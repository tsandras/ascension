extends Control

# Manager instances
var ability_manager: AllocationManager
var competences_manager: AllocationManager

# UI node references
@onready var points_label = $CenterContainer/VBoxContainer/ContentContainer/LeftPanel/PointsLabel
@onready var competences_points_label = $CenterContainer/VBoxContainer/ContentContainer/RightPanel/SkillsPointsLabel
@onready var abilities_container = $CenterContainer/VBoxContainer/ContentContainer/LeftPanel/AttributesContainer
@onready var competences_container = $CenterContainer/VBoxContainer/ContentContainer/RightPanel/SkillsContainer

# Store UI elements for each ability and competence
var ability_ui_elements = {}
var competences_ui_elements = {}

func _ready():
	# Apply UI constants to this scene
	UIManager.setup_character_creation_step2(self)
	
	# Wait a bit to ensure DatabaseManager is fully initialized
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Initialize the managers
	ability_manager = AllocationManager.new("abilities", "abilities", 3)
	competences_manager = AllocationManager.new("competences", "competences", 4)  # 4 points for competences
	
	# Apply trait bonuses if we have trait data from step 1
	if CharacterCreation.current_trait_data.size() > 0:
		# Reset abilities and competences first to clear any previous race bonuses
		ability_manager.reset_items()
		competences_manager.reset_items()
		apply_trait_bonuses()
	
	# Generate the UI dynamically
	generate_ability_ui()
	generate_competences_ui()
	
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
	"""Apply trait bonuses to abilities and competences"""
	print("Applying trait bonuses...")
	
	var trait_data = CharacterCreation.current_trait_data
	var current_abilities = ability_manager.get_all_item_values()
	var current_competences = competences_manager.get_all_item_values()
	
	var modified_data = TraitManager.apply_trait_bonuses(trait_data, {}, current_abilities, current_competences)
	
	# Extract competence bonuses for race bonus tracking
	var competence_bonuses = {}
	if trait_data.has("competence_bonuses"):
		for bonus in trait_data.competence_bonuses:
			if bonus.name != "free":  # Skip free points, only track specific bonuses
				var comp_name = bonus.name.to_lower()
				# Find the competence (case-insensitive)
				for comp in current_competences:
					if comp.to_lower() == comp_name:
						competence_bonuses[comp] = bonus.value
						break
	
	# Set competence race bonuses in the allocation manager
	competences_manager.set_race_bonuses(competence_bonuses)
	
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
	
	# Apply competence bonuses
	for competence_name in modified_data.competences:
		var base_value = competences_manager.get_item_base_value(competence_name)
		var target_value = modified_data.competences[competence_name]
		var current_value = competences_manager.get_item_value(competence_name)
		
		# Set the value directly (race bonuses don't consume allocation points)
		competences_manager.character_items[competence_name] = target_value
	
	# Add free competence points if any
	if modified_data.free_points.competences > 0:
		competences_manager.add_free_points(modified_data.free_points.competences)
		print("Added %d free competence points from trait" % modified_data.free_points.competences)
	
	# Update the remaining points calculation
	competences_manager.update_remaining_points()
	
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
	
	# Load competence allocations
	if CharacterCreation.competences.size() > 0:
		print("Loading competence allocations...")
		for competence_name in CharacterCreation.competences:
			var value = CharacterCreation.competences[competence_name]
			var base_value = competences_manager.get_item_base_value(competence_name)
			var points_to_add = value - base_value
			
			# Add points one by one to respect the allocation system
			for i in range(points_to_add):
				if not competences_manager.increase_item(competence_name):
					print("Warning: Could not fully restore competence " + competence_name)
					break
			
			print("Loaded %s: %d (added %d points)" % [competence_name, value, points_to_add])
	
	print("Abilities and competences data loading complete")

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

func generate_competences_ui():
	# Clear existing children
	for child in competences_container.get_children():
		child.queue_free()
	
	# Wait for children to be freed
	await get_tree().process_frame
	
	# Get all competence names in order
	var competence_names = competences_manager.get_item_names()
	
	# Create UI for each competence
	for competence_name in competence_names:
		create_competence_row(competence_name)

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

func create_competence_row(competence_name: String):
	# Create horizontal container for this competence
	var h_container = HBoxContainer.new()
	h_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Create UI elements using UIManager
	var elements = UIManager.create_attribute_row_elements()
	
	# Configure the label
	elements.label.text = competence_name + ":"
	
	# Set initial value
	elements.value_label.text = str(competences_manager.get_item_value(competence_name))
	
	# Connect button signals
	elements.minus_button.pressed.connect(_on_competence_minus_pressed.bind(competence_name))
	elements.plus_button.pressed.connect(_on_competence_plus_pressed.bind(competence_name))
	
	# Add all elements to the container
	h_container.add_child(elements.label)
	h_container.add_child(elements.minus_button)
	h_container.add_child(elements.value_label)
	h_container.add_child(elements.plus_button)
	
	# Add to competences container
	competences_container.add_child(h_container)
	
	# Store references for easy access
	competences_ui_elements[competence_name] = {
		"container": h_container,
		"label": elements.label,
		"minus_button": elements.minus_button,
		"value_label": elements.value_label,
		"plus_button": elements.plus_button
	}
	
	# Set initial button states using UIManager
	UIManager.apply_button_state(elements.plus_button, competences_manager.can_increase_item(competence_name))
	UIManager.apply_button_state(elements.minus_button, competences_manager.can_decrease_item(competence_name))

func _on_ability_plus_pressed(ability_name: String):
	if ability_manager.increase_item(ability_name):
		update_ui()

func _on_ability_minus_pressed(ability_name: String):
	if ability_manager.decrease_item(ability_name):
		update_ui()

func _on_competence_plus_pressed(competence_name: String):
	if competences_manager.increase_item(competence_name):
		update_ui()

func _on_competence_minus_pressed(competence_name: String):
	if competences_manager.decrease_item(competence_name):
		update_ui()

func update_ui():
	# Update abilities points label with color feedback
	var remaining_points = ability_manager.get_remaining_points()
	points_label.text = "Ability Points Remaining: " + str(remaining_points)
	
	# Apply color feedback using UIManager
	UIManager.apply_color_feedback(points_label, remaining_points)
	
	# Update competences points label with color feedback and trait bonus info
	var competences_remaining_points = competences_manager.get_remaining_points()
	var trait_info = ""
	if CharacterCreation.current_trait_data.size() > 0:
		var trait_data = CharacterCreation.current_trait_data
		if trait_data.has("competence_bonuses"):
			for bonus in trait_data.competence_bonuses:
				if bonus.name == "free":
					trait_info = " (+%d from trait)" % bonus.value
					break
	
	competences_points_label.text = "Competence Points Remaining: " + str(competences_remaining_points) + trait_info
	
	# Apply color feedback using UIManager
	UIManager.apply_color_feedback(competences_points_label, competences_remaining_points)
	
	# Update each ability's value and button states
	for ability_name in ability_ui_elements:
		var ui_elements = ability_ui_elements[ability_name]
		var current_value = ability_manager.get_item_value(ability_name)
		
		# Update value display
		ui_elements.value_label.text = str(current_value)
		
		# Update button states using UIManager
		UIManager.apply_button_state(ui_elements.plus_button, ability_manager.can_increase_item(ability_name))
		UIManager.apply_button_state(ui_elements.minus_button, ability_manager.can_decrease_item(ability_name))
	
	# Update each competence's value and button states
	for competence_name in competences_ui_elements:
		var ui_elements = competences_ui_elements[competence_name]
		var current_value = competences_manager.get_item_value(competence_name)
		
		# Update value display
		ui_elements.value_label.text = str(current_value)
		
		# Update button states using UIManager
		UIManager.apply_button_state(ui_elements.plus_button, competences_manager.can_increase_item(competence_name))
		UIManager.apply_button_state(ui_elements.minus_button, competences_manager.can_decrease_item(competence_name))
		
		# Add visual feedback for race-bonused competences
		if competences_manager.race_bonuses.has(competence_name):
			var race_bonus = competences_manager.race_bonuses[competence_name]
			var base_value = competences_manager.get_item_base_value(competence_name)
			var minimum_value = base_value + race_bonus
			
			# If current value equals minimum (race bonus level), disable minus button
			if current_value <= minimum_value:
				ui_elements.minus_button.disabled = true
				ui_elements.minus_button.modulate = Color.GRAY
				# Add visual indicator to value label
				ui_elements.value_label.text = str(current_value) + " (race bonus)"
	
	# Update continue button state using UIManager
	var continue_button = get_node("CenterContainer/VBoxContainer/ButtonsContainer/ContinueButton")
	var can_continue = ability_manager.all_points_spent() and competences_manager.all_points_spent()
	UIManager.apply_button_state(continue_button, can_continue)

func _on_back_button_pressed():
	# Save current progress before going back to step 1
	CharacterCreation.set_step2_data(
		ability_manager.get_character_items(),
		competences_manager.get_character_items()
	)
	print("Saved current step 2 progress before going back")
	
	get_tree().change_scene_to_file("res://scenes/character_creation/character_creation_step1.tscn")

func _on_continue_button_pressed():
	# Check if all points have been spent
	if not ability_manager.all_points_spent():
		print("Cannot continue: You must spend all %d ability points before proceeding!" % ability_manager.get_remaining_points())
		UIManager.flash_error_feedback(points_label)
		return
	
	if not competences_manager.all_points_spent():
		print("Cannot continue: You must spend all %d competence points before proceeding!" % competences_manager.get_remaining_points())
		UIManager.flash_error_feedback(competences_points_label)
		return
	
	# Store step 2 data
	CharacterCreation.set_step2_data(
		ability_manager.get_character_items(),
		competences_manager.get_character_items()
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