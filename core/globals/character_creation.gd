extends Node

# Character creation data that persists between steps
var character_name: String = ""
var selected_race: String = ""
var selected_sex: String = ""
var selected_portrait: String = ""
var selected_avatar: String = ""
var attributes: Dictionary = {}
var abilities: Dictionary = {}
var competences: Dictionary = {}
var current_trait_data: Dictionary = {}

func reset_character_data():
	"""Reset all character creation data"""
	character_name = ""
	selected_race = ""
	selected_sex = ""
	selected_portrait = ""
	selected_avatar = ""
	attributes.clear()
	abilities.clear()
	competences.clear()
	current_trait_data.clear()

func set_step1_data(char_name: String, race: String, sex: String, portrait: String, avatar: String, attr: Dictionary):
	"""Store data from character creation step 1"""
	character_name = char_name
	selected_race = race
	selected_sex = sex
	selected_portrait = portrait
	selected_avatar = avatar
	attributes = attr.duplicate()
	print("Stored step 1 data - Name: %s, Race: %s, Sex: %s, Portrait: %s, Avatar: %s" % [character_name, selected_race, selected_sex, selected_portrait, selected_avatar])

func set_step2_data(abil: Dictionary, competence: Dictionary):
	"""Store data from character creation step 2"""
	abilities = abil.duplicate()
	competences = competence.duplicate()
	print("Stored step 2 data - Abilities and competences set")

func has_complete_data() -> bool:
	"""Check if we have all required data for character creation"""
	return character_name != "" and selected_race != "" and selected_sex != "" and attributes.size() > 0

 
