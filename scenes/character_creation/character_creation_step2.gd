extends Control

# Manager instances
var ability_manager: AllocationManager

# UI node references
@onready var points_label = $CenterContainer/VBoxContainer/ContentContainer/LeftPanel/PointsLabel
@onready var abilities_points_label = $CenterContainer/VBoxContainer/ContentContainer/RightPanel/SkillsPointsLabel
@onready var abilities_container = $CenterContainer/VBoxContainer/ContentContainer/LeftPanel/AttributesContainer

# Store UI elements for each ability
var ability_ui_elements = {}

func _ready():
	# Apply UI constants to this scene
	UIManager.setup_character_creation_step2(self)
	
	# Wait a bit to ensure DatabaseManager is fully initialized
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Initialize the managers
	ability_manager = AllocationManager.new("abilities", "abilities", 4)  # 4 points for abilities
	
	# Apply trait bonuses if we have trait data from step 1
	if CharacterCreation.current_trait_data.size() > 0:
		# Reset abilities first to clear any previous race bonuses
		ability_manager.reset_items()
		apply_trait_bonuses()
	
	# Generate the UI dynamically
	generate_ability_ui()
	
	# Add cursor functionality to buttons
	add_cursor_to_buttons()
	
	# Wait for UI elements to be added to scene tree
	await get_tree().process_frame
	
	# Load existing character data if returning with previous allocations
	load_existing_character_data()
	
	# Update the UI
	update_ui()

func add_cursor_to_buttons():
	"""Add cursor functionality to all buttons"""
	# Add cursor to navigation buttons
	var back_button = get_node_or_null("CenterContainer/VBoxContainer/ButtonsContainer/BackButton")
	var continue_button = get_node_or_null("CenterContainer/VBoxContainer/ButtonsContainer/ContinueButton")
	
	if back_button:
		CursorUtils.add_cursor_to_button(back_button)
	if continue_button:
		CursorUtils.add_cursor_to_button(continue_button)

func apply_trait_bonuses():
	"""Apply trait bonuses to abilities"""
	print("Applying trait bonuses...")
	
	var trait_data = CharacterCreation.current_trait_data
	var current_abilities = ability_manager.get_all_item_values()
	
	var modified_data = TraitManager.apply_trait_bonuses(trait_data, {}, current_abilities, {})
	
	# Extract ability bonuses for race bonus tracking
	var ability_bonuses = {}
	if trait_data.has("competence_bonuses"):  # Note: still using competence_bonuses from trait data
		for bonus in trait_data.competence_bonuses:
			if bonus.name != "free":  # Skip free points, only track specific bonuses
				var abil_name = bonus.name.to_lower()
				# Find the ability (case-insensitive)
				for abil in current_abilities:
					if abil.to_lower() == abil_name:
						ability_bonuses[abil] = bonus.value
						break
	
	# Set ability race bonuses in the allocation manager
	ability_manager.set_race_bonuses(ability_bonuses)
	
	# Apply ability bonuses
	for ability_name in modified_data.abilities:
		var base_value = ability_manager.get_item_base_value(ability_name)
		var target_value = modified_data.abilities[ability_name]
		var current_value = ability_manager.get_item_value(ability_name)
		
		# Adjust points to reach target value
		var points_needed = target_value - current_value
		if points_needed > 0:
			# Add points
			for i in range(points_needed):
				ability_manager.increase_item(ability_name)
		elif points_needed < 0:
			# Remove points (but don't go below base value)
			for i in range(-points_needed):
				if ability_manager.get_item_value(ability_name) > base_value:
					ability_manager.decrease_item(ability_name)
	
	# Add free ability points if any
	if modified_data.free_points.competences > 0:
		ability_manager.add_free_points(modified_data.free_points.competences)
		print("Added %d free ability points from trait" % modified_data.free_points.competences)
	
	# Update the remaining points calculation
	ability_manager.update_remaining_points()
	
	print("Trait bonuses applied successfully")

func load_existing_character_data():
	"""Load existing abilities and competences data if user has previous allocations"""
	if CharacterCreation.abilities.size() == 0 and CharacterCreation.competences.size() == 0:
		print("No existing abilities/competences data to load")
		return
	
	print("Loading existing abilities and competences data...")
	
	# Load ability allocations
	if CharacterCreation.abilities.size() > 0:
		print("Loading ability allocations...")
		for ability_name in CharacterCreation.abilities:
			var value = CharacterCreation.abilities[ability_name]
			var base_value = ability_manager.get_item_base_value(ability_name)
			var points_to_add = value - base_value
			
			# Add points one by one to respect the allocation system
			for i in range(points_to_add):
				if not ability_manager.increase_item(ability_name):
					print("Warning: Could not fully restore ability " + ability_name)
					break
			
			print("Loaded %s: %d (added %d points)" % [ability_name, value, points_to_add])
	
	print("Abilities data loading complete")

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
	# Update abilities points label with color feedback
	var remaining_points = ability_manager.get_remaining_points()
	points_label.text = "Ability Points Remaining: " + str(remaining_points)
	
	# Apply color feedback using UIManager
	UIManager.apply_color_feedback(points_label, remaining_points)
	
	# Update abilities points label with color feedback and trait bonus info
	var abilities_remaining_points = ability_manager.get_remaining_points()
	var trait_info = ""
	if CharacterCreation.current_trait_data.size() > 0:
		var trait_data = CharacterCreation.current_trait_data
		if trait_data.has("competence_bonuses"):
			for bonus in trait_data.competence_bonuses:
				if bonus.name == "free":
					trait_info = " (+%d from trait)" % bonus.value
					break
	
	abilities_points_label.text = "Ability Points Remaining: " + str(abilities_remaining_points) + trait_info
	
	# Apply color feedback using UIManager
	UIManager.apply_color_feedback(abilities_points_label, abilities_remaining_points)
	
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
	var can_continue = ability_manager.all_points_spent()
	UIManager.apply_button_state(continue_button, can_continue)

func _on_back_button_pressed():
	# Save current progress before going back to step 1
	CharacterCreation.set_step2_data(
		ability_manager.get_character_items()
	)
	print("Saved current step 2 progress before going back")
	
	get_tree().change_scene_to_file("res://scenes/character_creation/character_creation_step1.tscn")

func _on_continue_button_pressed():
	# Check if all points have been spent
	if not ability_manager.all_points_spent():
		print("Cannot continue: You must spend all %d ability points before proceeding!" % ability_manager.get_remaining_points())
		UIManager.flash_error_feedback(points_label)
		return
	

	
	# Store step 2 data
	CharacterCreation.set_step2_data(
		ability_manager.get_character_items()
	)
	
	# Print character stats
	ability_manager.print_character_stats()
	competences_manager.print_character_stats()
	
	# Create a Character instance from the creation data
	var character = Character.load_from_creation()
	if character == null:
		print("Error: Could not create character from creation data")
		return
	
	# Save the character to database
	var character_id = character.save_to_db()
	
	if character_id > 0:
		# Character creation complete!
		print("Character creation complete!")
		print("Character saved with ID: %d" % character_id)
		print("Ready to enter the world of Ascension!")
		
		# Navigate to the hexagonal map - hex_map will load the character directly
		print("Loading map...")
		get_tree().change_scene_to_file("res://scenes/game_world/hex_map.tscn")
	else:
		print("Error: Failed to save character. Please try again.")