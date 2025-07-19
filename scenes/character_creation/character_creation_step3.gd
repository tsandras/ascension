extends Control

# UI references
@onready var skills_container = $CenterContainer/VBoxContainer/ContentContainer/VBoxContainer/SkillsContainer
@onready var selected_skills_label = $CenterContainer/VBoxContainer/ContentContainer/VBoxContainer/SelectedSkillsLabel
@onready var back_button = $CenterContainer/VBoxContainer/ButtonsContainer/BackButton
@onready var continue_button = $CenterContainer/VBoxContainer/ButtonsContainer/ContinueButton

# Store available skills and selected skills
var available_skills = []
var selected_skills = {}
var skill_buttons = {}

func _ready():
	# Apply UI constants to this scene
	UIManager.setup_character_creation_step3(self)
	
	# Wait for the scene to be fully ready
	await get_tree().process_frame
	
	# Load available skills from database
	load_available_skills()
	
	# Generate the UI
	generate_skills_ui()
	
	# Load existing skills data if returning
	load_existing_skills_data()
	
	# Update the UI
	update_ui()
	
	# Connect button signals
	back_button.pressed.connect(_on_back_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)

func load_available_skills():
	"""Load all available skills from database"""
	available_skills = DatabaseManager.get_all_skills()
	print("Loaded %d available skills" % available_skills.size())

func generate_skills_ui():
	"""Generate UI for all available skills"""
	# Clear existing children
	for child in skills_container.get_children():
		child.queue_free()
	
	# Wait for children to be freed
	await get_tree().process_frame
	
	# Create UI for each skill that the character can learn
	for skill in available_skills:
		if can_learn_skill(skill):
			create_skill_row(skill)
		else:
			print("Skipping skill %s - requirements not met" % skill.name)

func create_skill_row(skill_data: Dictionary):
	"""Create a UI row for a skill"""
	# Create main container
	var skill_container = VBoxContainer.new()
	skill_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Create header with skill name and level
	var header_container = HBoxContainer.new()
	var name_label = Label.new()
	name_label.text = skill_data.name + " (Level " + str(skill_data.level) + ")"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(name_label)
	
	# Create select button
	var select_button = Button.new()
	select_button.text = "Select"
	select_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	select_button.pressed.connect(_on_skill_select_pressed.bind(skill_data))
	header_container.add_child(select_button)
	
	skill_container.add_child(header_container)
	
	# Create description
	var desc_label = Label.new()
	desc_label.text = skill_data.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_container.add_child(desc_label)
	
	# Create requirements section
	var req_container = HBoxContainer.new()
	req_container.add_child(Label.new())
	var req_label = Label.new()
	req_label.text = "Requirements: " + format_ability_conditions(skill_data.ability_conditions)
	req_container.add_child(req_label)
	skill_container.add_child(req_container)
	
	# Create cost section
	var cost_container = HBoxContainer.new()
	cost_container.add_child(Label.new())
	var cost_label = Label.new()
	cost_label.text = "Cost: " + format_cost(skill_data.cost)
	cost_container.add_child(cost_label)
	skill_container.add_child(cost_container)
	
	# Create effect section
	var effect_container = HBoxContainer.new()
	effect_container.add_child(Label.new())
	var effect_label = Label.new()
	effect_label.text = "Effect: " + skill_data.effect
	effect_container.add_child(effect_label)
	skill_container.add_child(effect_container)
	
	# Add separator
	var separator = HSeparator.new()
	skill_container.add_child(separator)
	
	# Add to skills container
	skills_container.add_child(skill_container)
	
	# Store button reference - convert ID to string to ensure consistency
	var skill_id_str = str(skill_data.id)
	skill_buttons[skill_id_str] = select_button

func format_ability_conditions(conditions_json) -> String:
	"""Format ability conditions for display"""
	var conditions = conditions_json
	
	# If it's a string, parse it as JSON
	if conditions is String:
		var json = JSON.new()
		if json.parse(conditions) == OK:
			conditions = json.data
		else:
			return "Invalid JSON"
	
	if conditions is Dictionary:
		var formatted = []
		for ability in conditions:
			formatted.append(ability.capitalize() + " " + str(conditions[ability]))
		return ", ".join(formatted)
	return "None"

func format_cost(cost_json) -> String:
	"""Format cost for display"""
	var cost = cost_json
	
	# If it's a string, parse it as JSON
	if cost is String:
		var json = JSON.new()
		if json.parse(cost) == OK:
			cost = json.data
		else:
			return "Invalid JSON"
	
	if cost is Dictionary:
		var formatted = []
		for resource in cost:
			formatted.append(resource.capitalize() + " " + str(cost[resource]))
		return ", ".join(formatted)
	return "None"

func _on_skill_select_pressed(skill_data: Dictionary):
	"""Handle skill selection"""
	var skill_id = str(skill_data.id)  # Convert to string for consistency
	
	if selected_skills.has(skill_id):
		# Deselect skill
		selected_skills.erase(skill_id)
		skill_buttons[skill_id].text = "Select"
		print("Deselected skill: ", skill_data.name)
	else:
		# Select skill (all displayed skills are learnable)
		selected_skills[skill_id] = int(skill_data.id)  # Store as integer
		skill_buttons[skill_id].text = "Selected"
		print("Selected skill: ", skill_data.name)
	
	update_ui()

func can_learn_skill(skill_data: Dictionary) -> bool:
	"""Check if character can learn this skill based on ability requirements"""
	var requirements = skill_data.ability_conditions
	
	# If it's a string, parse it as JSON
	if requirements is String:
		var json = JSON.new()
		if json.parse(requirements) == OK:
			requirements = json.data
		else:
			print("Failed to parse requirements JSON: ", requirements)
			return false
	
	if not requirements is Dictionary:
		print("Requirements is not a Dictionary after parsing: ", typeof(requirements))
		return false

	for ability in requirements:
		var required_level = requirements[ability]
		# Find the ability in character abilities (case-insensitive)
		var character_level = 0
		for char_ability in CharacterCreation.abilities:
			if char_ability.to_lower() == ability.to_lower():
				character_level = CharacterCreation.abilities[char_ability]
				break
		
		if character_level < required_level:
			print("Cannot learn %s: need %s %d, have %d" % [skill_data.name, ability, required_level, character_level])
			return false
	
	return true

func load_existing_skills_data():
	"""Load existing skills data if user has previous selections"""
	if CharacterCreation.skills.size() == 0:
		print("No existing skills data to load")
		return
	
	print("Loading existing skills data...")
	selected_skills = CharacterCreation.skills.duplicate()
	
	# Update button states
	for skill_id in selected_skills:
		if skill_buttons.has(skill_id):
			skill_buttons[skill_id].text = "Selected"
	
	print("Skills data loading complete")

func update_ui():
	"""Update the UI display"""
	# Update selected skills label
	var selected_count = selected_skills.size()
	selected_skills_label.text = "Selected Skills: %d" % selected_count
	
	# Update continue button state
	continue_button.disabled = selected_count == 0
	for skill in available_skills:
		var skill_id = str(skill.id)  # Convert to string for consistency
		if not skill_buttons.has(skill_id):
			continue  # Skip skills that weren't created (requirements not met)
		var button = skill_buttons[skill_id]
		
		# All displayed skills should be learnable, so just enable them
		button.disabled = false
		button.modulate = Color.WHITE

func _on_back_button_pressed():
	# Save current progress before going back to step 2
	CharacterCreation.set_step3_data(selected_skills)
	print("Saved current step 3 progress before going back")
	
	get_tree().change_scene_to_file("res://scenes/character_creation/character_creation_step2.tscn")

func _on_continue_button_pressed():
	# Store step 3 data and save character
	CharacterCreation.set_step3_data(selected_skills)
	
	# Save the complete character to database
	var character_id = CharacterCreation.save_character()
	
	if character_id > 0:
		# Character creation complete!
		print("Character creation complete!")
		print("Character saved with ID: %d" % character_id)
		print("Ready to enter the world of Ascension!")
		
		# Load the newly created character
		var saved_character = DatabaseManager.get_character_by_id(character_id)
		if saved_character:
			print("Loading newly created character: ", saved_character.name)
			CharacterCreation.load_saved_character(saved_character)
		else:
			print("Warning: Could not load saved character data")
		
		# Navigate to the hexagonal map
		print("Loading map...")
		get_tree().change_scene_to_file("res://scenes/game_world/hex_map.tscn")
	else:
		print("Error: Failed to save character. Please try again.") 
