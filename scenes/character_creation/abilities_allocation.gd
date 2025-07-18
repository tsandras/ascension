extends Control

# Ability manager instance
var ability_manager: AllocationManager

# UI node references
@onready var points_label = $CenterContainer/VBoxContainer/PointsLabel
@onready var abilities_container = $CenterContainer/VBoxContainer/AttributesContainer

# Store UI elements for each ability
var ability_ui_elements = {}

func _ready():
	# Apply UI constants to this scene
	UIManager.setup_abilities_allocation(self)
	
	# Wait a bit to ensure DatabaseManager is fully initialized
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Initialize the ability manager
	ability_manager = AllocationManager.new("abilities", "abilities", 3)
	
	# Generate the UI dynamically
	generate_ability_ui()
	
	# Wait for UI elements to be added to scene tree
	await get_tree().process_frame
	
	# Update the UI
	update_ui()

func generate_ability_ui():
	# Clear existing children
	for child in abilities_container.get_children():
		child.queue_free()
	
	# Wait for children to be freed
	await get_tree().process_frame
	
	# Get all ability names in order
	var ability_names = ability_manager.get_item_names()
	
	# Create UI for each ability
	for ability_name in ability_names:
		create_ability_row(ability_name)

func create_ability_row(ability_name: String):
	# Create horizontal container for this ability
	var h_container = HBoxContainer.new()
	h_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Create UI elements using UIManager
	var elements = UIManager.create_attribute_row_elements()
	
	# Configure the label
	elements.label.text = ability_name + ":"
	
	# Set initial value
	elements.value_label.text = str(ability_manager.get_item_value(ability_name))
	
	# Connect button signals
	elements.minus_button.pressed.connect(_on_ability_minus_pressed.bind(ability_name))
	elements.plus_button.pressed.connect(_on_ability_plus_pressed.bind(ability_name))
	
	# Add all elements to the container
	h_container.add_child(elements.label)
	h_container.add_child(elements.minus_button)
	h_container.add_child(elements.value_label)
	h_container.add_child(elements.plus_button)
	
	# Add to abilities container
	abilities_container.add_child(h_container)
	
	# Store references for easy access
	ability_ui_elements[ability_name] = {
		"container": h_container,
		"label": elements.label,
		"minus_button": elements.minus_button,
		"value_label": elements.value_label,
		"plus_button": elements.plus_button
	}
	
	# Set initial button states using UIManager
	UIManager.apply_button_state(elements.plus_button, ability_manager.can_increase_item(ability_name))
	UIManager.apply_button_state(elements.minus_button, ability_manager.can_decrease_item(ability_name))

func _on_ability_plus_pressed(ability_name: String):
	if ability_manager.increase_item(ability_name):
		update_ui()

func _on_ability_minus_pressed(ability_name: String):
	if ability_manager.decrease_item(ability_name):
		update_ui()

func update_ui():
	# Update points label with color feedback
	var remaining_points = ability_manager.get_remaining_points()
	points_label.text = "Points Remaining: " + str(remaining_points)
	
	# Apply color feedback using UIManager
	UIManager.apply_color_feedback(points_label, remaining_points)
	
	# Update each ability's value and button states
	for ability_name in ability_ui_elements:
		var ui_elements = ability_ui_elements[ability_name]
		var current_value = ability_manager.get_item_value(ability_name)
		
		# Update value display
		ui_elements.value_label.text = str(current_value)
		
		# Update button states using UIManager
		UIManager.apply_button_state(ui_elements.plus_button, ability_manager.can_increase_item(ability_name))
		UIManager.apply_button_state(ui_elements.minus_button, ability_manager.can_decrease_item(ability_name))
	
	# Update continue button state using UIManager
	var continue_button = get_node("CenterContainer/VBoxContainer/ButtonsContainer/ContinueButton")
	UIManager.apply_button_state(continue_button, ability_manager.all_points_spent())

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/character_creation/attributes_allocation.tscn")

func _on_continue_button_pressed():
	# Check if all points have been spent
	if not ability_manager.all_points_spent():
		# Visual feedback - this shouldn't happen since button is disabled
		print("Cannot continue: You must spend all %d ability points before proceeding!" % ability_manager.get_remaining_points())
		
		# Flash error feedback using UIManager
		UIManager.flash_error_feedback(points_label)
		return
	
	# Print ability stats using the ability manager
	ability_manager.print_character_stats()
	
	# Character creation complete!
	print("Character creation complete!")
	print("Ready to enter the world of Ascension!")
	
	# Navigate to the hexagonal map
	print("Loading map...")
	get_tree().change_scene_to_file("res://scenes/game_world/hex_map.tscn") 