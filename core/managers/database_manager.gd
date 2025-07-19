extends Node

# Database file path
var db_name = "res://data/game_data.db"
var db

func is_query_successful() -> bool:
	# SQLite plugin returns "not an error" when successful
	return db.error_message == "" or db.error_message == "not an error"

func _ready():
	# Initialize database
	db = SQLite.new()
	db.path = db_name
	db.open_db()
	
	# Create tables if they don't exist
	create_tables()
	
	# Seed initial data if needed
	seed_data()

func create_tables():
	# Create attributes table (updated base_value to 0)
	var attributes_query = """
	CREATE TABLE IF NOT EXISTS attributes (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		base_value INTEGER NOT NULL DEFAULT 0,
		max_value INTEGER NOT NULL DEFAULT 6,
		display_order INTEGER NOT NULL DEFAULT 0,
		description TEXT
	);
	"""
	
	db.query(attributes_query)
	if not is_query_successful():
		print("Error creating attributes table: ", db.error_message)
	else:
		print("Attributes table created successfully")
	
	# Create abilities table
	var abilities_query = """
	CREATE TABLE IF NOT EXISTS abilities (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		base_value INTEGER NOT NULL DEFAULT 0,
		max_value INTEGER NOT NULL DEFAULT 6,
		display_order INTEGER NOT NULL DEFAULT 0,
		description TEXT
	);
	"""
	
	db.query(abilities_query)
	if not is_query_successful():
		print("Error creating abilities table: ", db.error_message)
	else:
		print("Abilities table created successfully")
	
	# Create races table
	var races_query = """
	CREATE TABLE IF NOT EXISTS races (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		trait_id INTEGER,
		display_order INTEGER NOT NULL DEFAULT 0,
		description TEXT,
		FOREIGN KEY (trait_id) REFERENCES traits(id)
	);
	"""
	
	db.query(races_query)
	if not is_query_successful():
		print("Error creating races table: ", db.error_message)
	else:
		print("Races table created successfully")
	
	# Create traits table
	var traits_query = """
	CREATE TABLE IF NOT EXISTS traits (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		description TEXT,
		attribute_bonuses TEXT,
		ability_bonuses TEXT,
		skill_bonuses TEXT,
		other_bonuses TEXT,
		display_order INTEGER NOT NULL DEFAULT 0
	);
	"""
	
	db.query(traits_query)
	if not is_query_successful():
		print("Error creating traits table: ", db.error_message)
	else:
		print("Traits table created successfully")
	
	# Create skills table
	var skills_query = """
	CREATE TABLE IF NOT EXISTS skills (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		base_value INTEGER NOT NULL DEFAULT 0,
		max_value INTEGER NOT NULL DEFAULT 6,
		display_order INTEGER NOT NULL DEFAULT 0,
		description TEXT
	);
	"""
	
	db.query(skills_query)
	if not is_query_successful():
		print("Error creating skills table: ", db.error_message)
	else:
		print("Skills table created successfully")

	# Create character table for persistent character creation
	var character_query = """
	CREATE TABLE IF NOT EXISTS character (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL,
		race_id INTEGER,
		sex TEXT NOT NULL,
		attributes TEXT,
		abilities TEXT,
		skills TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (race_id) REFERENCES races(id)
	);
	"""
	
	db.query(character_query)
	if not is_query_successful():
		print("Error creating character table: ", db.error_message)
	else:
		print("Character table created successfully")
	
	# Create ref_map table (template maps)
	var ref_map_query = """
	CREATE TABLE IF NOT EXISTS ref_map (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		width INTEGER NOT NULL,
		height INTEGER NOT NULL,
		description TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	"""
	
	db.query(ref_map_query)
	if not is_query_successful():
		print("Error creating ref_map table: ", db.error_message)
	else:
		print("Ref_map table created successfully")
	
	# Create ref_tile table (template tiles)
	var ref_tile_query = """
	CREATE TABLE IF NOT EXISTS ref_tile (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		type_name TEXT NOT NULL UNIQUE,
		is_walkable BOOLEAN NOT NULL DEFAULT 1,
		texture_path TEXT,
		color_hex TEXT DEFAULT '#FFFFFF',
		movement_cost INTEGER DEFAULT 1,
		tileset_x INTEGER DEFAULT 0,
		tileset_y INTEGER DEFAULT 0,
		tile_size INTEGER DEFAULT 50,
		description TEXT
	);
	"""
	
	db.query(ref_tile_query)
	if not is_query_successful():
		print("Error creating ref_tile table: ", db.error_message)
	else:
		print("Ref_tile table created successfully")
	
	# Create ref_map_tile table (template tile layouts)
	var ref_map_tile_query = """
	CREATE TABLE IF NOT EXISTS ref_map_tile (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		ref_map_id INTEGER NOT NULL,
		ref_tile_id INTEGER NOT NULL,
		x INTEGER NOT NULL,
		y INTEGER NOT NULL,
		FOREIGN KEY (ref_map_id) REFERENCES ref_map(id),
		FOREIGN KEY (ref_tile_id) REFERENCES ref_tile(id),
		UNIQUE(ref_map_id, x, y)
	);
	"""
	
	db.query(ref_map_tile_query)
	if not is_query_successful():
		print("Error creating ref_map_tile table: ", db.error_message)
	else:
		print("Ref_map_tile table created successfully")
	
	# Create map_tile table (actual game tiles with state)
	var map_tile_query = """
	CREATE TABLE IF NOT EXISTS map_tile (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		game_id INTEGER DEFAULT 1,
		ref_map_id INTEGER NOT NULL,
		ref_tile_id INTEGER NOT NULL,
		x INTEGER NOT NULL,
		y INTEGER NOT NULL,
		is_occupied BOOLEAN DEFAULT 0,
		character_visited BOOLEAN DEFAULT 0,
		visit_count INTEGER DEFAULT 0,
		entity_id INTEGER,
		last_visited DATETIME,
		FOREIGN KEY (ref_map_id) REFERENCES ref_map(id),
		FOREIGN KEY (ref_tile_id) REFERENCES ref_tile(id),
		UNIQUE(game_id, x, y)
	);
	"""
	
	db.query(map_tile_query)
	if not is_query_successful():
		print("Error creating map_tile table: ", db.error_message)
	else:
		print("Map_tile table created successfully")

func seed_data():
	seed_attributes()
	seed_abilities()
	seed_traits()       # Seed traits before races (foreign key dependency)
	seed_races()
	seed_skills()
	seed_ref_maps()
	seed_ref_tiles()
	seed_ref_map_tiles()

func seed_attributes():
	# Check if we already have attribute data
	var check_query = "SELECT COUNT(*) as count FROM attributes"
	db.query(check_query)
	var result = db.query_result
	
	print("Checking existing attribute data - query result: ", result)
	if result.size() > 0:
		print("Found %d rows, count = %s" % [result.size(), str(result[0]["count"])])
		if result[0]["count"] > 0:
			print("Database already contains attribute data")
			return
	
	print("No existing attribute data found, seeding attributes...")
	
	# Insert the 6 attributes
	var attributes_data = [
		{"name": "Strength", "description": "Physical strength and power", "display_order": 1},
		{"name": "Essence", "description": "Magical power and energy", "display_order": 2},
		{"name": "Agility", "description": "Physical agility and reflexes", "display_order": 3},
		{"name": "Resolution", "description": "Mental resilience and determination", "display_order": 4},
		{"name": "Intelligence", "description": "Reasoning and learning ability", "display_order": 5},
		{"name": "Stamina", "description": "Endurance and vitality", "display_order": 6}
	]
	
	for attr in attributes_data:
		var insert_query = """
		INSERT INTO attributes (name, base_value, max_value, display_order, description)
		VALUES ('%s', 0, 6, %d, '%s')
		""" % [attr.name, attr.display_order, attr.description]
		
		db.query(insert_query)
		if not is_query_successful():
			print("Error inserting attribute " + attr.name + ": " + db.error_message)
		else:
			print("Inserted attribute: ", attr.name)

func seed_abilities():
	# Check if we already have ability data
	var check_query = "SELECT COUNT(*) as count FROM abilities"
	db.query(check_query)
	var result = db.query_result
	
	print("Checking existing ability data - query result: ", result)
	if result.size() > 0:
		print("Found %d rows, count = %s" % [result.size(), str(result[0]["count"])])
		if result[0]["count"] > 0:
			print("Database already contains ability data")
			return
	
	print("No existing ability data found, seeding abilities...")
	
	# Insert the 12 abilities
	var abilities_data = [
		{"name": "Scoundrel", "description": "Sneaking, thievery, and cunning", "display_order": 1},
		{"name": "Warrior", "description": "One-handed weapon mastery", "display_order": 2},
		{"name": "Berserker", "description": "Two-handed weapon expertise", "display_order": 3},
		{"name": "Ranger", "description": "Bows, crossbows, and throwing weapons", "display_order": 4},
		{"name": "Juggernaut", "description": "Defensive and armor mastery", "display_order": 5},
		{"name": "Tactician", "description": "Battlefield strategy", "display_order": 6},
		{"name": "Pyromancer", "description": "Destructive fire spells and pyromancy", "display_order": 7},
		{"name": "Aeromancer", "description": "Destructive air spells and aeromancy", "display_order": 8},
		{"name": "Hydromancer", "description": "Destructive water spells and hydromancy", "display_order": 9},
		{"name": "Lithomancer", "description": "Destructive earth spells and lithomancy", "display_order": 10},
		{"name": "Arcanist", "description": "Pure magical energy manipulation", "display_order": 11},
		{"name": "Bloodmage", "description": "Dark magic using life force", "display_order": 12}
	]
	
	for ability in abilities_data:
		var insert_query = """
		INSERT INTO abilities (name, base_value, max_value, display_order, description)
		VALUES ('%s', 0, 6, %d, '%s')
		""" % [ability.name, ability.display_order, ability.description]
		
		db.query(insert_query)
		if not is_query_successful():
			print("Error inserting ability " + ability.name + ": " + db.error_message)
		else:
			print("Inserted ability: ", ability.name)

func get_all_attributes():
	var query = "SELECT * FROM attributes ORDER BY display_order"
	db.query(query)
	
	if is_query_successful():
		print("Successfully fetched %d attributes from database" % db.query_result.size())
		return db.query_result
	else:
		print("Error fetching attributes: ", db.error_message)
		return []

func get_attribute_by_name(attribute_name: String):
	var query = "SELECT * FROM attributes WHERE name = '%s'" % attribute_name
	db.query(query)
	var result = db.query_result
	
	if result.size() > 0:
		return result[0]
	else:
		return null

func get_all_abilities():
	var query = "SELECT * FROM abilities ORDER BY display_order"
	db.query(query)
	
	if is_query_successful():
		print("Successfully fetched %d abilities from database" % db.query_result.size())
		return db.query_result
	else:
		print("Error fetching abilities: ", db.error_message)
		return []

func get_ability_by_name(ability_name: String):
	var query = "SELECT * FROM abilities WHERE name = '%s'" % ability_name
	db.query(query)
	var result = db.query_result
	
	if result.size() > 0:
		return result[0]
	else:
		return null

func seed_traits():
	# Check if we already have trait data
	var check_query = "SELECT COUNT(*) as count FROM traits"
	db.query(check_query)
	var result = db.query_result
	
	if result.size() > 0 and result[0]["count"] > 0:
		print("Database already contains trait data")
		return
	
	print("No existing trait data found, seeding traits...")
	
	# Insert Polyvalent trait (Human)
	var query1 = "INSERT INTO traits (name, description, attribute_bonuses, ability_bonuses, skill_bonuses, other_bonuses, display_order) VALUES "
	query1 += "('Polyvalent', 'Humans are adaptable and versatile, gaining small bonuses to all areas of expertise', "
	query1 += "'[]', "
	query1 += "'[]', "
	query1 += "'[{\"name\": \"survival\", \"value\": 1}, {\"name\": \"perception\", \"value\": 1}, {\"name\": \"stealth\", \"value\": 1}, {\"name\": \"knowledge\", \"value\": 1}, {\"name\": \"arcana\", \"value\": 1}, {\"name\": \"sleight_of_hand\", \"value\": 1}, {\"name\": \"persuasion\", \"value\": 1}, {\"name\": \"athletics\", \"value\": 1}]', "
	query1 += "'[{\"type\": \"damage\", \"value\": 5}, {\"type\": \"endurance\", \"value\": 2}, {\"type\": \"pv\", \"value\": 10}, {\"type\": \"mana\", \"value\": 10}]', 1)"
	db.query(query1)
	if is_query_successful():
		print("Inserted trait: Polyvalent")
	else:
		print("Error inserting Polyvalent trait: " + db.error_message)
	
	# Insert Ancient Wisdom trait (Elfs)
	var query2 = "INSERT INTO traits (name, description, attribute_bonuses, ability_bonuses, skill_bonuses, other_bonuses, display_order) VALUES "
	query2 += "('Ancient Wisdom', 'Elfs possess centuries of accumulated knowledge and unshakeable mental fortitude', "
	query2 += "'[{\"name\": \"stamina\", \"value\": -1}, {\"name\": \"willpower\", \"value\": 1}]', "
	query2 += "'[]', "
	query2 += "'[{\"name\": \"knowledge\", \"value\": 2}', "
	query2 += "'[{\"type\": \"resistance\", \"value\": 10, \"subtype\": \"magical\"}]', 2)"
	db.query(query2)
	if is_query_successful():
		print("Inserted trait: Ancient Wisdom")
	else:
		print("Error inserting Ancient Wisdom trait: " + db.error_message)
	
	# Insert Divine Heritage trait (Celestial-blooded)
	var query3 = "INSERT INTO traits (name, description, attribute_bonuses, ability_bonuses, skill_bonuses, other_bonuses, display_order) VALUES "
	query3 += "('Divine Heritage', 'Celestial-blooded carry divine blessings, excelling in protection and social grace', "
	query3 += "'[{\"name\": \"essence\", \"value\": 1}]', "
	query3 += "'[]', "
	query3 += "'[]', "
	query3 += "'[{\"type\": \"resistance\", \"value\": 15, \"subtype\": \"magical\"}, {\"type\": \"resistance\", \"value\": 5, \"subtype\": \"physical\"}]', 3)"
	db.query(query3)
	if is_query_successful():
		print("Inserted trait: Divine Heritage")
	else:
		print("Error inserting Divine Heritage trait: " + db.error_message)
	
	# Insert Infernal Power trait (Infernal-blooded)
	var query4 = "INSERT INTO traits (name, description, attribute_bonuses, ability_bonuses, skill_bonuses, other_bonuses, display_order) VALUES "
	query4 += "('Infernal Power', 'Infernal-blooded channel raw dark power, devastating in combat but consuming', "
	query4 += "'[{\"name\": \"essence\", \"value\": 1}]', "
	query4 += "'[]', "
	query4 += "'[]', "
	query4 += "'[{\"type\": \"resistance\", \"value\": 20, \"subtype\": \"fire\"}]', 4)"
	db.query(query4)
	if is_query_successful():
		print("Inserted trait: Infernal Power")
	else:
		print("Error inserting Infernal Power trait: " + db.error_message)

func seed_races():
	# Check if we already have race data
	var check_query = "SELECT COUNT(*) as count FROM races"
	db.query(check_query)
	var result = db.query_result
	
	if result.size() > 0 and result[0]["count"] > 0:
		print("Database already contains race data")
		return
	
	print("No existing race data found, seeding races...")
	
	# Insert the 4 races with their corresponding trait IDs
	var races_data = [
		{"name": "Human", "description": "The most adaptable and common race", "display_order": 1, "trait_id": 1},
		{"name": "Elf", "description": "Ancient and wise beings with extended lifespans", "display_order": 2, "trait_id": 2},
		{"name": "Celestial-blooded", "description": "Descendants of celestial beings with divine heritage", "display_order": 3, "trait_id": 3},
		{"name": "Infernal-blooded", "description": "Descendants of infernal beings with dark heritage", "display_order": 4, "trait_id": 4}
	]
	
	for race_data in races_data:
		var insert_query = """
		INSERT INTO races (name, trait_id, display_order, description)
		VALUES ('%s', %d, %d, '%s')
		""" % [race_data.name, race_data.trait_id, race_data.display_order, race_data.description]
		
		db.query(insert_query)
		if not is_query_successful():
			print("Error inserting race " + race_data.name + ": " + db.error_message)
		else:
			print("Inserted race: ", race_data.name)

func get_all_races():
	var query = """
	SELECT r.*, t.name as trait_name, t.description as trait_description, 
		   t.attribute_bonuses, t.ability_bonuses, t.skill_bonuses, t.other_bonuses
	FROM races r
	LEFT JOIN traits t ON r.trait_id = t.id
	ORDER BY r.display_order
	"""
	db.query(query)
	
	if is_query_successful():
		print("Successfully fetched %d races from database" % db.query_result.size())
		return db.query_result
	else:
		print("Error fetching races: ", db.error_message)
		return []

func get_race_by_name(race_name: String):
	var query = "SELECT * FROM races WHERE name = '%s'" % race_name
	db.query(query)
	var result = db.query_result
	
	if result.size() > 0:
		return result[0]
	else:
		return null

func seed_skills():
	# Check if we already have skill data
	var check_query = "SELECT COUNT(*) as count FROM skills"
	db.query(check_query)
	var result = db.query_result
	
	if result.size() > 0 and result[0]["count"] > 0:
		print("Database already contains skill data")
		return
	
	print("No existing skill data found, seeding skills...")
	
	# Insert the 8 skills as specified
	var skills_data = [
		{"name": "Survival", "description": "Ability to survive in the wilderness", "display_order": 1},
		{"name": "Perception", "description": "Awareness and ability to notice details", "display_order": 2},
		{"name": "Stealth", "description": "Ability to move silently and remain hidden", "display_order": 3},
		{"name": "Knowledge", "description": "General learning and intellectual capacity", "display_order": 4},
		{"name": "Arcana", "description": "Understanding of magical theory and practice", "display_order": 5},
		{"name": "Sleight of Hand", "description": "Dexterity and manual skill for precise tasks", "display_order": 6},
		{"name": "Persuasion", "description": "Ability to influence and convince others", "display_order": 7},
		{"name": "Athletics", "description": "Physical prowess and bodily coordination", "display_order": 8}
	]
	
	for skill in skills_data:
		var insert_query = """
		INSERT INTO skills (name, base_value, max_value, display_order, description)
		VALUES ('%s', 0, 6, %d, '%s')
		""" % [skill.name, skill.display_order, skill.description]
		
		db.query(insert_query)
		if not is_query_successful():
			print("Error inserting skill " + skill.name + ": " + db.error_message)
		else:
			print("Inserted skill: ", skill.name)

func get_all_skills():
	var query = "SELECT * FROM skills ORDER BY display_order"
	db.query(query)
	
	if is_query_successful():
		print("Successfully fetched %d skills from database" % db.query_result.size())
		return db.query_result
	else:
		print("Error fetching skills: ", db.error_message)
		return []

func get_skill_by_name(skill_name: String):
	var query = "SELECT * FROM skills WHERE name = '%s'" % skill_name
	db.query(query)
	var result = db.query_result
	
	if result.size() > 0:
		return result[0]
	else:
		return null

func get_all_traits():
	var query = "SELECT * FROM traits ORDER BY display_order"
	db.query(query)
	
	if is_query_successful():
		print("Successfully fetched %d traits from database" % db.query_result.size())
		return db.query_result
	else:
		print("Error fetching traits: ", db.error_message)
		return []

func get_trait_by_id(trait_id: int):
	var query = "SELECT * FROM traits WHERE id = %d" % trait_id
	db.query(query)
	var result = db.query_result
	
	if result.size() > 0:
		return result[0]
	else:
		return null

func get_trait_by_name(trait_name: String):
	var query = "SELECT * FROM traits WHERE name = '%s'" % trait_name
	db.query(query)
	var result = db.query_result
	
	if result.size() > 0:
		return result[0]
	else:
		return null

func seed_ref_maps():
	# Check if we already have ref_map data
	var check_query = "SELECT COUNT(*) as count FROM ref_map"
	db.query(check_query)
	var result = db.query_result
	
	if result.size() > 0 and result[0]["count"] > 0:
		print("Database already contains ref_map data")
		return
	
	print("No existing ref_map data found, seeding ref_maps...")
	
	# Insert default map references
	var maps_data = [
		{"name": "Simple Map Test", "width": 9, "height": 9, "description": "A diverse world with forests, mountains, arid lands, and varied terrain in a 9x9 grid"},
		{"name": "Tutorial Forest", "width": 20, "height": 15, "description": "A small forest area perfect for learning the basics"},
		{"name": "Ancient Ruins", "width": 30, "height": 25, "description": "Mysterious ruins filled with secrets and danger"},
		{"name": "Crystal Caves", "width": 25, "height": 20, "description": "Underground caverns with magical crystal formations"}
	]
	
	for map_data in maps_data:
		var insert_query = """
		INSERT INTO ref_map (name, width, height, description)
		VALUES ('%s', %d, %d, '%s')
		""" % [map_data.name, map_data.width, map_data.height, map_data.description]
		
		db.query(insert_query)
		if not is_query_successful():
			print("Error inserting ref_map " + map_data.name + ": " + db.error_message)
		else:
			print("Inserted ref_map: ", map_data.name)

func seed_ref_tiles():
	# Check if we already have ref_tile data
	var check_query = "SELECT COUNT(*) as count FROM ref_tile"
	db.query(check_query)
	var result = db.query_result
	
	if result.size() > 0 and result[0]["count"] > 0:
		print("Database already contains ref_tile data")
		return
	
	print("No existing ref_tile data found, seeding ref_tiles...")
	
	# Insert default tile types using constants for paths and values
	var tiles_data = [
		{"type_name": "forest", "is_walkable": true, "color_hex": "#2D5016", "movement_cost": HexTileConstants.DEFAULT_MOVEMENT_COST, "texture_path": HexTileConstants.get_texture_path("forest"), "description": "Dense forest with trees"},
		{"type_name": "mountain", "is_walkable": false, "color_hex": "#8B8680", "movement_cost": HexTileConstants.IMPASSABLE_MOVEMENT_COST, "texture_path": HexTileConstants.get_texture_path("mountain"), "description": "Tall impassable mountains"},
		{"type_name": "green_mountain", "is_walkable": false, "color_hex": "#6B8E5A", "movement_cost": HexTileConstants.IMPASSABLE_MOVEMENT_COST, "texture_path": HexTileConstants.get_texture_path("green_mountain"), "description": "Forested mountains"},
		{"type_name": "grassland", "is_walkable": true, "color_hex": "#7CB342", "movement_cost": HexTileConstants.DEFAULT_MOVEMENT_COST, "texture_path": HexTileConstants.get_texture_path("grassland"), "description": "Open grassland plains"},
		{"type_name": "empty_green", "is_walkable": true, "color_hex": "#8BC34A", "movement_cost": HexTileConstants.DEFAULT_MOVEMENT_COST, "texture_path": HexTileConstants.get_texture_path("empty_green"), "description": "Empty green fields"},
		{"type_name": "arid_varap", "is_walkable": true, "color_hex": "#D4A574", "movement_cost": 2, "texture_path": HexTileConstants.get_texture_path("arid_varap"), "description": "Arid wasteland with sparse vegetation"},
		{"type_name": "glade", "is_walkable": true, "color_hex": "#4CAF50", "movement_cost": HexTileConstants.DEFAULT_MOVEMENT_COST, "texture_path": HexTileConstants.get_texture_path("glade"), "description": "Peaceful forest glade"},
		{"type_name": "cliff", "is_walkable": false, "color_hex": "#795548", "movement_cost": HexTileConstants.IMPASSABLE_MOVEMENT_COST, "texture_path": HexTileConstants.get_texture_path("cliff"), "description": "Steep rocky cliffs"},
	]
	
	for tile_data in tiles_data:
		var insert_query = """
		INSERT INTO ref_tile (type_name, is_walkable, color_hex, movement_cost, texture_path, tileset_x, tileset_y, tile_size, description)
		VALUES ('%s', %s, '%s', %d, '%s', %d, %d, %d, '%s')
		""" % [tile_data.type_name, str(tile_data.is_walkable).to_lower(), tile_data.color_hex, tile_data.movement_cost, tile_data.texture_path, 0, 0, HexTileConstants.DEFAULT_TILE_SIZE_DB, tile_data.description]
		
		db.query(insert_query)
		if not is_query_successful():
			print("Error inserting ref_tile " + tile_data.type_name + ": " + db.error_message)
		else:
			print("Inserted ref_tile: ", tile_data.type_name)

func seed_ref_map_tiles():
	# Check if we already have ref_map_tile data
	var check_query = "SELECT COUNT(*) as count FROM ref_map_tile"
	db.query(check_query)
	var result = db.query_result
	
	if result.size() > 0 and result[0]["count"] > 0:
		print("Database already contains ref_map_tile data")
		return
	
	print("No existing ref_map_tile data found, seeding ref_map_tiles...")
	
	# Get the Simple Map Test map ID
	var map_query = "SELECT id FROM ref_map WHERE name = 'Simple Map Test'"
	db.query(map_query)
	if not is_query_successful() or db.query_result.size() == 0:
		print("Error: Simple Map Test map not found")
		return
	
	var forest_map_id = db.query_result[0]["id"]
	print("Found ref_map_id: " + str(forest_map_id) + " for map: Simple Map Test")
	
	# Get all tile IDs we'll need for the 9x9 map
	var tile_ids = {}
	var tile_types = ["forest", "mountain", "green_mountain", "grassland", "empty_green", "arid_varap", "glade", "cliff"]
	
	for tile_type in tile_types:
		var tile_query = "SELECT id FROM ref_tile WHERE type_name = '%s'" % tile_type
		db.query(tile_query)
		if not is_query_successful() or db.query_result.size() == 0:
			print("Error: %s tile not found" % tile_type)
			return
		tile_ids[tile_type] = db.query_result[0]["id"]
		print("Found tile ID %d for %s" % [tile_ids[tile_type], tile_type])
	
	# Define the 9x9 coherent terrain layout
	# F=forest, M=mountain, G=grassland, E=empty_green, A=arid_varap, V=glade, C=cliff, N=green_mountain
	var terrain_map = [
		["G", "G", "E", "E", "F", "F", "F", "G", "G"],  # Row 0
		["G", "E", "E", "F", "F", "F", "G", "G", "G"],  # Row 1  
		["E", "E", "F", "F", "V", "G", "G", "C", "C"],  # Row 2
		["F", "F", "F", "V", "A", "A", "A", "C", "M"],  # Row 3
		["F", "V", "G", "G", "A", "A", "A", "M", "M"],  # Row 4
		["F", "G", "G", "A", "A", "V", "V", "N", "G"],  # Row 5
		["G", "G", "G", "A", "V", "V", "G", "G", "G"],  # Row 6
		["G", "G", "G", "G", "G", "G", "G", "G", "G"],  # Row 7
		["G", "G", "G", "G", "G", "G", "G", "G", "G"]   # Row 8
	]
	
	# Tile type mapping
	var tile_mapping = {
		"F": "forest",
		"M": "mountain", 
		"N": "green_mountain",
		"G": "grassland",
		"E": "empty_green",
		"A": "arid_varap",
		"V": "glade",
		"C": "cliff"
	}
	
	# Create the 9x9 map with coherent terrain
	for y in range(9):
		for x in range(9):
			var terrain_code = terrain_map[y][x]
			var tile_type = tile_mapping[terrain_code]
			var tile_id = tile_ids[tile_type]
			
			var insert_query = """
			INSERT INTO ref_map_tile (ref_map_id, ref_tile_id, x, y)
			VALUES (%d, %d, %d, %d)
			""" % [forest_map_id, tile_id, x, y]
			
			db.query(insert_query)
			if not is_query_successful():
				print("Error creating ref_map_tile at (%d, %d): %s" % [x, y, db.error_message])
			else:
				print("Placed %s tile at (%d, %d)" % [tile_type, x, y])
	
	print("Created ref_map_tile entries for Simple Map Test map (9x9 grid)")
	print("Map features:")
	print("- Forest cluster in northwest")
	print("- Mountain range in northeast (fewer mountains)")
	print("- Arid wasteland in center-east")
	print("- Peaceful glades as transitions")
	print("- Rocky cliffs near mountains")
	print("- Grassland plains as base terrain")
	print("- Empty green fields as transitional areas")

# Map and Tile database functions
func get_all_ref_maps():
	var query = "SELECT * FROM ref_map ORDER BY name"
	db.query(query)
	
	if is_query_successful():
		print("Successfully fetched %d ref_maps from database" % db.query_result.size())
		return db.query_result
	else:
		print("Error fetching ref_maps: ", db.error_message)
		return []

func get_all_ref_tiles():
	var query = "SELECT * FROM ref_tile ORDER BY type_name"
	db.query(query)
	
	if is_query_successful():
		print("Successfully fetched %d ref_tiles from database" % db.query_result.size())
		return db.query_result
	else:
		print("Error fetching ref_tiles: ", db.error_message)
		return []

# Create a new game by copying ref_map_tile to map_tile
func create_new_game(ref_map_name: String, game_id: int = HexTileConstants.DEFAULT_GAME_ID) -> bool:
	print("Creating new game with map: %s for game_id: %d" % [ref_map_name, game_id])
	
	# Get the ref_map ID
	var map_query = "SELECT id FROM ref_map WHERE name = '%s'" % ref_map_name
	db.query(map_query)
	if not is_query_successful() or db.query_result.size() == 0:
		print("Error: Ref_map '" + ref_map_name + "' not found")
		return false
	
	var ref_map_id = db.query_result[0]["id"]
	print("Found ref_map_id: " + str(ref_map_id) + " for map: " + ref_map_name)
	
	# Check how many tiles are in ref_map_tile for this map
	var count_query = "SELECT COUNT(*) as count FROM ref_map_tile WHERE ref_map_id = %d" % ref_map_id
	db.query(count_query)
	var ref_tile_count = 0
	if is_query_successful() and db.query_result.size() > 0:
		ref_tile_count = db.query_result[0]["count"]
	print("Found %d tiles in ref_map_tile for this map" % ref_tile_count)
	
	# Clear any existing map_tile data for this game
	var clear_query = "DELETE FROM map_tile WHERE game_id = %d" % game_id
	db.query(clear_query)
	if is_query_successful():
		print("Cleared existing map_tile data for game_id: %d" % game_id)
	
	# Copy ref_map_tile to map_tile for this game
	var copy_query = """
	INSERT INTO map_tile (game_id, ref_map_id, ref_tile_id, x, y)
	SELECT %d, ref_map_id, ref_tile_id, x, y
	FROM ref_map_tile
	WHERE ref_map_id = %d
	""" % [game_id, ref_map_id]
	
	print("Executing copy query: %s" % copy_query)
	db.query(copy_query)
	if not is_query_successful():
		print("Error copying ref_map_tile to map_tile: ", db.error_message)
		return false
	
	# Verify the copy worked
	var verify_query = "SELECT COUNT(*) as count FROM map_tile WHERE game_id = %d" % game_id
	db.query(verify_query)
	var copied_count = 0
	if is_query_successful() and db.query_result.size() > 0:
		copied_count = db.query_result[0]["count"]
	
	print("Successfully copied %d tiles from ref_map_tile to map_tile for game_id: %d" % [copied_count, game_id])
	return true

func get_current_map_info(game_id: int = 1):
	var query = """
	SELECT rm.*, COUNT(mt.id) as tile_count
	FROM ref_map rm
	JOIN map_tile mt ON rm.id = mt.ref_map_id
	WHERE mt.game_id = %d
	GROUP BY rm.id
	LIMIT 1
	""" % game_id
	
	db.query(query)
	
	if is_query_successful() and db.query_result.size() > 0:
		return db.query_result[0]
	else:
		print("No current map found for game_id: ", game_id)
		return null

func get_game_map_tiles(game_id: int = 1):
	var query = """
	SELECT mt.*, rt.type_name, rt.is_walkable, rt.color_hex, rt.movement_cost, rt.texture_path, rt.tileset_x, rt.tileset_y, rt.tile_size, rt.description
	FROM map_tile mt
	JOIN ref_tile rt ON mt.ref_tile_id = rt.id
	WHERE mt.game_id = %d
	ORDER BY mt.y, mt.x
	""" % game_id
	
	db.query(query)
	
	if is_query_successful():
		return db.query_result
	else:
		print("Error fetching game map tiles: ", db.error_message)
		return []

func close_database():
	if db:
		db.close_db()

# Update existing tile texture paths to use new tilev2 files
func update_tile_texture_paths() -> bool:
	print("Updating tile texture paths to new tilev2 files...")
	
	var updates = [
		{"type_name": "forest", "new_path": "res://assets/tiles/tilev2_forest.png"},
		{"type_name": "mountain", "new_path": "res://assets/tiles/tilev2_mountain.png"},
		{"type_name": "mountain_forest", "new_path": "res://assets/tiles/tilev2_mountain_forest.png"}
	]
	
	var success = true
	for update in updates:
		var update_query = """
		UPDATE ref_tile 
		SET texture_path = '%s'
		WHERE type_name = '%s'
		""" % [update.new_path, update.type_name]
		
		db.query(update_query)
		if is_query_successful():
			print("Updated texture path for %s to %s" % [update.type_name, update.new_path])
		else:
			print("Error updating texture path for " + update.type_name + ": " + db.error_message)
			success = false
	
	# Also fix the typo if it exists
	var fix_typo_query = """
	UPDATE ref_tile 
	SET type_name = 'mountain_forest'
	WHERE type_name = 'moutain_forest'
	"""
	
	db.query(fix_typo_query)
	if is_query_successful():
		print("Fixed mountain_forest typo if it existed")
	
	return success

# Create a simple forest test map for immediate testing
 

func save_character(character_name: String, race_name: String, sex: String, attributes: Dictionary, abilities: Dictionary, skills: Dictionary) -> int:
	"""Save a character to the database and return the character ID"""
	print("Saving character: " + character_name)
	
	# Get race ID from race name
	var race = get_race_by_name(race_name)
	if not race:
		print("Error: Race not found: " + race_name)
		return -1
	
	var race_id = race.id
	
	# Convert dictionaries to JSON strings
	var attributes_json = JSON.stringify(attributes)
	var abilities_json = JSON.stringify(abilities)
	var skills_json = JSON.stringify(skills)
	
	# Insert character into database
	var insert_query = """
	INSERT INTO character (name, race_id, sex, attributes, abilities, skills)
	VALUES ('%s', %d, '%s', '%s', '%s', '%s')
	""" % [character_name, race_id, sex, attributes_json, abilities_json, skills_json]
	
	db.query(insert_query)
	if not is_query_successful():
		print("Error saving character: " + db.error_message)
		return -1
	
	# Get the ID of the newly created character
	var id_query = "SELECT last_insert_rowid() as id"
	db.query(id_query)
	if is_query_successful() and db.query_result.size() > 0:
		var character_id = db.query_result[0].id
		print("Character saved successfully with ID: " + str(character_id))
		return character_id
	else:
		print("Error retrieving character ID")
		return -1

func get_character_by_id(character_id: int) -> Dictionary:
	"""Retrieve a character by ID with race information"""
	var query = """
	SELECT c.*, r.name as race_name, r.description as race_description
	FROM character c
	LEFT JOIN races r ON c.race_id = r.id
	WHERE c.id = %d
	""" % character_id
	
	db.query(query)
	if is_query_successful() and db.query_result.size() > 0:
		var character_data = db.query_result[0]
		
		# Parse JSON strings back to dictionaries
		var json = JSON.new()
		
		if character_data.attributes:
			json.parse(character_data.attributes)
			character_data.attributes_dict = json.data
		
		if character_data.abilities:
			json.parse(character_data.abilities)
			character_data.abilities_dict = json.data
		
		if character_data.skills:
			json.parse(character_data.skills)
			character_data.skills_dict = json.data
		
		return character_data
	else:
		print("Character not found with ID: " + str(character_id))
		return {}

func get_all_characters() -> Array:
	"""Get all characters with their race information"""
	var query = """
	SELECT c.id, c.name, c.created_at, r.name as race_name
	FROM character c
	LEFT JOIN races r ON c.race_id = r.id
	ORDER BY c.created_at DESC
	"""
	
	db.query(query)
	if is_query_successful():
		print("Successfully fetched %d characters from database" % db.query_result.size())
		return db.query_result
	else:
		print("Error fetching characters: ", db.error_message)
		return []

func delete_character(character_id: int) -> bool:
	"""Delete a character by ID"""
	var delete_query = "DELETE FROM character WHERE id = %d" % character_id
	db.query(delete_query)
	
	if is_query_successful():
		print("Character deleted successfully")
		return true
	else:
		print("Error deleting character: " + db.error_message)
		return false
