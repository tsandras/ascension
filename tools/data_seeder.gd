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
	print("Sample CSV files created")

# Force create sample CSV files (overwrite existing)
func force_create_sample_csv_files():
	create_sample_nodes_csv()
	create_sample_traits_csv()
	create_sample_backgrounds_csv()
	create_sample_features_csv()
	print("Sample CSV files force created (overwritten)")

# Create sample nodes CSV
func create_sample_nodes_csv():
	var csv_content = """name,icon_name,node_type,attribute_bonuses,master_attribute_bonuses,ability_bonuses,trait_id,skill_id,description
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
	var csv_content = """name,description,icon_name,attribute_bonuses,ability_bonuses,skill_bonuses,other_bonuses
Elf Blood,You have elven heritage,elf_blood,{'agility': 1},{'perception': 1},{'arcana': 1},Long lifespan
Human Adaptability,You adapt quickly to new situations,human_adapt,{'intelligence': 1},{'knowledge': 1},{},Bonus experience
Dwarven Toughness,You are naturally hardy,dwarf_tough,{'vitality': 1},{'athletics': 1},{},Poison resistance
Tiefling Heritage,You have infernal blood,tiefling_herit,{'ruse': 1},{'persuasion': 1},{'arcana': 1},Fire resistance"""
	
	var file = FileAccess.open("res://tools/data/traits.csv", FileAccess.WRITE)
	if file:
		file.store_string(csv_content)
		file.close()
		print("Created sample traits.csv")
	else:
		print("ERROR: Could not create traits.csv")

# Create sample backgrounds CSV
func create_sample_backgrounds_csv():
	var csv_content = """name,description,attribute_bonuses,ability_bonuses,skill_bonuses,starting_equipment
Soldier,You served in the military,{'strength': 1, 'vitality': 1},{'athletics': 1},{'survival': 1},Weapon and armor
Scholar,You studied at a university,{'intelligence': 1, 'resolution': 1},{'knowledge': 1},{'arcana': 1},Books and writing supplies
Rogue,You lived on the streets,{'agility': 1, 'ruse': 1},{'stealth': 1},{'sleight of hand': 1},Lockpicks and dark clothing
Merchant,You ran a business,{'ruse': 1, 'persuasion': 1},{'persuasion': 1},{'knowledge': 1},Trade goods and money"""
	
	var file = FileAccess.open("res://tools/data/backgrounds.csv", FileAccess.WRITE)
	if file:
		file.store_string(csv_content)
		file.close()
		print("Created sample backgrounds.csv")
	else:
		print("ERROR: Could not create backgrounds.csv")

# Create sample features CSV
func create_sample_features_csv():
	var csv_content = """name,description,icon_name,trait_id,attribute_bonuses,ability_bonuses,skill_bonuses,other_bonuses
Elf Blood,You have elven heritage,elf_blood,1,{'agility': 1},{'perception': 1},{'arcana': 1},Long lifespan
Human Adaptability,You adapt quickly to new situations,human_adapt,2,{'intelligence': 1},{'knowledge': 1},{},Bonus experience
Dwarven Toughness,You are naturally hardy,dwarf_tough,3,{'vitality': 1},{'athletics': 1},{},Poison resistance
Tiefling Heritage,You have infernal blood,tiefling_herit,4,{'ruse': 1},{'persuasion': 1},{'arcana': 1},Fire resistance"""
	
	var file = FileAccess.open("res://tools/data/features.csv", FileAccess.WRITE)
	if file:
		file.store_string(csv_content)
		file.close()
		print("Created sample features.csv")
	else:
		print("ERROR: Could not create features.csv")

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
			# Parse data line
			var values = line.split(",")
			var row = {}
			
			for i in range(headers.size()):
				var header = headers[i].strip_edges()
				var value = values[i].strip_edges() if i < values.size() else ""
				
				# Handle JSON fields (replace single quotes with double quotes)
				if header in ["attribute_bonuses", "master_attribute_bonuses", "ability_bonuses", "skill_bonuses", "other_bonuses", "starting_equipment"]:
					if value != "{}" and value != "NULL":
						value = parse_json_field(value)
					else:
						value = {}
				elif value == "NULL":
					value = null
				
				row[header] = value
			
			lines.append(row)
	
	file.close()
	return lines

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
			"trait_id": row.trait_id,
			"skill_id": row.skill_id,
			"description": row.description
		}
		
		# Debug: Print JSON parsing info
		print("Raw attribute_bonuses: ", row.attribute_bonuses)
		print("Parsed attribute_bonuses: ", node_data.attribute_bonuses)
		print("Final JSON string: ", JSON.stringify(node_data.attribute_bonuses))
		
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
			"description": row.description,
			"icon_name": row.icon_name,
			"attribute_bonuses": row.attribute_bonuses,
			"ability_bonuses": row.ability_bonuses,
			"skill_bonuses": row.skill_bonuses,
			"other_bonuses": row.other_bonuses
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
			"attribute_bonuses": row.attribute_bonuses,
			"ability_bonuses": row.ability_bonuses,
			"skill_bonuses": row.skill_bonuses,
			"starting_equipment": row.starting_equipment
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
			"icon_name": row.icon_name,
			"trait_id": row.trait_id,
			"attribute_bonuses": row.attribute_bonuses,
			"ability_bonuses": row.ability_bonuses,
			"skill_bonuses": row.skill_bonuses,
			"other_bonuses": row.other_bonuses
		}
		
		database_manager.create_feature(feature_data)
	
	print("Features seeded successfully!")

# Clear all game data
func clear_all_game_data():
	print("Clearing all game data...")
	database_manager.clear_nodes()
	database_manager.clear_traits()
	database_manager.clear_backgrounds()
	database_manager.clear_features()
	print("All game data cleared!")

# Seed all data from CSV files
func seed_all_from_csv():
	print("Seeding all data from CSV files...")
	seed_nodes_from_csv()
	seed_traits_from_csv()
	seed_backgrounds_from_csv()
	seed_features_from_csv()
	print("All data seeded successfully!")
