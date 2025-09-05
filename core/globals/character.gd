extends RefCounted

class_name Character

# Character data
var id: int = -1
var name: String = ""
var race_name: String = ""
var background_name: String = ""
var feature_name: String = ""
var personality_name: String = ""
var sex: String = ""
var portrait: String = ""
var avatar: String = ""
var level: int = 1
var attributes: Dictionary = {}
var abilities: Dictionary = {}
var created_at: String = ""

# Stats instance for calculations
var stats: Stats

func _init():
	stats = Stats.new()

func get_attribute_value(attribute_name: String) -> int:
	"""Get the value of a specific attribute"""
	var normalized_name = attribute_name.to_lower()
	if attributes.has(normalized_name):
		return attributes[normalized_name]
	return 0

# Load character from database by ID
static func load_from_db(character_id: int = -1) -> Character:
	var character_data: Dictionary
	
	if character_id > 0:
		character_data = DatabaseManager.get_character_by_id(character_id)
	else:
		character_data = DatabaseManager.get_last_saved_character()
	
	if character_data.size() == 0:
		if character_id > 0:
			print("Character not found with ID: ", character_id)
		else:
			print("No saved characters found")
		return null
	
	var character = Character.new()
	character.id = character_data.id
	character.name = character_data.name
	character.race_name = character_data.race_name
	character.background_name = character_data.background_name if character_data.has("background_name") else ""
	character.feature_name = character_data.feature_name if character_data.has("feature_name") else ""
	character.personality_name = character_data.personality_name if character_data.has("personality_name") else ""
	character.sex = character_data.sex
	character.created_at = character_data.created_at
	
	# Load JSON data
	if character_data.has("attributes_dict"):
		character.attributes = character_data.attributes_dict
	if character_data.has("abilities_dict"):
		character.abilities = character_data.abilities_dict
	
	if character_id > 0:
		print("Loaded character: ", character.name)
	else:
		print("Loaded last saved character: ", character.name)
	return character

# Load character from CharacterCreation globals
static func load_from_creation() -> Character:
	if CharacterCreation.character_name == "":
		print("No character data available in CharacterCreation")
		return null
	
	var character = Character.new()
	character.name = CharacterCreation.character_name
	character.race_name = CharacterCreation.selected_race
	character.background_name = CharacterCreation.selected_background
	character.feature_name = CharacterCreation.selected_feature
	character.personality_name = CharacterCreation.selected_personality
	character.sex = CharacterCreation.selected_sex
	character.portrait = CharacterCreation.selected_portrait
	character.avatar = CharacterCreation.selected_avatar
	
	# Handle attributes - ensure it's a Dictionary
	if CharacterCreation.attributes is Dictionary:
		character.attributes = CharacterCreation.attributes
	else:
		character.attributes = {}
	
	# Handle abilities - ensure it's a Dictionary
	if CharacterCreation.abilities is Dictionary:
		character.abilities = CharacterCreation.abilities
	else:
		character.abilities = {}
	

	
	print("Loaded character from creation: ", character.name)
	return character

# Save character to database
func save_to_db() -> int:
	if name == "":
		print("Cannot save character: no name")
		return -1
	
	var character_id = DatabaseManager.save_character(
		name, 
		race_name, 
		background_name, 
		feature_name, 
		personality_name, 
		sex, 
		portrait, 
		avatar, 
		attributes, 
		abilities
	)
	
	if character_id > 0:
		self.id = character_id
		print("Character saved with ID: ", character_id)
	else:
		print("Failed to save character")
	
	return character_id

# Load character from database result dictionary
static func load_from_db_result(character_data: Dictionary) -> Character:
	var character = Character.new()
	character.id = character_data.id
	character.name = character_data.name
	character.race_name = character_data.race_name
	character.background_name = character_data.background_name if character_data.has("background_name") else ""
	character.feature_name = character_data.feature_name if character_data.has("feature_name") else ""
	character.personality_name = character_data.personality_name if character_data.has("personality_name") else ""
	character.sex = character_data.sex
	character.portrait = character_data.get("portrait", "")
	character.avatar = character_data.get("avatar", "")
	character.created_at = character_data.created_at
	
	# Load JSON data
	if character_data.has("attributes_dict"):
		character.attributes = character_data.attributes_dict
	if character_data.has("abilities_dict"):
		character.abilities = character_data.abilities_dict
	
	print("Loaded character from database result: ", character.name)
	return character

# Get character data for UI display
func get_character_data() -> Dictionary:
	return {
		"name": name,
		"race_name": race_name,
		"background_name": background_name,
		"feature_name": feature_name,
		"personality_name": personality_name,
		"sex": sex,
		"portrait": portrait,
		"avatar": avatar,
		"level": level,
		"attributes_dict": attributes,
		"abilities_dict": abilities
	}

# Get attribute value
func get_attribute(attribute_name: String) -> int:
	# Make attribute lookup case-insensitive
	var search_name = attribute_name.to_lower()
	for attr_name in attributes:
		if attr_name.to_lower() == search_name:
			return attributes[attr_name]
	return 0

# Get ability value
func get_ability(ability_name: String) -> int:
	# Make ability lookup case-insensitive
	var search_name = ability_name.to_lower()
	for abil_name in abilities:
		if abil_name.to_lower() == search_name:
			return abilities[abil_name]
	return 0





# Calculate character stats
func get_pv_max() -> int:
	var stamina = get_attribute("stamina")
	return stats.pv_max(stamina, level)

func get_endurance_max() -> int:
	var strength = get_attribute("strength")
	return stats.endurance_max(strength)

func get_mana_max() -> int:
	var essence = get_attribute("essence")
	return stats.mana_max(essence)

func get_skill_slots_max() -> int:
	var intelligence = get_attribute("intelligence")
	return stats.skill_slots_max(intelligence)

func get_block_max() -> int:
	var agility = get_attribute("agility")
	return stats.block_max(agility)

func get_willpower_max() -> int:
	var resolution = get_attribute("resolution")
	return stats.willpower_max(resolution)

# Get all calculated stats as a dictionary
func get_all_stats() -> Dictionary:
	return {
		"pv_max": get_pv_max(),
		"endurance_max": get_endurance_max(),
		"mana_max": get_mana_max(),
		"skill_slots_max": get_skill_slots_max(),
		"block_max": get_block_max(),
		"willpower_max": get_willpower_max()
	}

# Check if character has valid data
func is_valid() -> bool:
	return name != "" and race_name != "" and sex != ""

# Get avatar path
func get_avatar_path() -> String:
	if not is_valid():
		return ""
	
	if avatar != "":
		return "res://assets/avatars/" + avatar + ".png"
	else:
		# Fallback to old race/sex based path
		var race_lowercase = race_name.to_lower()
		return "res://assets/avatars/%s_%s_1.png" % [sex, race_lowercase]

# Get portrait path
func get_portrait_path() -> String:
	if not is_valid():
		return ""
	
	if portrait != "":
		return "res://assets/ink_portraits/" + portrait + ".png"
	else:
		# Fallback to avatar path
		return get_avatar_path()

# Get display name with race and sex
func get_display_name() -> String:
	if not is_valid():
		return "Unknown Character"
	
	return "%s (%s %s)" % [name, sex, race_name]

# Get position display string
func get_position_display(grid_pos: Vector2) -> String:
	return "Position: (%d, %d)" % [grid_pos.x, grid_pos.y] 
