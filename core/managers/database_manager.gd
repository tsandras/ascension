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
	# Create attributes table
	var attributes_query = """
	CREATE TABLE IF NOT EXISTS attributes (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		base_value INTEGER NOT NULL DEFAULT 2,
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
		{"name": "Vigor", "description": "Physical strength and health", "display_order": 1},
		{"name": "Essence", "description": "Magical power and energy", "display_order": 2},
		{"name": "Perception", "description": "Awareness and intuition", "display_order": 3},
		{"name": "Willpower", "description": "Mental resilience and determination", "display_order": 4},
		{"name": "Intelligence", "description": "Reasoning and learning ability", "display_order": 5},
		{"name": "Constitution", "description": "Endurance and vitality", "display_order": 6}
	]
	
	for attr in attributes_data:
		var insert_query = """
		INSERT INTO attributes (name, base_value, max_value, display_order, description)
		VALUES ('%s', 2, 6, %d, '%s')
		""" % [attr.name, attr.display_order, attr.description]
		
		db.query(insert_query)
		if not is_query_successful():
			print("Error inserting attribute %s: %s" % [attr.name, db.error_message])
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
	
	# Insert the 10 abilities
	var abilities_data = [
		{"name": "Scoundrel", "description": "Sneaking, thievery, and cunning", "display_order": 1},
		{"name": "Fire magic", "description": "Destructive fire spells and pyromancy", "display_order": 2},
		{"name": "Single-handed", "description": "One-handed weapon mastery", "display_order": 3},
		{"name": "Two-handed", "description": "Two-handed weapon expertise", "display_order": 4},
		{"name": "Dual wielding", "description": "Fighting with weapons in both hands", "display_order": 5},
		{"name": "Ranged", "description": "Bows, crossbows, and throwing weapons", "display_order": 6},
		{"name": "Protection", "description": "Defensive magic and armor mastery", "display_order": 7},
		{"name": "Tacticien", "description": "Leadership and battlefield strategy", "display_order": 8},
		{"name": "Blood magic", "description": "Dark magic using life force", "display_order": 9},
		{"name": "Magic source", "description": "Pure magical energy manipulation", "display_order": 10}
	]
	
	for ability in abilities_data:
		var insert_query = """
		INSERT INTO abilities (name, base_value, max_value, display_order, description)
		VALUES ('%s', 0, 6, %d, '%s')
		""" % [ability.name, ability.display_order, ability.description]
		
		db.query(insert_query)
		if not is_query_successful():
			print("Error inserting ability %s: %s" % [ability.name, db.error_message])
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
		{"name": "Simple Forest Test", "width": 3, "height": 3, "description": "A simple test map with 9 forest tiles in a 3x3 grid"},
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
			print("Error inserting ref_map %s: %s" % [map_data.name, db.error_message])
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
		{"type_name": "mountain", "is_walkable": false, "color_hex": "#A0A0A0", "movement_cost": 3, "texture_path": HexTileConstants.get_texture_path("mountain"), "description": "Tall mountains"},
		{"type_name": "green_mountain", "is_walkable": false, "color_hex": "#A0A0A0", "movement_cost": 3, "texture_path": HexTileConstants.get_texture_path("green_mountain"), "description": "Tall mountains with trees"},
		{"type_name": "grasslands", "is_walkable": true, "color_hex": "#A0A0A0", "movement_cost": HexTileConstants.DEFAULT_MOVEMENT_COST, "texture_path": HexTileConstants.get_texture_path("grasslands"), "description": "Grasslands"},
	]
	
	for tile_data in tiles_data:
		var insert_query = """
		INSERT INTO ref_tile (type_name, is_walkable, color_hex, movement_cost, texture_path, tileset_x, tileset_y, tile_size, description)
		VALUES ('%s', %s, '%s', %d, '%s', %d, %d, %d, '%s')
		""" % [tile_data.type_name, str(tile_data.is_walkable).to_lower(), tile_data.color_hex, tile_data.movement_cost, tile_data.texture_path, 0, 0, HexTileConstants.DEFAULT_TILE_SIZE_DB, tile_data.description]
		
		db.query(insert_query)
		if not is_query_successful():
			print("Error inserting ref_tile %s: %s" % [tile_data.type_name, db.error_message])
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
	
	# Get the Simple Forest Test map ID
	var map_query = "SELECT id FROM ref_map WHERE name = 'Simple Forest Test'"
	db.query(map_query)
	if not is_query_successful() or db.query_result.size() == 0:
		print("Error: Simple Forest Test map not found")
		return
	
	var forest_map_id = db.query_result[0]["id"]
	
	# Get the forest tile ID
	var tile_query = "SELECT id FROM ref_tile WHERE type_name = 'forest'"
	db.query(tile_query)
	if not is_query_successful() or db.query_result.size() == 0:
		print("Error: Forest tile not found")
		return
	
	var forest_tile_id = db.query_result[0]["id"]

	# Get the mountain tile ID
	var mountain_tile_query = "SELECT id FROM ref_tile WHERE type_name = 'mountain'"
	db.query(mountain_tile_query)
	if not is_query_successful() or db.query_result.size() == 0:
		print("Error: Mountain tile not found")
		return
	
	var mountain_tile_id = db.query_result[0]["id"]

	# get the mountain forest tile ID
	var mountain_forest_tile_query = "SELECT id FROM ref_tile WHERE type_name = 'green_mountain'"
	db.query(mountain_forest_tile_query)
	if not is_query_successful() or db.query_result.size() == 0:
		print("Error: Mountain forest tile not found")
		return
	
	var green_mountain_tile_id = db.query_result[0]["id"]

	# get grasslands tile ID
	var grasslands_tile_query = "SELECT id FROM ref_tile WHERE type_name = 'grasslands'"
	db.query(grasslands_tile_query)
	if not is_query_successful() or db.query_result.size() == 0:
		print("Error: Grasslands tile not found")
		return

	var grasslands_tile_id = db.query_result[0]["id"]
	
	# Create 9 forest tiles in a 3x3 grid for the Simple Forest Test map
	for y in range(3):
		for x in range(3):
			var insert_query = ""
			if x == 1 and y == 1:
				insert_query = """
				INSERT INTO ref_map_tile (ref_map_id, ref_tile_id, x, y)
				VALUES (%d, %d, %d, %d)
				""" % [forest_map_id, green_mountain_tile_id, x, y]
				print("Inserting green mountain tile at (%d, %d)" % [x, y])
			elif x == 1 or y == 1:
				insert_query = """
				INSERT INTO ref_map_tile (ref_map_id, ref_tile_id, x, y)
				VALUES (%d, %d, %d, %d)
				""" % [forest_map_id, mountain_tile_id, x, y]
				print("Inserting mountain tile at (%d, %d)" % [x, y])
			elif x == 0 and y == 0:
				insert_query = """
				INSERT INTO ref_map_tile (ref_map_id, ref_tile_id, x, y)
				VALUES (%d, %d, %d, %d)
				""" % [forest_map_id, forest_tile_id, x, y]
				print("Inserting forest tile at (%d, %d)" % [x, y])
			else:
				insert_query = """
				INSERT INTO ref_map_tile (ref_map_id, ref_tile_id, x, y)
				VALUES (%d, %d, %d, %d)
				""" % [forest_map_id, grasslands_tile_id, x, y]
				print("Inserting grasslands tile at (%d, %d)" % [x, y])
		
			db.query(insert_query)
			if not is_query_successful():
				print("Error creating ref_map_tile at (%d, %d): %s" % [x, y, db.error_message])
	
	print("Created ref_map_tile entries for Simple Forest Test map (3x3 grid)")

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
		print("Error: Ref_map '%s' not found" % ref_map_name)
		return false
	
	var ref_map_id = db.query_result[0]["id"]
	print("Found ref_map_id: %d for map: %s" % [ref_map_id, ref_map_name])
	
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

# Mark a tile as visited by the character
func mark_tile_visited(game_id: int, x: int, y: int) -> bool:
	var update_query = """
	UPDATE map_tile 
	SET character_visited = 1, 
		visit_count = visit_count + 1,
		last_visited = CURRENT_TIMESTAMP
	WHERE game_id = %d AND x = %d AND y = %d
	""" % [game_id, x, y]
	
	db.query(update_query)
	
	if is_query_successful():
		print("Marked tile (%d, %d) as visited for game %d" % [x, y, game_id])
		return true
	else:
		print("Error marking tile as visited: ", db.error_message)
		return false

# Set tile occupation status
func set_tile_occupied(game_id: int, x: int, y: int, occupied: bool, entity_id: int = 0) -> bool:
	var update_query = """
	UPDATE map_tile 
	SET is_occupied = %s, entity_id = %d
	WHERE game_id = %d AND x = %d AND y = %d
	""" % [str(occupied).to_lower(), entity_id, game_id, x, y]
	
	db.query(update_query)
	
	if is_query_successful():
		print("Set tile (%d, %d) occupied=%s for game %d" % [x, y, str(occupied), game_id])
		return true
	else:
		print("Error setting tile occupation: ", db.error_message)
		return false

# Legacy function names for compatibility (will be removed)
func get_all_map_references():
	return get_all_ref_maps()

func get_all_tile_references():
	return get_all_ref_tiles()

func get_current_map(game_id: int = 1):
	return get_current_map_info(game_id)

func get_map_tiles(map_id: int):
	# This function is deprecated - use get_game_map_tiles instead
	print("Warning: get_map_tiles is deprecated, use get_game_map_tiles")
	return get_game_map_tiles(1)  # Default to game_id 1

# Helper function to update tileset coordinates for a tile type
func update_tile_tileset_coordinates(type_name: String, tileset_x: int, tileset_y: int, tile_size: int = 75) -> bool:
	var update_query = """
	UPDATE tile_reference 
	SET tileset_x = %d, tileset_y = %d, tile_size = %d
	WHERE type_name = '%s'
	""" % [tileset_x, tileset_y, tile_size, type_name]
	
	db.query(update_query)
	
	if is_query_successful():
		print("Updated tileset coordinates for %s: (%d, %d)" % [type_name, tileset_x, tileset_y])
		return true
	else:
		print("Error updating tileset coordinates for %s: %s" % [type_name, db.error_message])
		return false

# Debug function to show current tileset mappings
func print_tileset_mappings():
	var query = "SELECT type_name, tileset_x, tileset_y, tile_size FROM tile_reference ORDER BY type_name"
	db.query(query)
	
	if is_query_successful():
		print("=== TILESET MAPPINGS ===")
		for tile_ref in db.query_result:
			print("%s: (%d, %d) [size: %d]" % [tile_ref["type_name"], tile_ref["tileset_x"], tile_ref["tileset_y"], tile_ref["tile_size"]])
		print("========================")
	else:
		print("Error fetching tileset mappings: ", db.error_message)

func close_database():
	if db:
		db.close_db()

# Force database recreation (useful when schema changes)
func reset_database():
	print("Resetting database...")
	
	# Close current database
	if db:
		db.close_db()
	
	# Remove the database file to force recreation
	if FileAccess.file_exists(db_name):
		DirAccess.remove_absolute(db_name)
		print("Removed existing database file")
	
	# Reinitialize
	db = SQLite.new()
	db.path = db_name
	db.open_db()
	
	# Recreate tables and seed data
	create_tables()
	seed_data()
	
	print("Database reset complete")

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
			print("Error updating texture path for %s: %s" % [update.type_name, db.error_message])
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
func create_simple_forest_test_game(game_id: int = 1) -> bool:
	return create_new_game("Simple Forest Test", game_id) 
