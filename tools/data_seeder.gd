extends Node

# Data seeder tool for importing game data from CSV files
# Handles nodes, traits, backgrounds, and features

var database_manager: Node

func _ready():
	# Get reference to database manager
	database_manager = get_node("/root/DatabaseManager")
	if not database_manager:
		print("ERROR: DatabaseManager not found!")
		return
	
	print("Data Seeder Tool initialized")

# Create tools directory if it doesn't exist
func create_tools_directory():
	var dir = DirAccess.open("res://tools")
	if not dir:
		print("ERROR: Cannot access tools directory")
		return false
	
	if not dir.dir_exists("data"):
		dir.make_dir("data")
		print("Created tools/data directory")
	
	return true

# Create sample CSV files for testing
func create_sample_csv_files():
	create_sample_nodes_csv()
	create_sample_traits_csv()
	create_sample_backgrounds_csv()
	create_sample_features_csv()
	create_sample_races_csv()
	create_sample_personalities_csv()
	print("Sample CSV files created")

# Force create sample CSV files (overwrite existing)
func force_create_sample_csv_files():
	create_sample_nodes_csv()
	create_sample_traits_csv()
	create_sample_backgrounds_csv()
	create_sample_features_csv()
	create_sample_races_csv()
	create_sample_personalities_csv()
	print("Sample CSV files force created (overwritten)")

# Create sample nodes CSV
func create_sample_nodes_csv():
	var csv_content = """name,icon_name,node_type,attribute_bonuses,master_attribute_bonuses,ability_bonuses,trait,skill,description
strength,strength,ATTRIBUTE,{'strength': 1},{},{},NULL,NULL,Physical strength and power
intelligence,intelligence,ATTRIBUTE,{'intelligence': 1},{},{},NULL,NULL,Reasoning and learning ability
ruse,ruse,ATTRIBUTE,{'ruse': 1},{},{},NULL,NULL,Cunning and deception
agility,agility,ATTRIBUTE,{'agility': 1},{},{},NULL,NULL,Physical agility and reflexes
resolution,resolution,ATTRIBUTE,{'resolution': 1},{},{},NULL,NULL,Mental resilience and determination
vitality,vitality,ATTRIBUTE,{'vitality': 1},{},{},NULL,NULL,Endurance and vitality
survival,survival,ABILITY,{},{},{'survival': 1},NULL,NULL,Wilderness survival skills
perception,perception,ABILITY,{},{},{'perception': 1},NULL,NULL,Alertness and awareness
stealth,stealth,ABILITY,{},{},{'stealth': 1},NULL,NULL,Sneaking and hiding
knowledge,knowledge,ABILITY,{},{},{'knowledge': 1},NULL,NULL,Academic and scholarly knowledge
arcana,arcana,ABILITY,{},{},{'arcana': 1},NULL,NULL,Magical knowledge and theory
sleight of hand,sleight of hand,ABILITY,{},{},{'sleight of hand': 1},NULL,NULL,Pickpocketing and manual dexterity
persuasion,persuasion,ABILITY,{},{},{'persuasion': 1},NULL,NULL,Social influence and diplomacy
athletics,athletics,ABILITY,{},{},{'athletics': 1},NULL,NULL,Physical sports and acrobatics
speed,speed,MASTER_ATTRIBUTE,{},{'speed': 1},{},NULL,NULL,Overall movement and reaction speed
magic,magic,MASTER_ATTRIBUTE,{},{'magic': 1},{},NULL,NULL,Magical power and energy
resistance,resistance,MASTER_ATTRIBUTE,{},{'resistance': 1},{},NULL,NULL,Overall damage resistance"""
	
	var file = FileAccess.open("res://tools/data/nodes.csv", FileAccess.WRITE)
	if file:
		file.store_string(csv_content)
		file.close()
		print("Created sample nodes.csv")
	else:
		print("ERROR: Could not create nodes.csv")

# Create sample traits CSV
func create_sample_traits_csv():
	var csv_content = """name,icon_name,point_bonuses,attribute_scaling_bonuses,master_attribute_scaling_bonuses,others_bonuses
big,big,,-{agility}x0.5 [Ward]; {strenght}x0.5 to [Physical damage],,
small,small,,{agility}x0.5 [Ward]; -{strenght}x0.5 to [Physical damage],,
magic resistance,magic_resistance,,,{magic} [magic RP]; {magic}x4 to [Magic tenacity],
regeneration,regeneration,,,,regenerate 5% {HP} per round
extraordinary vigor,extraordinary_vigor,,{vigor}x2 [physical Tenacity],,
extraordinary reflex,extraordinary_reflex,,,,first physical attack/round have 100% [Chance avoidance]
extraordinary force,extraordinary_force,,{strenght}x0.5 to [Physical damage],,
slow learner,slow_learner,-1:4,,,
quick learner,quick_learner,1:4,,,
lucky,lucky,,,,10% [Chance avoidance]; 10% to [Critical chance]
magic affinity,magic_affinity,,{intelligence}x2 [MP],,"""
	
	var file = FileAccess.open("res://tools/data/traits.csv", FileAccess.WRITE)
	if file:
		file.store_string(csv_content)
		file.close()
		print("Created sample traits.csv")
	else:
		print("ERROR: Could not create traits.csv")

# Create sample backgrounds CSV
func create_sample_backgrounds_csv():
	var csv_content = """name,ability_bonuses,description
soldier,"{'athletics': 1, 'perception': 1}",Was a soldier
scholar,"{'knowledge': 1, 'arcana': 1}",Was a scholar
acolyte,"{'knowledge': 1, 'insight': 1}",Was a acolyte
artisan,"{'insight': 1, 'persuasion': 1}",Was a artisan
criminal,"{'stealth': 1, 'sleight of hand': 1}",Was a criminal
entertainer,"{'athletics': 1, 'persuasion': 1}",Was a entertainer
noble,"{'knowledge': 1, 'persuasion': 1}",Was a noble
outlander,"{'survival': 1, 'perception': 1}",Was a outlander"""
	
	var file = FileAccess.open("res://tools/data/backgrounds.csv", FileAccess.WRITE)
	if file:
		file.store_string(csv_content)
		file.close()
		print("Created sample backgrounds.csv")
	else:
		print("ERROR: Could not create backgrounds.csv")

# Create sample features CSV
func create_sample_features_csv():
	var csv_content = """name,trait,attribute_bonuses,description
mist-touched,mist-touched,{'resolution': 1},The magic mist infected the character
astral symbiosis,astral symbiosis,{'intelligence': 1},The character have a astral symbiot
diviner,diviner,{'ruse': 1},The character have superior visions
celestial-blooded,celestial-blooded,{'agility': 1},The character have celestial ancestors
infernal-blooded,infernal-blooded,{'strength': 1},The character have infernal ancestors
dhampire,dhampyre,{'vitality': 1},The character have a vampire as parent
heros,heros,{},The character is a hero"""
	
	var file = FileAccess.open("res://tools/data/features.csv", FileAccess.WRITE)
	if file:
		file.store_string(csv_content)
		file.close()
		print("Created sample features.csv")
	else:
		print("ERROR: Could not create features.csv")

# Create sample races CSV
func create_sample_races_csv():
	var csv_content = """name,attribute_bonuses,master_attribute_bonuses,traits,description
human,{},,quick learner,The humans are numerous
elf,"{'agility': 1, 'intelligence': 1}",,magic affinity,The elfs are rare
dwarf,"{'vitality': 1, 'resolution': 1}",,extraordinary vigor,The dwarfs live under mountains
hobbit,"{'agility': 1, 'ruse': 1}",,"small, lucky",The hobbits are lucky
orc,"{'strength': 1, 'vitality': 1}",,extraordinary force,The orc are strong
troll,"{'vitality': 1, 'strength': 1}",{'resistance': 1},"regeneration, big, slow learner",The troll are resistante
gnoll,{'agility': 1},{'speed': 1},"extraordinary reflex, slow learner",The gnoll are quick
dragonborn,{'strength': 1},{'magic': 1},"magic resistance, slow learner",The dragonborn are strange"""
	
	var file = FileAccess.open("res://tools/data/races.csv", FileAccess.WRITE)
	if file:
		file.store_string(csv_content)
		file.close()
		print("Created sample races.csv")
	else:
		print("ERROR: Could not create races.csv")

# Create sample personalities CSV
func create_sample_personalities_csv():
	var csv_content = """name,description
degenerate,a degenerate person
righteous,a righteous person
vengeful,a vengeful person
altruistic,a altruistic person
ambitious,a ambitious person
greed,a greed person"""
	
	var file = FileAccess.open("res://tools/data/personalities.csv", FileAccess.WRITE)
	if file:
		file.store_string(csv_content)
		file.close()
		print("Created sample personalities.csv")
	else:
		print("ERROR: Could not create personalities.csv")

# Read CSV file and return array of dictionaries
func read_csv_file(file_path: String) -> Array:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("ERROR: Could not open file: ", file_path)
		return []
	
	var lines = []
	var headers = []
	var is_first_line = true
	
	while not file.eof_reached():
		var line = file.get_line()
		if line.strip_edges().is_empty():
			continue
		
		if is_first_line:
			# Parse headers
			headers = line.split(",")
			is_first_line = false
		else:
			# Parse data line - handle CSV with commas inside quoted fields
			var values = parse_csv_line(line)
			var row = {}
			
			for i in range(headers.size()):
				var header = headers[i].strip_edges()
				var value = values[i].strip_edges() if i < values.size() else ""
				
				# Handle JSON fields (replace single quotes with double quotes)
				if header in ["attribute_bonuses", "master_attribute_bonuses", "ability_bonuses", "skill_bonuses", "other_bonuses", "starting_equipment"]:
					if value != "{}" and value != "NULL" and value != "":
						# Remove surrounding quotes if present
						if value.begins_with('"') and value.ends_with('"'):
							value = value.substr(1, value.length() - 2)
						value = parse_json_field(value)
					else:
						value = {}
				elif header == "traits":
					# Traits is a comma-separated string, not JSON
					if value == "NULL" or value == "":
						value = null
					else:
						# Remove surrounding quotes if present
						if value.begins_with('"') and value.ends_with('"'):
							value = value.substr(1, value.length() - 2)
				elif value == "NULL" or value == "":
					value = null
				
				row[header] = value
			
			lines.append(row)
	
	file.close()
	return lines

# Parse CSV line handling commas inside quoted fields
func parse_csv_line(line: String) -> Array:
	var values = []
	var current_value = ""
	var in_quotes = false
	var i = 0
	
	while i < line.length():
		var char = line[i]
		
		if char == '"':
			if in_quotes and i + 1 < line.length() and line[i + 1] == '"':
				# Escaped quote
				current_value += '"'
				i += 2
				continue
			else:
				# Toggle quote state
				in_quotes = !in_quotes
		elif char == ',' and not in_quotes:
			# End of field
			values.append(current_value)
			current_value = ""
		else:
			current_value += char
		
		i += 1
	
	# Add the last field
	values.append(current_value)
	
	return values

# Parse JSON field, handling single quotes for Google Sheets compatibility
func parse_json_field(field_value: String):
	if field_value.is_empty() or field_value == "{}":
		return {}
	
	# Replace single quotes with double quotes for valid JSON
	var json_string = field_value.replace("'", "\"")
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result == OK:
		var data = json.data
		# Convert float values to integers if they represent whole numbers
		data = convert_floats_to_ints(data)
		return data
	else:
		print("ERROR: Failed to parse JSON field: ", field_value)
		print("JSON error: ", json.get_error_message())
		return {}

# Convert float values to integers if they represent whole numbers
func convert_floats_to_ints(data):
	if data is Dictionary:
		var result = {}
		for key in data:
			result[key] = convert_floats_to_ints(data[key])
		return result
	elif data is Array:
		var result = []
		for item in data:
			result.append(convert_floats_to_ints(item))
		return result
	elif data is float:
		# Check if float represents a whole number
		if data == int(data):
			return int(data)
		else:
			return data
	else:
		return data

# Helper function to get trait ID by name
func get_trait_id_by_name(trait_name) -> int:
	if trait_name == null or trait_name == "NULL" or (trait_name is String and trait_name.is_empty()):
		return 0
	
	var traitv = database_manager.get_trait_by_name(trait_name)
	if traitv:
		return traitv.id
	else:
		print("WARNING: Trait not found: ", trait_name)
		return 0

# Helper function to get skill ID by name (assuming skills are stored as abilities)
func get_skill_id_by_name(skill_name) -> int:
	if skill_name == null or skill_name == "NULL" or (skill_name is String and skill_name.is_empty()):
		return 0
	
	var ability = database_manager.get_ability_by_name(skill_name)
	if ability:
		return ability.id
	else:
		print("WARNING: Skill/Ability not found: ", skill_name)
		return 0

# Helper functions now use actual database manager methods

# Seed nodes from CSV
func seed_nodes_from_csv():
	print("Seeding nodes from CSV...")
	
	var csv_data = read_csv_file("res://tools/data/nodes.csv")
	if csv_data.is_empty():
		print("ERROR: No data found in nodes.csv")
		return
	
	# Clear existing nodes
	database_manager.clear_nodes()
	
	# Insert new nodes
	for row in csv_data:
		var node_data = {
			"name": row.name,
			"icon_name": row.icon_name,
			"node_type": row.node_type,
			"attribute_bonuses": row.attribute_bonuses,
			"master_attribute_bonuses": row.master_attribute_bonuses,
			"ability_bonuses": row.ability_bonuses,
			"trait_id": get_trait_id_by_name(row.trait),
			"skill_id": get_skill_id_by_name(row.skill),
			"description": row.description
		}
		
		database_manager.create_node(node_data)
	
	print("Nodes seeded successfully!")

# Seed traits from CSV
func seed_traits_from_csv():
	print("Seeding traits from CSV...")
	
	var csv_data = read_csv_file("res://tools/data/traits.csv")
	if csv_data.is_empty():
		print("ERROR: No data found in traits.csv")
		return
	
	# Clear existing traits
	database_manager.clear_traits()
	
	# Insert new traits
	for row in csv_data:
		var trait_data = {
			"name": row.name,
			"description": "",  # No description in new CSV
			"icon_name": row.icon_name,
			"point_bonuses": row.point_bonuses if row.has("point_bonuses") else "",
			"attribute_scaling_bonuses": row.attribute_scaling_bonuses if row.has("attribute_scaling_bonuses") else "",
			"master_attribute_scaling_bonuses": row.master_attribute_scaling_bonuses if row.has("master_attribute_scaling_bonuses") else "",
			"others_bonuses": row.others_bonuses if row.has("others_bonuses") else ""
		}
		
		database_manager.create_trait(trait_data)
	
	print("Traits seeded successfully!")

# Seed backgrounds from CSV
func seed_backgrounds_from_csv():
	print("Seeding backgrounds from CSV...")
	
	var csv_data = read_csv_file("res://tools/data/backgrounds.csv")
	if csv_data.is_empty():
		print("ERROR: No data found in backgrounds.csv")
		return
	
	# Clear existing backgrounds
	database_manager.clear_backgrounds()
	
	# Insert new backgrounds
	for row in csv_data:
		var background_data = {
			"name": row.name,
			"description": row.description,
			"attribute_bonuses": {},
			"ability_bonuses": row.ability_bonuses,
			"skill_bonuses": {},
			"starting_equipment": ""
		}
		
		database_manager.create_background(background_data)
	
	print("Backgrounds seeded successfully!")

# Seed features from CSV
func seed_features_from_csv():
	print("Seeding features from CSV...")
	
	var csv_data = read_csv_file("res://tools/data/features.csv")
	if csv_data.is_empty():
		print("ERROR: No data found in features.csv")
		return
	
	# Clear existing features
	database_manager.clear_features()
	
	# Insert new features
	for row in csv_data:
		var feature_data = {
			"name": row.name,
			"description": row.description,
			"icon_name": "",
			"trait_id": get_trait_id_by_name(row.trait),
			"attribute_bonuses": row.attribute_bonuses,
			"ability_bonuses": {},
			"skill_bonuses": {},
			"other_bonuses": ""
		}
		
		database_manager.create_feature(feature_data)
	
	print("Features seeded successfully!")

# Seed races from CSV
func seed_races_from_csv():
	print("Seeding races from CSV...")
	
	var csv_data = read_csv_file("res://tools/data/races.csv")
	if csv_data.is_empty():
		print("ERROR: No data found in races.csv")
		return
	
	# Clear existing races
	database_manager.clear_races()
	
	# Insert new races
	for row in csv_data:
		var race_data = {
			"name": row.name,
			"description": row.description,
			"attribute_bonuses": row.attribute_bonuses,
			"master_attribute_bonuses": row.master_attribute_bonuses,
			"traits": row.traits
		}
		
		database_manager.create_race(race_data)
	
	print("Races seeded successfully!")

# Seed personalities from CSV
func seed_personalities_from_csv():
	print("Seeding personalities from CSV...")
	
	var csv_data = read_csv_file("res://tools/data/personalities.csv")
	if csv_data.is_empty():
		print("ERROR: No data found in personalities.csv")
		return
	
	# Clear existing personalities
	database_manager.clear_personalities()
	
	# Insert new personalities
	for row in csv_data:
		var personality_data = {
			"name": row.name,
			"description": row.description
		}
		
		database_manager.create_personality(personality_data)
	
	print("Personalities seeded successfully!")

# Clear all game data
func clear_all_game_data():
	print("Clearing all game data...")
	database_manager.clear_nodes()
	database_manager.clear_traits()
	database_manager.clear_backgrounds()
	database_manager.clear_features()
	database_manager.clear_races()
	database_manager.clear_personalities()
	print("All game data cleared!")

# Seed all data from CSV files (in dependency order)
func seed_all_from_csv():
	print("Seeding all data from CSV files...")
	# Seed in dependency order: traits first, then others
	seed_traits_from_csv()
	seed_personalities_from_csv()
	seed_races_from_csv()
	seed_backgrounds_from_csv()
	seed_features_from_csv()
	seed_nodes_from_csv()
	print("All data seeded successfully!")

# Seed data with traits first (for dependencies)
func seed_with_traits_first():
	print("Seeding data with traits first...")
	seed_traits_from_csv()
	seed_backgrounds_from_csv()
	seed_features_from_csv()
	seed_nodes_from_csv()
	print("Data with traits seeded successfully!")
