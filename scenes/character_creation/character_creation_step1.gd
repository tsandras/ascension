extends Control

# Manager instances
var attribute_manager: AllocationManager
var race_manager: AllocationManager

# UI node references
@onready var points_label = $CenterContainer/VBoxContainer/PointsLabel
@onready var character_name_input = $CenterContainer/VBoxContainer/CharacterNameInput
@onready var male_button = $CenterContainer/VBoxContainer/ContentContainer/Column2/SexContainer/MaleButton
@onready var female_button = $CenterContainer/VBoxContainer/ContentContainer/Column2/SexContainer/FemaleButton
@onready var avatar_sprite = $CenterContainer/VBoxContainer/ContentContainer/Column2/AvatarContainer/AvatarSprite
@onready var attributes_container = $CenterContainer/VBoxContainer/ContentContainer/Column3/AttributesContainer
@onready var race_container = $CenterContainer/VBoxContainer/ContentContainer/Column1/RaceContainer
@onready var trait_name_label = $CenterContainer/VBoxContainer/ContentContainer/Column1/TraitPanel/TraitContent/TraitMargin/TraitInfo/TraitNameLabel
@onready var trait_desc_label = $CenterContainer/VBoxContainer/ContentContainer/Column1/TraitPanel/TraitContent/TraitMargin/TraitInfo/TraitDescLabel
@onready var trait_bonuses_label = $CenterContainer/VBoxContainer/ContentContainer/Column1/TraitPanel/TraitContent/TraitMargin/TraitInfo/TraitBonusesLabel

# Store UI elements for each attribute and race
var attribute_ui_elements = {}
var race_ui_elements = {}
# Store race data with trait information
var race_data = {}
# Store selected sex
var selected_sex = ""
# Store avatar textures
var avatar_textures = {}

func _ready():
	# Apply UI constants to this scene
	UIManager.setup_character_creation_step1(self)
	
	# Wait a bit to ensure DatabaseManager is fully initialized
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Initialize the managers
	attribute_manager = AllocationManager.new("attributes", "attributes", 5)
	race_manager = AllocationManager.new("races", "races", 0)  # Races don't use points
	
	# Generate the UI dynamically
	generate_attribute_ui()
	generate_race_ui()
	
	# Connect character name input signal
	character_name_input.text_changed.connect(_on_character_name_changed)
	
	# Connect sex selection buttons
	male_button.pressed.connect(_on_male_button_pressed)
	female_button.pressed.connect(_on_female_button_pressed)
	
	# Load avatar textures
	load_avatar_textures()
	

	
	# Wait for UI elements to be added to scene tree
	await get_tree().process_frame
	
	# Load existing character data if returning from step 2
	load_existing_character_data()
	
	# Update the UI
	update_ui()

func load_existing_character_data():
	"""Load existing character data if user is returning from step 2"""
	if not CharacterCreation.has_complete_data():
		print("No existing character data to load")
		return
	
	print("Loading existing character data...")
	
	# Load character name
	if CharacterCreation.character_name != "":
		character_name_input.text = CharacterCreation.character_name
		print("Loaded character name: " + CharacterCreation.character_name)
	
	# Load selected race
	if CharacterCreation.selected_race != "":
		race_manager.select_race(CharacterCreation.selected_race)
		update_trait_display(CharacterCreation.selected_race)
		print("Loaded selected race: " + CharacterCreation.selected_race)
	
	# Load selected sex
	if CharacterCreation.selected_sex != "":
		selected_sex = CharacterCreation.selected_sex
		update_sex_buttons()
		update_avatar_display()
		print("Loaded selected sex: " + CharacterCreation.selected_sex)
	
	# Load attribute allocations
	if CharacterCreation.attributes.size() > 0:
		print("Loading attribute allocations...")
		for attribute_name in CharacterCreation.attributes:
			var value = CharacterCreation.attributes[attribute_name]
			var base_value = attribute_manager.get_item_base_value(attribute_name)
			var points_to_add = value - base_value
			
			# Add points one by one to respect the allocation system
			for i in range(points_to_add):
				if not attribute_manager.increase_item(attribute_name):
					print("Warning: Could not fully restore attribute " + attribute_name)
					break
			
			print("Loaded %s: %d (added %d points)" % [attribute_name, value, points_to_add])
	
	print("Character data loading complete")

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

func generate_race_ui():
	# Clear existing children
	for child in race_container.get_children():
		child.queue_free()
	
	# Wait for children to be freed
	await get_tree().process_frame
	
	# Get all race data (including trait information)
	var races = DatabaseManager.get_all_races()
	
	# Store race data for trait display
	for race in races:
		race_data[race.name] = race
	
	# Get all race names in order
	var race_names = race_manager.get_item_names()
	
	# Create UI for each race
	for race_name in race_names:
		create_race_row(race_name)

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

func create_race_row(race_name: String):
	# Create horizontal container for this race
	var h_container = HBoxContainer.new()
	h_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Create selection button for race
	var race_button = Button.new()
	race_button.text = race_name
	race_button.custom_minimum_size = Vector2(200, 40)
	race_button.pressed.connect(_on_race_selected.bind(race_name))
	
	# Add to container
	h_container.add_child(race_button)
	
	# Add to race container
	race_container.add_child(h_container)
	
	# Store references for easy access
	race_ui_elements[race_name] = {
		"container": h_container,
		"button": race_button
	}
	
	# Set initial button state
	update_race_button_state(race_name)

func update_race_button_state(race_name: String):
	var race_button = race_ui_elements[race_name].button
	var is_selected = race_manager.is_race_selected(race_name)
	
	if is_selected:
		race_button.text = "✓ " + race_name
		race_button.disabled = false
	else:
		race_button.text = race_name
		race_button.disabled = false

func _on_attribute_plus_pressed(attribute_name: String):
	if attribute_manager.increase_item(attribute_name):
		update_ui()

func _on_attribute_minus_pressed(attribute_name: String):
	if attribute_manager.decrease_item(attribute_name):
		update_ui()

func _on_race_selected(race_name: String):
	if race_manager.select_race(race_name):
		update_trait_display(race_name)
		update_avatar_display()  # Update avatar when race changes
		update_ui()

func _on_character_name_changed(_new_text: String):
	# Update the continue button state when the character name changes
	update_ui()

func get_character_name() -> String:
	return character_name_input.text.strip_edges()

func load_avatar_textures():
	"""Load all available avatar textures"""
	print("Loading avatar textures...")
	
	# Define the races and sexes available
	var races = DatabaseManager.get_all_races()
	var sexes = ["male", "female"]
	
	for sex in sexes:
		avatar_textures[sex] = {}
		
		for race in races:
			var avatar_path = "res://assets/avatars/%s_%s_1.png" % [sex, race.name.to_lower()]
			var texture = load(avatar_path)
			if texture:
				# Store using the lowercase race name as the key (string, not object)
				avatar_textures[sex][race.name.to_lower()] = texture
				print("Loaded avatar: ", sex, "_", race.name.to_lower())
			else:
				print("Warning: Failed to load avatar: ", avatar_path)
	
	print("Avatar loading complete")

func _on_male_button_pressed():
	"""Handle male button selection"""
	selected_sex = "male"
	update_sex_buttons()
	update_avatar_display()
	update_ui()

func _on_female_button_pressed():
	"""Handle female button selection"""
	selected_sex = "female"
	update_sex_buttons()
	update_avatar_display()
	update_ui()

func update_sex_buttons():
	"""Update sex button visual states"""
	if selected_sex == "male":
		male_button.modulate = Color(1.2, 1.2, 0.8)  # Highlight selected
		female_button.modulate = Color.WHITE
	elif selected_sex == "female":
		female_button.modulate = Color(1.2, 1.2, 0.8)  # Highlight selected
		male_button.modulate = Color.WHITE
	else:
		male_button.modulate = Color.WHITE
		female_button.modulate = Color.WHITE

func update_avatar_display():
	"""Update the avatar display based on selected sex and race"""
	var selected_race = race_manager.get_selected_race()
	var race_lowercase = selected_race.to_lower()  # Convert to lowercase for avatar lookup
	
	if selected_sex != "" and selected_race != "":
		if avatar_textures.has(selected_sex) and avatar_textures[selected_sex].has(race_lowercase):
			avatar_sprite.texture = avatar_textures[selected_sex][race_lowercase]
			print("Avatar updated: ", selected_sex, "_", race_lowercase)
		else:
			avatar_sprite.texture = null
			print("Avatar not found for: ", selected_sex, "_", race_lowercase)
	else:
		avatar_sprite.texture = null

func get_selected_sex() -> String:
	return selected_sex

func update_trait_display(race_name: String):
	if race_data.has(race_name):
		var race = race_data[race_name]
		
		# Display trait name
		trait_name_label.text = race.trait_name if race.trait_name else "No Trait"
		
		# Display trait description
		trait_desc_label.text = race.trait_description if race.trait_description else ""
		
		# Build and display trait bonuses
		var bonuses = []
		
		# Parse JSON attribute_bonuses
		if race.attribute_bonuses and race.attribute_bonuses != "":
			var attribute_bonuses_text = format_json_bonuses(race.attribute_bonuses, "Attributes")
			if attribute_bonuses_text != "":
				bonuses.append(attribute_bonuses_text)
		
		# Parse JSON ability_bonuses
		if race.ability_bonuses and race.ability_bonuses != "":
			var ability_bonuses_text = format_json_bonuses(race.ability_bonuses, "Abilities")
			if ability_bonuses_text != "":
				bonuses.append(ability_bonuses_text)
		
		# Parse JSON skill_bonuses
		if race.skill_bonuses and race.skill_bonuses != "":
			var skill_bonuses_text = format_json_bonuses(race.skill_bonuses, "Skills")
			if skill_bonuses_text != "":
				bonuses.append(skill_bonuses_text)
		
		# Parse and format JSON other_bonuses
		if race.other_bonuses and race.other_bonuses != "":
			var other_bonuses_text = format_other_bonuses(race.other_bonuses)
			if other_bonuses_text != "":
				bonuses.append(other_bonuses_text)
		
		trait_bonuses_label.text = "\n".join(bonuses) if bonuses.size() > 0 else ""
	else:
		# Reset trait display if no race data found
		trait_name_label.text = "Select a race to see its trait"
		trait_desc_label.text = ""
		trait_bonuses_label.text = ""

func format_other_bonuses(json_string: String) -> String:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing other_bonuses JSON: " + json_string)
		return ""
	
	var bonuses_array = json.data
	if not bonuses_array is Array:
		print("other_bonuses is not an array: " + json_string)
		return ""
	
	var formatted_bonuses = []
	
	for bonus in bonuses_array:
		if not bonus is Dictionary:
			continue
		
		var bonus_type = bonus.get("type", "")
		var bonus_value = bonus.get("value", 0)
		var bonus_subtype = bonus.get("subtype", "")
		
		var formatted_bonus = format_single_bonus(bonus_type, bonus_value, bonus_subtype)
		if formatted_bonus != "":
			formatted_bonuses.append(formatted_bonus)
	
	return ", ".join(formatted_bonuses)

func format_json_bonuses(json_string: String, category_name: String) -> String:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing " + category_name.to_lower() + "_bonuses JSON: " + json_string)
		return ""
	
	var bonuses_array = json.data
	if not bonuses_array is Array:
		print(category_name.to_lower() + "_bonuses is not an array: " + json_string)
		return ""
	
	if bonuses_array.size() == 0:
		return ""
	
	var formatted_bonuses = []
	
	for bonus in bonuses_array:
		if not bonus is Dictionary:
			continue
		
		var bonus_name = bonus.get("name", "")
		var bonus_value = bonus.get("value", 0)
		
		if bonus_name != "" and bonus_value != 0:
			var formatted_bonus = str(int(bonus_value))
			formatted_bonus += " " + bonus_name.replace("_", " ").capitalize()
			formatted_bonuses.append(formatted_bonus)
	
	if formatted_bonuses.size() > 0:
		return category_name + ": " + ", ".join(formatted_bonuses)
	else:
		return ""

func format_single_bonus(bonus_type: String, value: int, subtype: String = "") -> String:
	var formatted_type = get_bonus_display_name(bonus_type)
	var is_percentage = is_percentage_bonus(bonus_type)
	
	var result = "+"
	result += str(value)
	if is_percentage:
		result += "%"
	result += " " + formatted_type
	
	if subtype != "":
		result += " (" + subtype.capitalize() + ")"
	
	return result

func get_bonus_display_name(bonus_type: String) -> String:
	match bonus_type:
		"damage":
			return "Damage"
		"critical_chance":
			return "Critical Chance"
		"critical_multiplier":
			return "Critical Multiplier"
		"accuracy":
			return "Accuracy"
		"dodge":
			return "Dodge"
		"endurance":
			return "Endurance"
		"block":
			return "Block"
		"willpower":
			return "Willpower"
		"pv":
			return "PV"
		"mana":
			return "Mana"
		"resistance":
			return "Resistance"
		_:
			return bonus_type.capitalize()

func is_percentage_bonus(bonus_type: String) -> bool:
	# Percentage bonuses based on the combat stats specification
	match bonus_type:
		"damage", "critical_chance", "critical_multiplier", "resistance":
			return true
		"accuracy", "dodge", "endurance", "block", "willpower", "pv", "mana":
			return false
		_:
			return false

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
	
	# Update race button states
	for race_name in race_ui_elements:
		update_race_button_state(race_name)
	
	# Update trait display based on selected race
	var selected_race = race_manager.get_selected_race()
	if selected_race != "":
		update_trait_display(selected_race)
	else:
		# Reset trait display if no race selected
		trait_name_label.text = "Select a race to see its trait"
		trait_desc_label.text = ""
		trait_bonuses_label.text = ""
	
	# Update continue button state using UIManager
	var continue_button = get_node("CenterContainer/VBoxContainer/ButtonsContainer/ContinueButton")
	var character_name = character_name_input.text.strip_edges()
	var can_continue = attribute_manager.all_points_spent() and race_manager.all_points_spent() and character_name.length() > 0 and selected_sex != ""
	UIManager.apply_button_state(continue_button, can_continue)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_continue_button_pressed():
	# Check if all points have been spent and race selected
	if not attribute_manager.all_points_spent():
		print("Cannot continue: You must spend all %d attribute points before proceeding!" % attribute_manager.get_remaining_points())
		UIManager.flash_error_feedback(points_label)
		return
	
	if not race_manager.all_points_spent():
		print("Cannot continue: You must select a race before proceeding!")
		return
	
	# Check if character name is provided
	var character_name = get_character_name()
	if character_name.length() == 0:
		print("Cannot continue: You must enter a character name!")
		character_name_input.modulate = Color.RED
		var tween = character_name_input.create_tween()
		tween.tween_property(character_name_input, "modulate", Color.WHITE, 0.5)
		return
	
	# Store step 1 data in global CharacterCreation
	CharacterCreation.set_step1_data(
		character_name,
		race_manager.get_selected_race(),
		selected_sex,
		attribute_manager.get_character_items()
	)
	
	# Print character stats
	attribute_manager.print_character_stats()
	print("Selected Race: %s" % race_manager.get_selected_race())
	print("Character Name: %s" % character_name)
	
	# Navigate to step 2 (abilities & competences allocation)
	get_tree().change_scene_to_file("res://scenes/character_creation/character_creation_step2.tscn") 
