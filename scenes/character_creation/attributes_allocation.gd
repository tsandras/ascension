extends Control

# Attribute manager instance
var attribute_manager: AllocationManager

# UI node references
@onready var points_label = $CenterContainer/VBoxContainer/PointsLabel
@onready var attributes_container = $CenterContainer/VBoxContainer/AttributesContainer

# Store UI elements for each attribute
var attribute_ui_elements = {}

func _ready():
	# Apply UI constants to this scene
	UIManager.setup_attributes_allocation(self)
	
	# Wait a bit to ensure DatabaseManager is fully initialized
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Initialize the attribute manager
	attribute_manager = AllocationManager.new("attributes", "attributes", 8)
	
	# Generate the UI dynamically
	generate_attribute_ui()
	
	# Wait for UI elements to be added to scene tree
	await get_tree().process_frame
	
	# Update the UI
	update_ui()

func generate_attribute_ui():
	# Clear existing children
	for child in attributes_container.get_children():
		child.queue_free()
	
	# Wait for children to be freed
	await get_tree().process_frame
	
	# Get all attribute names in order
	var attribute_names = attribute_manager.get_item_names()
	
	# Create UI for each attribute
	for attribute_name in attribute_names:
		create_attribute_row(attribute_name)

func create_attribute_row(attribute_name: String):
	# Create horizontal container for this attribute
	var h_container = HBoxContainer.new()
	h_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Create UI elements using UIManager
	var elements = UIManager.create_attribute_row_elements()
	
	# Configure the label
	elements.label.text = attribute_name + ":"
	
	# Set initial value
	elements.value_label.text = str(attribute_manager.get_item_value(attribute_name))
	
	# Connect button signals
	elements.minus_button.pressed.connect(_on_attribute_minus_pressed.bind(attribute_name))
	elements.plus_button.pressed.connect(_on_attribute_plus_pressed.bind(attribute_name))
	
	# Add all elements to the container
	h_container.add_child(elements.label)
	h_container.add_child(elements.minus_button)
	h_container.add_child(elements.value_label)
	h_container.add_child(elements.plus_button)
	
	# Add to attributes container
	attributes_container.add_child(h_container)
	
	# Store references for easy access
	attribute_ui_elements[attribute_name] = {
		"container": h_container,
		"label": elements.label,
		"minus_button": elements.minus_button,
		"value_label": elements.value_label,
		"plus_button": elements.plus_button
	}
	
	# Set initial button states using UIManager
	UIManager.apply_button_state(elements.plus_button, attribute_manager.can_increase_item(attribute_name))
	UIManager.apply_button_state(elements.minus_button, attribute_manager.can_decrease_item(attribute_name))

func _on_attribute_plus_pressed(attribute_name: String):
	if attribute_manager.increase_item(attribute_name):
		update_ui()

func _on_attribute_minus_pressed(attribute_name: String):
	if attribute_manager.decrease_item(attribute_name):
		update_ui()

func update_ui():
	# Update points label with color feedback
	var remaining_points = attribute_manager.get_remaining_points()
	points_label.text = "Points Remaining: " + str(remaining_points)
	
	# Apply color feedback using UIManager
	UIManager.apply_color_feedback(points_label, remaining_points)
	
	# Update each attribute's value and button states
	for attribute_name in attribute_ui_elements:
		var ui_elements = attribute_ui_elements[attribute_name]
		var current_value = attribute_manager.get_item_value(attribute_name)
		
		# Update value display
		ui_elements.value_label.text = str(current_value)
		
		# Update button states using UIManager
		UIManager.apply_button_state(ui_elements.plus_button, attribute_manager.can_increase_item(attribute_name))
		UIManager.apply_button_state(ui_elements.minus_button, attribute_manager.can_decrease_item(attribute_name))
	
	# Update continue button state using UIManager
	var continue_button = get_node("CenterContainer/VBoxContainer/ButtonsContainer/ContinueButton")
	UIManager.apply_button_state(continue_button, attribute_manager.all_points_spent())

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_continue_button_pressed():
	# Check if all points have been spent
	if not attribute_manager.all_points_spent():
		# Visual feedback - this shouldn't happen since button is disabled
		print("Cannot continue: You must spend all %d attribute points before proceeding!" % attribute_manager.get_remaining_points())
		
		# Flash error feedback using UIManager
		UIManager.flash_error_feedback(points_label)
		return
	
	# Print character stats using the attribute manager
	attribute_manager.print_character_stats()
	
	# Navigate to abilities allocation
	get_tree().change_scene_to_file("res://scenes/character_creation/abilities_allocation.tscn") 