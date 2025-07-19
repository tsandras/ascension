extends Node

# Character creation data that persists between steps
var character_name: String = ""
var selected_race: String = ""
var selected_sex: String = ""
var attributes: Dictionary = {}
var abilities: Dictionary = {}
var skills: Dictionary = {}

func reset_character_data():
	"""Reset all character creation data"""
	character_name = ""
	selected_race = ""
	selected_sex = ""
	attributes.clear()
	abilities.clear()
	skills.clear()

func set_step1_data(char_name: String, race: String, sex: String, attr: Dictionary):
	"""Store data from character creation step 1"""
	character_name = char_name
	selected_race = race
	selected_sex = sex
	attributes = attr.duplicate()
	print("Stored step 1 data - Name: %s, Race: %s, Sex: %s" % [character_name, selected_race, selected_sex])

func set_step2_data(abil: Dictionary, skill: Dictionary):
	"""Store data from character creation step 2"""
	abilities = abil.duplicate()
	skills = skill.duplicate()
	print("Stored step 2 data - Abilities and skills set")

func save_character() -> int:
	"""Save the complete character to database"""
	if character_name == "" or selected_race == "":
		print("Error: Missing character name or race")
		return -1
	
	var character_id = DatabaseManager.save_character(
		character_name,
		selected_race,
		selected_sex,
		attributes,
		abilities,
		skills
	)
	
	if character_id > 0:
		print("Character '%s' saved successfully with ID: %d" % [character_name, character_id])
		reset_character_data()  # Clear data after successful save
	else:
		print("Failed to save character")
	
	return character_id

func has_complete_data() -> bool:
	"""Check if we have all required data for character creation"""
	return character_name != "" and selected_race != "" and selected_sex != "" and attributes.size() > 0 
