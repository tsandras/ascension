extends Node

# Character creation data that persists between steps
var character_name: String = ""
var selected_race: String = ""
var selected_sex: String = ""
var attributes: Dictionary = {}
var abilities: Dictionary = {}
var competences: Dictionary = {}
var skills: Dictionary = {}
var current_trait_data: Dictionary = {}

func reset_character_data():
	"""Reset all character creation data"""
	character_name = ""
	selected_race = ""
	selected_sex = ""
	attributes.clear()
	abilities.clear()
	competences.clear()
	skills.clear()
	current_trait_data.clear()

func set_step1_data(char_name: String, race: String, sex: String, attr: Dictionary):
	"""Store data from character creation step 1"""
	character_name = char_name
	selected_race = race
	selected_sex = sex
	attributes = attr.duplicate()
	print("Stored step 1 data - Name: %s, Race: %s, Sex: %s" % [character_name, selected_race, selected_sex])

func set_step2_data(abil: Dictionary, competence: Dictionary):
	"""Store data from character creation step 2"""
	abilities = abil.duplicate()
	competences = competence.duplicate()
	print("Stored step 2 data - Abilities and competences set")

func set_step3_data(skill: Dictionary):
	"""Store data from character creation step 3"""
	skills = skill.duplicate()
	print("Stored step 3 data - Skills set")

func get_skills_array() -> Array:
	"""Convert skills dictionary to array of IDs for database storage"""
	var skills_array = []
	for skill_id in skills.values():
		skills_array.append(skill_id)
	return skills_array

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
		competences,
		get_skills_array()
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

func load_saved_character(character_data: Dictionary):
	"""Load a saved character into the global CharacterCreation data"""
	if character_data.is_empty():
		print("Error: No character data provided")
		return
	
	# Load basic character info
	character_name = character_data.name
	selected_race = character_data.race_name
	selected_sex = character_data.sex
	
	# Load attributes, abilities, competences, and skills
	if character_data.has("attributes_dict"):
		var attr_data = character_data.attributes_dict
		if attr_data is String:
			var json = JSON.new()
			if json.parse(attr_data) == OK:
				attributes = json.data
			else:
				attributes = {}
		else:
			attributes = attr_data.duplicate()
	else:
		attributes = {}
	
	if character_data.has("abilities_dict"):
		var abil_data = character_data.abilities_dict
		if abil_data is String:
			var json = JSON.new()
			if json.parse(abil_data) == OK:
				abilities = json.data
			else:
				abilities = {}
		else:
			abilities = abil_data.duplicate()
	else:
		abilities = {}
	
	if character_data.has("competences_dict"):
		var comp_data = character_data.competences_dict
		if comp_data is String:
			var json = JSON.new()
			if json.parse(comp_data) == OK:
				competences = json.data
			else:
				competences = {}
		else:
			competences = comp_data.duplicate()
	else:
		competences = {}
	
	if character_data.has("skills_dict"):
		# Handle skills data - could be string, array, or dictionary
		var skills_data = character_data.skills_dict
		
		# If it's a string, parse it as JSON
		if skills_data is String:
			var json = JSON.new()
			if json.parse(skills_data) == OK:
				skills_data = json.data
			else:
				print("Failed to parse skills JSON: ", skills_data)
				skills_data = []
		
		# Convert array back to dictionary for internal use
		skills = {}
		if skills_data is Array:
			for skill_id in skills_data:
				skills[str(skill_id)] = skill_id
		elif skills_data is Dictionary:
			skills = skills_data.duplicate()
		else:
			print("Unexpected skills data type: ", typeof(skills_data))
			skills = {}
	else:
		skills = {}
	
	print("Loaded saved character: %s (%s %s)" % [character_name, selected_sex, selected_race])
	print("Attributes: ", attributes)
	print("Abilities: ", abilities)
	print("Competences: ", competences)
	print("Skills: ", skills) 
