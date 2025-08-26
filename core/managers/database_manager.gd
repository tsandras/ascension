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
		attribute_bonuses JSON,
		ability_bonuses JSON,
		skill_bonuses JSON,
		other_bonuses JSON,
		display_order INTEGER NOT NULL DEFAULT 0
	);
	"""
	
	db.query(traits_query)
	if not is_query_successful():
		print("Error creating traits table: ", db.error_message)
	else:
		print("Traits table created successfully")
	
	# Create competences table
	var competences_query = """
	CREATE TABLE IF NOT EXISTS competences (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		base_value INTEGER NOT NULL DEFAULT 0,
		max_value INTEGER NOT NULL DEFAULT 6,
		display_order INTEGER NOT NULL DEFAULT 0,
		description TEXT
	);
	"""
	
	db.query(competences_query)
	if not is_query_successful():
		print("Error creating competences table: ", db.error_message)
	else:
		print("Competences table created successfully")
	
	# Create nodes table for skill trees
	var nodes_query = """
	CREATE TABLE IF NOT EXISTS nodes (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		description TEXT,
		node_type TEXT NOT NULL DEFAULT 'PASSIVE',
		trait_id INTEGER,
		skill_id INTEGER,
		attribute_bonuses JSON,
		FOREIGN KEY (trait_id) REFERENCES traits(id),
		FOREIGN KEY (skill_id) REFERENCES abilities(id)
	);
	"""
	
	db.query(nodes_query)
	if not is_query_successful():
		print("Error creating nodes table: ", db.error_message)
	else:
		print("Nodes table created successfully")
	
	# Create skill_tree table
	var skill_tree_query = """
	CREATE TABLE IF NOT EXISTS skill_tree (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		description TEXT,
		data JSON NOT NULL,
		parents TEXT
	);
	"""
	
	db.query(skill_tree_query)
	if not is_query_successful():
		print("Error creating skill_tree table: ", db.error_message)
	else:
		print("Skill_tree table created successfully")
	
	# Create character table for persistent character creation
	var character_query = """
	CREATE TABLE IF NOT EXISTS character (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL,
		race_id INTEGER,
		sex TEXT NOT NULL,
		portrait TEXT,
		avatar TEXT,
		attributes JSON,
		abilities JSON,
		competences JSON,
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
		starting_tileset_x INTEGER NOT NULL,
		starting_tileset_y INTEGER NOT NULL,
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
		initials TEXT NOT NULL UNIQUE,
		is_walkable BOOLEAN NOT NULL DEFAULT 1,
		is_top_blocked BOOLEAN NOT NULL DEFAULT 0,
		is_bottom_blocked BOOLEAN NOT NULL DEFAULT 0,
		is_middle_blocked BOOLEAN NOT NULL DEFAULT 0,
		texture_path TEXT,
		time_to_cross INTEGER DEFAULT 1,
		tileset_x INTEGER DEFAULT 0,
		tileset_y INTEGER DEFAULT 0,
		description TEXT,
		extra_content JSON
	);
	"""
	
	db.query(ref_tile_query)
	if not is_query_successful():
		print("Error creating ref_tile table: ", db.error_message)
	else:
		print("Ref_tile table created successfully")
	
	# Create ref_overlay table (template overlays)
	var ref_overlay_query = """
	CREATE TABLE IF NOT EXISTS ref_overlay (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		initials TEXT NOT NULL UNIQUE,
		texture_path TEXT NOT NULL,
		description TEXT,
		display_order INTEGER NOT NULL DEFAULT 0,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	"""
	
	db.query(ref_overlay_query)
	if not is_query_successful():
		print("Error creating ref_overlay table: ", db.error_message)
	else:
		print("Ref_overlay table created successfully")
	
	# Create ref_map_tile table (template tile layouts)
	var ref_map_tile_query = """
	CREATE TABLE IF NOT EXISTS ref_map_tile (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		ref_map_id INTEGER NOT NULL,
		ref_tile_id INTEGER NOT NULL,
		x INTEGER NOT NULL,
		y INTEGER NOT NULL,
		first_overlay_id INTEGER,
		second_overlay_id INTEGER,
		first_overlay_x REAL DEFAULT 0.5,
		first_overlay_y REAL DEFAULT 0.5,
		second_overlay_x REAL DEFAULT 0.5,
		second_overlay_y REAL DEFAULT 0.5,
		FOREIGN KEY (ref_map_id) REFERENCES ref_map(id),
		FOREIGN KEY (ref_tile_id) REFERENCES ref_tile(id),
		FOREIGN KEY (first_overlay_id) REFERENCES ref_overlay(id),
		FOREIGN KEY (second_overlay_id) REFERENCES ref_overlay(id),
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
		first_overlay_id INTEGER,
		second_overlay_id INTEGER,
		first_overlay_x REAL DEFAULT 0.5,
		first_overlay_y REAL DEFAULT 0.5,
		second_overlay_x REAL DEFAULT 0.5,
		second_overlay_y REAL DEFAULT 0.5,
		is_occupied BOOLEAN DEFAULT 0,
		character_visited BOOLEAN DEFAULT 0,
		visit_count INTEGER DEFAULT 0,
		entity_id INTEGER,
		last_visited DATETIME,
		FOREIGN KEY (ref_map_id) REFERENCES ref_map(id),
		FOREIGN KEY (ref_tile_id) REFERENCES ref_tile(id),
		FOREIGN KEY (first_overlay_id) REFERENCES ref_overlay(id),
		FOREIGN KEY (second_overlay_id) REFERENCES ref_overlay(id),
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
	seed_traits()       # Seed traits before races (foreign key dependency)
	seed_races()
	seed_competences()
	seed_nodes()        # Seed sample nodes for skill trees


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
	
	# Define traits data as GDScript objects
	var traits_data = [
		{
			"name": "Polyvalent",
			"description": "Humans are adaptable and versatile, gaining small bonuses to all areas of expertise",
			"attribute_bonuses": [],
			"ability_bonuses": [],
			"competence_bonuses": [
				{"name": "free", "value": 1}
			],
			"other_bonuses": [
				{"type": "critical_chance", "value": 5},
			],
			"display_order": 1
		},
		{
			"name": "Ancient Wisdom",
			"description": "Elfs possess centuries of accumulated knowledge and unshakeable mental fortitude",
			"attribute_bonuses": [
				{"name": "stamina", "value": -1},
				{"name": "willpower", "value": 1}
			],
			"ability_bonuses": [],
			"competence_bonuses": [
				{"name": "knowledge", "value": 2}
			],
			"other_bonuses": [
				{"type": "resistance", "value": 5, "subtype": "magical"}
			],
			"display_order": 2
		},
		{
			"name": "Divine Heritage",
			"description": "Celestial-blooded carry divine blessings, excelling in protection and social grace",
			"attribute_bonuses": [
				{"name": "essence", "value": 1}
			],
			"ability_bonuses": [],
			"competence_bonuses": [],
			"other_bonuses": [
				{"type": "resistance", "value": 15, "subtype": "fire"},
				{"type": "resistance", "value": 15, "subtype": "lightning"}
			],
			"display_order": 3
		},
		{
			"name": "Infernal Power",
			"description": "Infernal-blooded channel raw dark power, devastating in combat but consuming",
			"attribute_bonuses": [
				{"name": "essence", "value": 1}
			],
			"ability_bonuses": [],
			"competence_bonuses": [],
			"other_bonuses": [
				{"type": "resistance", "value": 15, "subtype": "fire"},
				{"type": "resistance", "value": 15, "subtype": "cold"}
			],
			"display_order": 4
		}
	]
	
	# Insert each trait
	for trait_data in traits_data:
		var insert_query = """
		INSERT INTO traits (name, description, attribute_bonuses, ability_bonuses, skill_bonuses, other_bonuses, display_order)
		VALUES ('%s', '%s', '%s', '%s', '%s', '%s', %d)
		""" % [
			trait_data.name,
			trait_data.description,
			JSON.stringify(trait_data.attribute_bonuses),
			JSON.stringify(trait_data.ability_bonuses),
			JSON.stringify(trait_data.competence_bonuses),
			JSON.stringify(trait_data.other_bonuses),
			trait_data.display_order
		]
		
		db.query(insert_query)
		if is_query_successful():
			print("Inserted trait: " + trait_data.name)
		else:
			print("Error inserting " + trait_data.name + " trait: " + db.error_message)

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

func seed_competences():
	# Check if we already have competence data
	var check_query = "SELECT COUNT(*) as count FROM competences"
	db.query(check_query)
	var result = db.query_result
	
	if result.size() > 0 and result[0]["count"] > 0:
		print("Database already contains competence data")
		return
	
	print("No existing competence data found, seeding competences...")
	
	# Insert the 8 competences as specified
	var competences_data = [
		{"name": "Survival", "description": "Ability to survive in the wilderness", "display_order": 1},
		{"name": "Perception", "description": "Awareness and ability to notice details", "display_order": 2},
		{"name": "Stealth", "description": "Ability to move silently and remain hidden", "display_order": 3},
		{"name": "Knowledge", "description": "General learning and intellectual capacity", "display_order": 4},
		{"name": "Arcana", "description": "Understanding of magical theory and practice", "display_order": 5},
		{"name": "Sleight of Hand", "description": "Dexterity and manual skill for precise tasks", "display_order": 6},
		{"name": "Persuasion", "description": "Ability to influence and convince others", "display_order": 7},
		{"name": "Athletics", "description": "Physical prowess and bodily coordination", "display_order": 8}
	]
	
	for competence in competences_data:
		var insert_query = """
		INSERT INTO competences (name, base_value, max_value, display_order, description)
		VALUES ('%s', 0, 6, %d, '%s')
		""" % [competence.name, competence.display_order, competence.description]
		
		db.query(insert_query)
		if not is_query_successful():
			print("Error inserting competence " + competence.name + ": " + db.error_message)
		else:
			print("Inserted competence: ", competence.name)





func get_all_competences():
	var query = "SELECT * FROM competences ORDER BY display_order"
	db.query(query)
	
	if is_query_successful():
		print("Successfully fetched %d competences from database" % db.query_result.size())
		return db.query_result
	else:
		print("Error fetching competences: ", db.error_message)
		return []

func get_competence_by_name(competence_name: String):
	var query = "SELECT * FROM competences WHERE name = '%s'" % competence_name
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

func get_all_overlays():
	var query = "SELECT * FROM ref_overlay ORDER BY display_order, name"
	db.query(query)
	
	if is_query_successful():
		print("Successfully fetched %d overlays from database" % db.query_result.size())
		return db.query_result
	else:
		print("Error fetching overlays: ", db.error_message)
		return []

func get_overlay_by_name(overlay_name: String):
	var query = "SELECT * FROM ref_overlay WHERE name = '%s'" % overlay_name
	db.query(query)
	var result = db.query_result
	
	if result.size() > 0:
		return result[0]
	else:
		return null

func get_overlay_by_id(overlay_id: int):
	var query = "SELECT * FROM ref_overlay WHERE id = %d" % overlay_id
	db.query(query)
	var result = db.query_result
	
	if result.size() > 0:
		return result[0]
	else:
		return null

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
	INSERT INTO map_tile (game_id, ref_map_id, ref_tile_id, x, y, first_overlay_id, second_overlay_id, first_overlay_x, first_overlay_y, second_overlay_x, second_overlay_y)
	SELECT %d, ref_map_id, ref_tile_id, x, y, first_overlay_id, second_overlay_id, first_overlay_x, first_overlay_y, second_overlay_x, second_overlay_y
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
	SELECT mt.*, rt.type_name, rt.initials, rt.is_walkable, rt.is_top_blocked, rt.is_bottom_blocked, rt.is_middle_blocked, rt.texture_path, rt.time_to_cross, rt.tileset_x, rt.tileset_y, rt.description, rt.extra_content,
		   mt.first_overlay_id, mt.second_overlay_id, mt.first_overlay_x, mt.first_overlay_y, mt.second_overlay_x, mt.second_overlay_y
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


func save_character(character_name: String, race_name: String, sex: String, portrait: String, avatar: String, attributes: Dictionary, abilities: Dictionary, competences: Dictionary) -> int:
	"""Save a character to the database and return the character ID"""
	print("Saving character: " + character_name)
	
	# Get race ID from race name
	var race = get_race_by_name(race_name)
	if not race:
		print("Error: Race not found: " + race_name)
		return -1
	
	var race_id = race.id
	
	# Convert dictionaries to JSON strings for SQLite JSON columns
	var attributes_json = JSON.stringify(attributes)
	var abilities_json = JSON.stringify(abilities)
	var competences_json = JSON.stringify(competences)
	
	# Insert character into database
	var insert_query = """
	INSERT INTO character (name, race_id, sex, portrait, avatar, attributes, abilities, competences)
	VALUES ('%s', %d, '%s', '%s', '%s', '%s', '%s', '%s')
	""" % [character_name, race_id, sex, portrait, avatar, attributes_json, abilities_json, competences_json]
	
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
		
		# Parse JSON strings into objects
		if character_data.attributes:
			var json = JSON.new()
			if json.parse(character_data.attributes) == OK:
				character_data.attributes_dict = json.data
			else:
				character_data.attributes_dict = {}
		
		if character_data.abilities:
			var json = JSON.new()
			if json.parse(character_data.abilities) == OK:
				character_data.abilities_dict = json.data
			else:
				character_data.abilities_dict = {}
		
		if character_data.competences:
			var json = JSON.new()
			if json.parse(character_data.competences) == OK:
				character_data.competences_dict = json.data
			else:
				character_data.competences_dict = {}
		
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

func get_last_saved_character() -> Dictionary:
	"""Get the most recently saved character"""
	var query = """
	SELECT c.*, r.name as race_name, r.description as race_description
	FROM character c
	LEFT JOIN races r ON c.race_id = r.id
	ORDER BY c.created_at DESC
	LIMIT 1
	"""
	
	db.query(query)
	if is_query_successful() and db.query_result.size() > 0:
		var character_data = db.query_result[0]
		
		# Parse JSON strings into objects
		if character_data.attributes:
			var json = JSON.new()
			if json.parse(character_data.attributes) == OK:
				character_data.attributes_dict = json.data
			else:
				character_data.attributes_dict = {}
		
		if character_data.abilities:
			var json = JSON.new()
			if json.parse(character_data.abilities) == OK:
				character_data.abilities_dict = json.data
			else:
				character_data.abilities_dict = {}
		
		if character_data.competences:
			var json = JSON.new()
			if json.parse(character_data.competences) == OK:
				character_data.competences_dict = json.data
			else:
				character_data.competences_dict = {}
		
		print("Found last saved character: " + character_data.name)
		return character_data
	else:
		print("No saved characters found")
		return {}

# Node management methods for skill trees
func save_node(name: String, description: String, node_type: String = "PASSIVE", trait_id: int = -1, skill_id: int = -1, attribute_bonuses: Dictionary = {}) -> int:
	"""Save a new node to the database"""
	var json = JSON.new()
	var bonuses_json = json.stringify(attribute_bonuses) if attribute_bonuses.size() > 0 else ""
	
	var insert_query = """
	INSERT INTO nodes (name, description, node_type, trait_id, skill_id, attribute_bonuses)
	VALUES ('%s', '%s', '%s', %s, %s, '%s')
	""" % [
		name.replace("'", "''"),  # Escape single quotes
		description.replace("'", "''"),
		node_type,
		str(trait_id) if trait_id > 0 else "NULL",
		str(skill_id) if skill_id > 0 else "NULL",
		bonuses_json
	]
	
	db.query(insert_query)
	if is_query_successful():
		var node_id = db.last_insert_rowid
		print("Node saved successfully with ID: ", node_id)
		return node_id
	else:
		print("Error saving node: ", db.error_message)
		return -1

func update_node(node_id: int, name: String, description: String, node_type: String = "PASSIVE", trait_id: int = -1, skill_id: int = -1, attribute_bonuses: Dictionary = {}) -> bool:
	"""Update an existing node in the database"""
	var json = JSON.new()
	var bonuses_json = json.stringify(attribute_bonuses) if attribute_bonuses.size() > 0 else ""
	
	var update_query = """
	UPDATE nodes 
	SET name = '%s', description = '%s', node_type = '%s', trait_id = %s, skill_id = %s, attribute_bonuses = '%s'
	WHERE id = %d
	""" % [
		name.replace("'", "''"),  # Escape single quotes
		description.replace("'", "''"),
		node_type,
		str(trait_id) if trait_id > 0 else "NULL",
		str(skill_id) if skill_id > 0 else "NULL",
		bonuses_json,
		node_id
	]
	
	db.query(update_query)
	if is_query_successful():
		print("Node updated successfully")
		return true
	else:
		print("Error updating node: ", db.error_message)
		return false

func get_node_by_id(node_id: int) -> Dictionary:
	"""Get a node by ID"""
	var query = "SELECT * FROM nodes WHERE id = %d" % node_id
	db.query(query)
	
	if is_query_successful() and db.query_result.size() > 0:
		var node_data = db.query_result[0]
		
		# Parse JSON attribute bonuses
		if node_data.attribute_bonuses:
			var json = JSON.new()
			if json.parse(node_data.attribute_bonuses) == OK:
				node_data.attribute_bonuses_dict = json.data
			else:
				node_data.attribute_bonuses_dict = {}
		else:
			node_data.attribute_bonuses_dict = {}
		
		return node_data
	else:
		print("Node not found with ID: ", node_id)
		return {}

func get_all_nodes() -> Array:
	"""Get all nodes from the database"""
	var query = """
	SELECT n.*, t.name as trait_name, a.name as skill_name
	FROM nodes n
	LEFT JOIN traits t ON n.trait_id = t.id
	LEFT JOIN abilities a ON n.skill_id = a.id
	ORDER BY n.name
	"""
	
	db.query(query)
	if is_query_successful():
		var nodes = []
		for node_data in db.query_result:
			# Parse JSON attribute bonuses
			if node_data.attribute_bonuses:
				var json = JSON.new()
				if json.parse(node_data.attribute_bonuses) == OK:
					node_data.attribute_bonuses_dict = json.data
				else:
					node_data.attribute_bonuses_dict = {}
			else:
				node_data.attribute_bonuses_dict = {}
			
			nodes.append(node_data)
		
		print("Successfully fetched %d nodes from database" % nodes.size())
		return nodes
	else:
		print("Error fetching nodes: ", db.error_message)
		return []

func delete_node(node_id: int) -> bool:
	"""Delete a node by ID"""
	var delete_query = "DELETE FROM nodes WHERE id = %d" % node_id
	db.query(delete_query)
	
	if is_query_successful():
		print("Node deleted successfully")
		return true
	else:
		print("Error deleting node: ", db.error_message)
		return false

func get_nodes_by_trait(trait_id: int) -> Array:
	"""Get all nodes associated with a specific trait"""
	var query = "SELECT * FROM nodes WHERE trait_id = %d ORDER BY name" % trait_id
	db.query(query)
	
	if is_query_successful():
		var nodes = []
		for node_data in db.query_result:
			# Parse JSON attribute bonuses
			if node_data.attribute_bonuses:
				var json = JSON.new()
				if json.parse(node_data.attribute_bonuses) == OK:
					node_data.attribute_bonuses_dict = json.data
				else:
					node_data.attribute_bonuses_dict = {}
			else:
				node_data.attribute_bonuses_dict = {}
			
			nodes.append(node_data)
		
		return nodes
	else:
		print("Error fetching nodes by trait: ", db.error_message)
		return []

func get_nodes_by_skill(skill_id: int) -> Array:
	"""Get all nodes associated with a specific skill"""
	var query = "SELECT * FROM nodes WHERE skill_id = %d ORDER BY name" % skill_id
	db.query(query)
	
	if is_query_successful():
		var nodes = []
		for node_data in db.query_result:
			# Parse JSON attribute bonuses
			if node_data.attribute_bonuses:
				var json = JSON.new()
				if json.parse(node_data.attribute_bonuses) == OK:
					node_data.attribute_bonuses_dict = json.data
				else:
					node_data.attribute_bonuses_dict = {}
			else:
				node_data.attribute_bonuses_dict = {}
			
			nodes.append(node_data)
		
		return nodes
	else:
		print("Error fetching nodes by skill: ", db.error_message)
		return []

# Skill Tree management methods
func save_skill_tree(name: String, description: String, data: Dictionary, parents: String = "") -> int:
	"""Save a skill tree to the database"""
	var json = JSON.new()
	var data_json = json.stringify(data)
	
	var insert_query = """
	INSERT INTO skill_tree (name, description, data, parents)
	VALUES ('%s', '%s', '%s', '%s')
	""" % [
		name.replace("'", "''"),  # Escape single quotes
		description.replace("'", "''"),
		data_json,
		parents.replace("'", "''")
	]
	
	db.query(insert_query)
	if is_query_successful():
		var tree_id = db.last_insert_rowid
		print("Skill tree saved successfully with ID: ", tree_id)
		return tree_id
	else:
		print("Error saving skill tree: ", db.error_message)
		return -1

func update_skill_tree(tree_id: int, name: String, description: String, data: Dictionary, parents: String = "") -> bool:
	"""Update an existing skill tree in the database"""
	var json = JSON.new()
	var data_json = json.stringify(data)
	
	var update_query = """
	UPDATE skill_tree 
	SET name = '%s', description = '%s', data = '%s', parents = '%s'
	WHERE id = %d
	""" % [
		name.replace("'", "''"),  # Escape single quotes
		description.replace("'", "''"),
		data_json,
		parents.replace("'", "''"),
		tree_id
	]
	
	db.query(update_query)
	if is_query_successful():
		print("Skill tree updated successfully")
		return true
	else:
		print("Error updating skill tree: ", db.error_message)
		return false

func get_skill_tree_by_id(tree_id: int) -> Dictionary:
	"""Get a skill tree by ID"""
	var query = "SELECT * FROM skill_tree WHERE id = %d" % tree_id
	db.query(query)
	
	if is_query_successful() and db.query_result.size() > 0:
		var tree_data = db.query_result[0]
		
		# Parse JSON data
		if tree_data.data:
			var json = JSON.new()
			if json.parse(tree_data.data) == OK:
				tree_data.data_dict = json.data
			else:
				tree_data.data_dict = {}
		else:
			tree_data.data_dict = {}
		
		return tree_data
	else:
		print("Skill tree not found with ID: ", tree_id)
		return {}

func get_all_skill_trees() -> Array:
	"""Get all skill trees from the database"""
	var query = "SELECT * FROM skill_tree ORDER BY name"
	
	db.query(query)
	if is_query_successful():
		var trees = []
		for tree_data in db.query_result:
			# Parse JSON data
			if tree_data.data:
				var json = JSON.new()
				if json.parse(tree_data.data) == OK:
					tree_data.data_dict = json.data
				else:
					tree_data.data_dict = {}
			else:
				tree_data.data_dict = {}
			
			trees.append(tree_data)
		
		print("Successfully fetched %d skill trees from database" % trees.size())
		return trees
	else:
		print("Error fetching skill trees: ", db.error_message)
		return []

func delete_skill_tree(tree_id: int) -> bool:
	"""Delete a skill tree by ID"""
	var delete_query = "DELETE FROM skill_tree WHERE id = %d" % tree_id
	db.query(delete_query)
	
	if is_query_successful():
		print("Skill tree deleted successfully")
		return true
	else:
		print("Error deleting skill tree: ", db.error_message)
		return false

func get_skill_tree_by_name(name: String) -> Dictionary:
	"""Get a skill tree by name"""
	var query = "SELECT * FROM skill_tree WHERE name = '%s'" % name.replace("'", "''")
	db.query(query)
	
	if is_query_successful() and db.query_result.size() > 0:
		var tree_data = db.query_result[0]
		
		# Parse JSON data
		if tree_data.data:
			var json = JSON.new()
			if json.parse(tree_data.data) == OK:
				tree_data.data_dict = json.data
			else:
				tree_data.data_dict = {}
		else:
			tree_data.data_dict = {}
		
		return tree_data
	else:
		print("Skill tree not found with name: ", name)
		return {}

func seed_nodes():
	"""Seed the database with sample skill tree nodes"""
	# Check if we already have node data
	var check_query = "SELECT COUNT(*) as count FROM nodes"
	db.query(check_query)
	var result = db.query_result
	
	if result.size() > 0 and result[0]["count"] > 0:
		print("Database already contains node data")
		return
	
	print("No existing node data found, seeding nodes...")
	
	# Get some trait and ability IDs for foreign key references
	var traits = get_all_traits()
	var abilities = get_all_abilities()
	
	var trait_id = -1
	var ability_id = -1
	
	if traits.size() > 0:
		trait_id = traits[0].id
	if abilities.size() > 0:
		ability_id = abilities[0].id
	
	# Sample nodes data
	var nodes_data = [
		{
			"name": "Combat Mastery",
			"description": "Master of all combat techniques",
			"node_type": "MASTER_ATTRIBUTE",
			"trait_id": trait_id,
			"skill_id": -1,
			"attribute_bonuses": {"damage": 15, "critical_chance": 10}
		},
		{
			"name": "Arcane Knowledge",
			"description": "Deep understanding of magical arts",
			"node_type": "IMPROVEMENT",
			"trait_id": -1,
			"skill_id": ability_id,
			"attribute_bonuses": {"mana": 20, "resistance": 15}
		},
		{
			"name": "Stealth Expert",
			"description": "Master of stealth and subterfuge",
			"node_type": "PASSIVE",
			"trait_id": trait_id,
			"skill_id": -1,
			"attribute_bonuses": {"dodge": 20, "accuracy": 10}
		},
		{
			"name": "Leadership",
			"description": "Natural leader and commander",
			"node_type": "ACTIVE",
			"trait_id": -1,
			"skill_id": -1,
			"attribute_bonuses": {"willpower": 15, "endurance": 10}
		}
	]
	
	for node in nodes_data:
		var node_id = save_node(
			node.name,
			node.description,
			node.node_type,
			node.trait_id,
			node.skill_id,
			node.attribute_bonuses
		)
		
		if node_id > 0:
			print("Seeded node: ", node.name)
		else:
			print("Failed to seed node: ", node.name)
	
	print("Node seeding complete")
