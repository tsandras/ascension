extends Control

# Manager instances
var ability_manager: AllocationManager
var skills_manager: AllocationManager

# UI node references
@onready var points_label = $CenterContainer/VBoxContainer/ContentContainer/LeftPanel/PointsLabel
@onready var skills_points_label = $CenterContainer/VBoxContainer/ContentContainer/RightPanel/SkillsPointsLabel
@onready var abilities_container = $CenterContainer/VBoxContainer/ContentContainer/LeftPanel/AttributesContainer
@onready var skills_container = $CenterContainer/VBoxContainer/ContentContainer/RightPanel/SkillsContainer

# Store UI elements for each ability and skill
var ability_ui_elements = {}
var skills_ui_elements = {}

func _ready():
	# Apply UI constants to this scene
	UIManager.setup_character_creation_step2(self)
	
	# Wait a bit to ensure DatabaseManager is fully initialized
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Initialize the managers
	ability_manager = AllocationManager.new("abilities", "abilities", 3)
	skills_manager = AllocationManager.new("skills", "skills", 4)  # 4 points for skills
	
	# Generate the UI dynamically
	generate_ability_ui()
	generate_skills_ui()
	
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

func generate_skills_ui():
	# Clear existing children
	for child in skills_container.get_children():
		child.queue_free()
	
	# Wait for children to be freed
	await get_tree().process_frame
	
	# Get all skill names in order
	var skill_names = skills_manager.get_item_names()
	
	# Create UI for each skill
	for skill_name in skill_names:
		create_skill_row(skill_name)

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

func create_skill_row(skill_name: String):
	# Create horizontal container for this skill
	var h_container = HBoxContainer.new()
	h_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Create UI elements using UIManager
	var elements = UIManager.create_attribute_row_elements()
	
	# Configure the label
	elements.label.text = skill_name + ":"
	
	# Set initial value
	elements.value_label.text = str(skills_manager.get_item_value(skill_name))
	
	# Connect button signals
	elements.minus_button.pressed.connect(_on_skill_minus_pressed.bind(skill_name))
	elements.plus_button.pressed.connect(_on_skill_plus_pressed.bind(skill_name))
	
	# Add all elements to the container
	h_container.add_child(elements.label)
	h_container.add_child(elements.minus_button)
	h_container.add_child(elements.value_label)
	h_container.add_child(elements.plus_button)
	
	# Add to skills container
	skills_container.add_child(h_container)
	
	# Store references for easy access
	skills_ui_elements[skill_name] = {
		"container": h_container,
		"label": elements.label,
		"minus_button": elements.minus_button,
		"value_label": elements.value_label,
		"plus_button": elements.plus_button
	}
	
	# Set initial button states using UIManager
	UIManager.apply_button_state(elements.plus_button, skills_manager.can_increase_item(skill_name))
	UIManager.apply_button_state(elements.minus_button, skills_manager.can_decrease_item(skill_name))

func _on_ability_plus_pressed(ability_name: String):
	if ability_manager.increase_item(ability_name):
		update_ui()

func _on_ability_minus_pressed(ability_name: String):
	if ability_manager.decrease_item(ability_name):
		update_ui()

func _on_skill_plus_pressed(skill_name: String):
	if skills_manager.increase_item(skill_name):
		update_ui()

func _on_skill_minus_pressed(skill_name: String):
	if skills_manager.decrease_item(skill_name):
		update_ui()

func update_ui():
	# Update abilities points label with color feedback
	var remaining_points = ability_manager.get_remaining_points()
	points_label.text = "Ability Points Remaining: " + str(remaining_points)
	
	# Apply color feedback using UIManager
	UIManager.apply_color_feedback(points_label, remaining_points)
	
	# Update skills points label with color feedback
	var skills_remaining_points = skills_manager.get_remaining_points()
	skills_points_label.text = "Skill Points Remaining: " + str(skills_remaining_points)
	
	# Apply color feedback using UIManager
	UIManager.apply_color_feedback(skills_points_label, skills_remaining_points)
	
	# Update each ability's value and button states
	for ability_name in ability_ui_elements:
		var ui_elements = ability_ui_elements[ability_name]
		var current_value = ability_manager.get_item_value(ability_name)
		
		# Update value display
		ui_elements.value_label.text = str(current_value)
		
		# Update button states using UIManager
		UIManager.apply_button_state(ui_elements.plus_button, ability_manager.can_increase_item(ability_name))
		UIManager.apply_button_state(ui_elements.minus_button, ability_manager.can_decrease_item(ability_name))
	
	# Update each skill's value and button states
	for skill_name in skills_ui_elements:
		var ui_elements = skills_ui_elements[skill_name]
		var current_value = skills_manager.get_item_value(skill_name)
		
		# Update value display
		ui_elements.value_label.text = str(current_value)
		
		# Update button states using UIManager
		UIManager.apply_button_state(ui_elements.plus_button, skills_manager.can_increase_item(skill_name))
		UIManager.apply_button_state(ui_elements.minus_button, skills_manager.can_decrease_item(skill_name))
	
	# Update continue button state using UIManager
	var continue_button = get_node("CenterContainer/VBoxContainer/ButtonsContainer/ContinueButton")
	var can_continue = ability_manager.all_points_spent() and skills_manager.all_points_spent()
	UIManager.apply_button_state(continue_button, can_continue)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/character_creation/character_creation_step1.tscn")

func _on_continue_button_pressed():
	# Check if all points have been spent
	if not ability_manager.all_points_spent():
		print("Cannot continue: You must spend all %d ability points before proceeding!" % ability_manager.get_remaining_points())
		UIManager.flash_error_feedback(points_label)
		return
	
	if not skills_manager.all_points_spent():
		print("Cannot continue: You must spend all %d skill points before proceeding!" % skills_manager.get_remaining_points())
		UIManager.flash_error_feedback(skills_points_label)
		return
	
	# Print character stats
	ability_manager.print_character_stats()
	skills_manager.print_character_stats()
	
	# Character creation complete!
	print("Character creation complete!")
	print("Ready to enter the world of Ascension!")
	
	# Navigate to the hexagonal map
	print("Loading map...")
	get_tree().change_scene_to_file("res://scenes/game_world/hex_map.tscn") 