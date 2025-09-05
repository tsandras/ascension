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
		display_order INTEGER NOT NULL DEFAULT 0,
		description TEXT,
		attribute_bonuses JSON
	);
	"""
	
	db.query(races_query)
	if not is_query_successful():
		print("Error creating races table: ", db.error_message)
	else:
		print("Races table created successfully")
	
	# Create races_traits join table
	var races_traits_query = """
	CREATE TABLE IF NOT EXISTS races_traits (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		race_id INTEGER NOT NULL,
		trait_id INTEGER NOT NULL,
		FOREIGN KEY (race_id) REFERENCES races(id),
		FOREIGN KEY (trait_id) REFERENCES traits(id),
		UNIQUE(race_id, trait_id)
	);
	"""
	
	db.query(races_traits_query)
	if not is_query_successful():
		print("Error creating races_traits table: ", db.error_message)
	else:
		print("Races_traits table created successfully")
	
	# Create traits table
	var traits_query = """
	CREATE TABLE IF NOT EXISTS traits (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		description TEXT,
		icon_name TEXT,
		point_bonuses TEXT,
		attribute_scaling_bonuses TEXT,
		master_attribute_scaling_bonuses TEXT,
		others_bonuses TEXT,
		display_order INTEGER NOT NULL DEFAULT 0
	);
	"""
	
	db.query(traits_query)
	if not is_query_successful():
		print("Error creating traits table: ", db.error_message)
	else:
		print("Traits table created successfully")
	
	# Note: competences table removed - using abilities table instead
	
	# Create nodes table for skill trees
	var nodes_query = """
	CREATE TABLE IF NOT EXISTS nodes (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		description TEXT,
		icon_name TEXT,
		node_type TEXT NOT NULL DEFAULT 'PASSIVE',
		trait_id INTEGER,
		skill_id INTEGER,
		attribute_bonuses JSON,
		master_attribute_bonuses JSON,
		ability_bonuses JSON,
		FOREIGN KEY (trait_id) REFERENCES traits(id),
		FOREIGN KEY (skill_id) REFERENCES abilities(id)
	);
	"""
	
	db.query(nodes_query)
	if not is_query_successful():
		print("Error creating nodes table: ", db.error_message)
	else:
		print("Nodes table created successfully")
	
	# Migrate existing nodes tables to add new bonus columns if they don't exist
	var nodes_migration_query1 = "ALTER TABLE nodes ADD COLUMN master_attribute_bonuses JSON"
	db.query(nodes_migration_query1)
	if not is_query_successful():
		# Check if it's a duplicate column error
		if "duplicate column name" in db.error_message:
			print("Nodes master_attribute_bonuses column already exists")
		else:
			print("Nodes master_attribute_bonuses column migration note: " + db.error_message)
	else:
		print("Nodes table migrated to include master_attribute_bonuses column")
	
	var nodes_migration_query2 = "ALTER TABLE nodes ADD COLUMN ability_bonuses JSON"
	db.query(nodes_migration_query2)
	if not is_query_successful():
		# Check if it's a duplicate column error
		if "duplicate column name" in db.error_message:
			print("Nodes ability_bonuses column already exists")
		else:
			print("Nodes ability_bonuses column migration note: " + db.error_message)
	else:
		print("Nodes table migrated to include ability_bonuses column")
	
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
	
	# Create backgrounds table
	var backgrounds_query = """
	CREATE TABLE IF NOT EXISTS backgrounds (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		description TEXT,
		attribute_bonuses JSON,
		ability_bonuses JSON,
		skill_bonuses JSON,
		starting_equipment TEXT,
		display_order INTEGER NOT NULL DEFAULT 0
	);
	"""
	
	db.query(backgrounds_query)
	if not is_query_successful():
		print("Error creating backgrounds table: ", db.error_message)
	else:
		print("Backgrounds table created successfully")
	
	# Migrate existing backgrounds tables to add missing columns if they don't exist
	var backgrounds_migration_queries = [
		"ALTER TABLE backgrounds ADD COLUMN attribute_bonuses JSON",
		"ALTER TABLE backgrounds ADD COLUMN skill_bonuses JSON",
		"ALTER TABLE backgrounds ADD COLUMN starting_equipment TEXT"
	]
	
	for migration_query in backgrounds_migration_queries:
		db.query(migration_query)
		if not is_query_successful():
			# Check if it's a duplicate column error
			if "duplicate column name" in db.error_message:
				print("Backgrounds column already exists")
			else:
				print("Backgrounds migration note: " + db.error_message)
		else:
			print("Backgrounds table migrated to include new columns")
	
	# Create features table
	var features_query = """
	CREATE TABLE IF NOT EXISTS features (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		description TEXT,
		icon_name TEXT,
		attribute_bonuses JSON,
		ability_bonuses JSON,
		skill_bonuses JSON,
		other_bonuses JSON,
		trait_id INTEGER,
		display_order INTEGER NOT NULL DEFAULT 0,
		FOREIGN KEY (trait_id) REFERENCES traits(id)
	);
	"""
	
	db.query(features_query)
	if not is_query_successful():
		print("Error creating features table: ", db.error_message)
	else:
		print("Features table created successfully")
	
	# Create personalities table
	var personalities_query = """
	CREATE TABLE IF NOT EXISTS personalities (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE,
		description TEXT,
		display_order INTEGER NOT NULL DEFAULT 0
	);
	"""
	
	db.query(personalities_query)
	if not is_query_successful():
		print("Error creating personalities table: ", db.error_message)
	else:
		print("Personalities table created successfully")
	
	# Migrate existing features tables to add trait_id column if it doesn't exist
	var features_migration_query = "ALTER TABLE features ADD COLUMN trait_id INTEGER"
	db.query(features_migration_query)
	if not is_query_successful():
		# Check if it's a duplicate column error
		if "duplicate column name" in db.error_message:
			print("Features trait_id column already exists")
		else:
			print("Features trait column migration note: " + db.error_message)
	else:
		print("Features table migrated to include trait_id column")
	
	# Create character table for persistent character creation
	var character_query = """
	CREATE TABLE IF NOT EXISTS character (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL,
		race_id INTEGER,
		background_id INTEGER,
		feature_id INTEGER,
		personality_id INTEGER,
		sex TEXT NOT NULL,
		portrait TEXT,
		avatar TEXT,
		attributes JSON,
		abilities JSON,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (race_id) REFERENCES races(id),
		FOREIGN KEY (background_id) REFERENCES backgrounds(id),
		FOREIGN KEY (feature_id) REFERENCES features(id),
		FOREIGN KEY (personality_id) REFERENCES personalities(id)
	);
	"""
	
	db.query(character_query)
	if not is_query_successful():
		print("Error creating character table: ", db.error_message)
	else:
		print("Character table created successfully")
	
	# Migrate existing character tables to add feature_id column if it doesn't exist
	var migration_query = "ALTER TABLE character ADD COLUMN feature_id INTEGER"
	db.query(migration_query)
	if not is_query_successful():
		# Check if it's a duplicate column error
		if "duplicate column name" in db.error_message:
			print("Character feature_id column already exists")
		else:
			print("Feature column migration note: " + db.error_message)
	else:
		print("Character table migrated to include feature_id column")
	
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
	seed_backgrounds()  # Seed backgrounds
	seed_features()     # Seed features
	seed_abilities()    # Seed abilities (includes old competences)
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
		# Update existing traits with icon names if they don't have them
		_update_existing_traits_with_icons()
		return
	
	print("No existing trait data found, seeding traits...")
	
	# Define traits data as GDScript objects
	var traits_data = [
		{
			"name": "Polyvalent",
			"description": "Humans are adaptable and versatile, gaining small bonuses to all areas of expertise",
			"icon_name": "hobbit",
			"point_bonuses": "1:4",
			"attribute_scaling_bonuses": "",
			"master_attribute_scaling_bonuses": "",
			"others_bonuses": "10% [Chance avoidance]; 10% to [Critical chance]",
			"display_order": 1
		},
		{
			"name": "Ancient Wisdom",
			"description": "Elfs possess centuries of accumulated knowledge and unshakeable mental fortitude",
			"icon_name": "magic_book",
			"point_bonuses": "",
			"attribute_scaling_bonuses": "{intelligence}x2 [MP]",
			"master_attribute_scaling_bonuses": "",
			"others_bonuses": "Long lifespan",
			"display_order": 2
		},
		{
			"name": "Divine Heritage",
			"description": "Celestial-blooded carry divine blessings, excelling in protection and social grace",
			"icon_name": "giant",
			"point_bonuses": "",
			"attribute_scaling_bonuses": "{agility}x0.25 [AP]; {agility}x0.5 to [Physical damage]",
			"master_attribute_scaling_bonuses": "",
			"others_bonuses": "Fire and lightning resistance",
			"display_order": 3
		},
		{
			"name": "Infernal Power",
			"description": "Infernal-blooded channel raw dark power, devastating in combat but consuming",
			"icon_name": "lion",
			"point_bonuses": "",
			"attribute_scaling_bonuses": "{strenght} [MP]; {strenght} to [Critical chance]",
			"master_attribute_scaling_bonuses": "",
			"others_bonuses": "Fire and cold resistance",
			"display_order": 4
		}
	]
	
	# Insert each trait
	for trait_data in traits_data:
		var insert_query = """
		INSERT INTO traits (name, description, icon_name, point_bonuses, attribute_scaling_bonuses, master_attribute_scaling_bonuses, others_bonuses, display_order)
		VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s', %d)
		""" % [
			trait_data.name,
			trait_data.description,
			trait_data.icon_name,
			trait_data.get("point_bonuses", ""),
			trait_data.get("attribute_scaling_bonuses", ""),
			trait_data.get("master_attribute_scaling_bonuses", ""),
			trait_data.get("others_bonuses", ""),
			trait_data.display_order
		]
		
		db.query(insert_query)
		if is_query_successful():
			print("Inserted trait: " + trait_data.name)
		else:
			print("Error inserting " + trait_data.name + " trait: " + db.error_message)
	
	print("Trait seeding complete")

func _update_existing_traits_with_icons():
	"""Update existing traits with icon names if they don't have them"""
	print("Updating existing traits with icon names...")
	
	# Define icon mappings for existing traits
	var icon_mappings = {
		"Polyvalent": "hobbit",
		"Ancient Wisdom": "magic_book",
		"Divine Heritage": "giant",
		"Infernal Power": "lion"
	}
	
	# Update each trait that doesn't have an icon_name
	for trait_name in icon_mappings:
		var update_query = """
		UPDATE traits 
		SET icon_name = '%s' 
		WHERE name = '%s' AND (icon_name IS NULL OR icon_name = '')
		""" % [icon_mappings[trait_name], trait_name]
		
		db.query(update_query)
		if is_query_successful():
			print("Updated trait '%s' with icon '%s'" % [trait_name, icon_mappings[trait_name]])
		else:
			print("Error updating trait '%s': %s" % [trait_name, db.error_message])
	
	print("Trait icon updates complete")

func _update_existing_nodes_with_icons():
	"""Update existing nodes with icon names if they don't have them"""
	print("Updating existing nodes with icon names...")
	
	# Define icon mappings for existing nodes
	var icon_mappings = {
		"Combat Mastery": "lion",
		"Arcane Knowledge": "magic_book",
		"Stealth Expert": "monkey",
		"Leadership": "giant"
	}
	
	# Update each node that doesn't have an icon_name
	for node_name in icon_mappings:
		var update_query = """
		UPDATE nodes 
		SET icon_name = '%s' 
		WHERE name = '%s' AND (icon_name IS NULL OR icon_name = '')
		""" % [icon_mappings[node_name], node_name]
		
		db.query(update_query)
		if is_query_successful():
			print("Updated node '%s' with icon '%s'" % [node_name, icon_mappings[node_name]])
		else:
			print("Error updating node '%s': %s" % [node_name, db.error_message])
	
	print("Node icon updates complete")

func seed_races():
	# Check if we already have race data
	var check_query = "SELECT COUNT(*) as count FROM races"
	db.query(check_query)
	var result = db.query_result
	
	if result.size() > 0 and result[0]["count"] > 0:
		print("Database already contains race data")
		return
	
	print("No existing race data found, seeding races...")
	
	# Insert the 4 races with their attribute bonuses
	var races_data = [
		{
			"name": "Human", 
			"description": "The most adaptable and common race", 
			"display_order": 1, 
			"attribute_bonuses": {}
		},
		{
			"name": "Elf", 
			"description": "Ancient and wise beings with extended lifespans", 
			"display_order": 2, 
			"attribute_bonuses": {"stamina": -1, "resolution": 1}
		},
		{
			"name": "Celestial-blooded", 
			"description": "Descendants of celestial beings with divine heritage", 
			"display_order": 3, 
			"attribute_bonuses": {"agility": 1}
		},
		{
			"name": "Infernal-blooded", 
			"description": "Descendants of infernal beings with dark heritage", 
			"display_order": 4, 
			"attribute_bonuses": {"agility": 1}
		}
	]
	
	for race_data in races_data:
		var json = JSON.new()
		var bonuses_json = json.stringify(race_data.attribute_bonuses)
		
		var insert_query = """
		INSERT INTO races (name, display_order, description, attribute_bonuses)
		VALUES ('%s', %d, '%s', '%s')
		""" % [race_data.name, race_data.display_order, race_data.description, bonuses_json]
		
		db.query(insert_query)
		if not is_query_successful():
			print("Error inserting race " + race_data.name + ": " + db.error_message)
		else:
			print("Inserted race: ", race_data.name)
	
	# Now seed the races_traits relationships
	seed_races_traits()

func get_all_races():
	var query = """
	SELECT r.*, r.attribute_bonuses as race_attribute_bonuses
	FROM races r
	ORDER BY r.display_order
	"""
	db.query(query)
	
	if is_query_successful():
		var races = []
		for race_data in db.query_result:
			# Parse JSON attribute bonuses
			if race_data.race_attribute_bonuses:
				var json = JSON.new()
				if json.parse(race_data.race_attribute_bonuses) == OK:
					race_data.race_attribute_bonuses_dict = json.data
				else:
					race_data.race_attribute_bonuses_dict = {}
			else:
				race_data.race_attribute_bonuses_dict = {}
			
			races.append(race_data)
		
		print("Successfully fetched %d races from database" % races.size())
		return races
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

func get_background_by_name(background_name: String):
	var query = "SELECT * FROM backgrounds WHERE name = '%s'" % background_name
	db.query(query)
	var result = db.query_result
	
	if result.size() > 0:
		var background_data = result[0]
		
		# Parse JSON ability bonuses (same as get_all_backgrounds)
		if background_data.ability_bonuses:
			var json = JSON.new()
			if json.parse(background_data.ability_bonuses) == OK:
				background_data.ability_bonuses_dict = json.data
			else:
				background_data.ability_bonuses_dict = {}
		else:
			background_data.ability_bonuses_dict = {}
		
		return background_data
	else:
		return null

func get_feature_by_name(feature_name: String):
	var query = """
	SELECT f.*, t.name as trait_name, t.description as trait_description, t.icon_name as trait_icon_name
	FROM features f
	LEFT JOIN traits t ON f.trait_id = t.id
	WHERE f.name = '%s'
	""" % feature_name
	db.query(query)
	var result = db.query_result
	
	if result.size() > 0:
		var feature_data = result[0]
		
		# Parse JSON bonuses (same as get_all_features)
		if feature_data.attribute_bonuses:
			var json = JSON.new()
			if json.parse(feature_data.attribute_bonuses) == OK:
				feature_data.attribute_bonuses_dict = json.data
			else:
				feature_data.attribute_bonuses_dict = {}
		else:
			feature_data.attribute_bonuses_dict = {}
		
		if feature_data.ability_bonuses:
			var json = JSON.new()
			if json.parse(feature_data.ability_bonuses) == OK:
				feature_data.ability_bonuses_dict = json.data
			else:
				feature_data.ability_bonuses_dict = {}
		else:
			feature_data.ability_bonuses_dict = {}
		
		if feature_data.skill_bonuses:
			var json = JSON.new()
			if json.parse(feature_data.skill_bonuses) == OK:
				feature_data.skill_bonuses_dict = json.data
			else:
				feature_data.skill_bonuses_dict = {}
		else:
			feature_data.skill_bonuses_dict = {}
		
		if feature_data.other_bonuses:
			var json = JSON.new()
			if json.parse(feature_data.other_bonuses) == OK:
				feature_data.other_bonuses_dict = json.data
			else:
				feature_data.other_bonuses_dict = {}
		else:
			feature_data.other_bonuses_dict = {}
		
		# Add trait information
		if feature_data.trait_id and feature_data.trait_name:
			feature_data.has_trait = true
			feature_data.trait_data = {
				"name": feature_data.trait_name,
				"description": feature_data.trait_description,
				"icon_name": feature_data.trait_icon_name
			}
		else:
			feature_data.has_trait = false
			feature_data.trait_data = {}
		
		return feature_data
	else:
		return null

func get_features_by_trait(trait_id: int) -> Array:
	"""Get all features that have a specific trait"""
	var query = """
	SELECT f.*, t.name as trait_name, t.description as trait_description, t.icon_name as trait_icon_name
	FROM features f
	LEFT JOIN traits t ON f.trait_id = t.id
	WHERE f.trait_id = %d
	ORDER BY f.display_order
	""" % trait_id
	db.query(query)
	
	if is_query_successful():
		var features = []
		for feature_data in db.query_result:
			# Parse JSON bonuses (same as get_all_features)
			if feature_data.attribute_bonuses:
				var json = JSON.new()
				if json.parse(feature_data.attribute_bonuses) == OK:
					feature_data.attribute_bonuses_dict = json.data
				else:
					feature_data.attribute_bonuses_dict = {}
			else:
				feature_data.attribute_bonuses_dict = {}
			
			if feature_data.ability_bonuses:
				var json = JSON.new()
				if json.parse(feature_data.ability_bonuses) == OK:
					feature_data.ability_bonuses_dict = json.data
				else:
					feature_data.ability_bonuses_dict = {}
			else:
				feature_data.ability_bonuses_dict = {}
			
			if feature_data.skill_bonuses:
				var json = JSON.new()
				if json.parse(feature_data.skill_bonuses) == OK:
					feature_data.skill_bonuses_dict = json.data
				else:
					feature_data.skill_bonuses_dict = {}
			else:
				feature_data.skill_bonuses_dict = {}
			
			if feature_data.other_bonuses:
				var json = JSON.new()
				if json.parse(feature_data.other_bonuses) == OK:
					feature_data.other_bonuses_dict = json.data
				else:
					feature_data.other_bonuses_dict = {}
			else:
				feature_data.other_bonuses_dict = {}
			
			# Add trait information
			if feature_data.trait_id and feature_data.trait_name:
				feature_data.has_trait = true
				feature_data.trait_data = {
					"name": feature_data.trait_name,
					"description": feature_data.trait_description,
					"icon_name": feature_data.trait_icon_name
				}
			else:
				feature_data.has_trait = false
				feature_data.trait_data = {}
			
			features.append(feature_data)
		
		print("Successfully fetched %d features with trait ID %d" % [features.size(), trait_id])
		return features
	else:
		print("Error fetching features by trait: ", db.error_message)
		return []

func seed_abilities():
	# Check if we already have ability data
	var check_query = "SELECT COUNT(*) as count FROM abilities"
	db.query(check_query)
	var result = db.query_result
	
	if result.size() > 0 and result[0]["count"] > 0:
		print("Database already contains ability data")
		return
	
	print("No existing ability data found, seeding abilities...")
	
	# Insert the 8 abilities (formerly competences) as specified
	var abilities_data = [
		{"name": "Survival", "description": "Ability to survive in the wilderness", "display_order": 1},
		{"name": "Perception", "description": "Awareness and ability to notice details", "display_order": 2},
		{"name": "Stealth", "description": "Ability to move silently and remain hidden", "display_order": 3},
		{"name": "Knowledge", "description": "General learning and intellectual capacity", "display_order": 4},
		{"name": "Arcana", "description": "Understanding of magical theory and practice", "display_order": 5},
		{"name": "Sleight of Hand", "description": "Dexterity and manual skill for precise tasks", "display_order": 6},
		{"name": "Persuasion", "description": "Ability to influence and convince others", "display_order": 7},
		{"name": "Athletics", "description": "Physical prowess and bodily coordination", "display_order": 8}
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





# Note: competences functions removed - using abilities functions instead

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
	var query = "SELECT * FROM traits WHERE name = ?"
	var params = [trait_name]
	print("DEBUG: get_trait_by_name query: ", query, " with param: ", trait_name)
	db.query_with_bindings(query, params)
	var result = db.query_result
	
	if result.size() > 0:
		print("DEBUG: Found trait: ", result[0])
		return result[0]
	else:
		print("DEBUG: Trait not found: ", trait_name)
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


func save_character(character_name: String, race_name: String, background_name: String, feature_name: String, personality_name: String, sex: String, portrait: String, avatar: String, attributes: Dictionary, abilities: Dictionary) -> int:
	"""Save a character to the database and return the character ID"""
	print("Saving character: " + character_name)
	
	# Get race ID from race name
	var race = get_race_by_name(race_name)
	if not race:
		print("Error: Race not found: " + race_name)
		return -1
	
	var race_id = race.id
	
	# Get background ID from background name
	var background = get_background_by_name(background_name)
	if not background:
		print("Error: Background not found: " + background_name)
		return -1
	
	var background_id = background.id
	
	# Get feature ID from feature name
	var feature = get_feature_by_name(feature_name)
	if not feature:
		print("Error: Feature not found: " + feature_name)
		return -1
	
	var feature_id = feature.id
	
	# Get personality ID from personality name
	var personality = get_personality_by_name(personality_name)
	if not personality:
		print("Error: Personality not found: " + personality_name)
		return -1
	
	var personality_id = personality.id
	
	# Convert dictionaries to JSON strings for SQLite JSON columns
	var attributes_json = JSON.stringify(attributes)
	var abilities_json = JSON.stringify(abilities)
	
	# Insert character into database
	var insert_query = """
	INSERT INTO character (name, race_id, background_id, feature_id, personality_id, sex, portrait, avatar, attributes, abilities)
	VALUES ('%s', %d, %d, %d, %d, '%s', '%s', '%s', '%s', '%s')
	""" % [character_name, race_id, background_id, feature_id, personality_id, sex, portrait, avatar, attributes_json, abilities_json]
	
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
	"""Retrieve a character by ID with race, background, and feature information"""
	var query = """
	SELECT c.*, r.name as race_name, r.description as race_description, b.name as background_name, b.description as background_description, f.name as feature_name, f.description as feature_description
	FROM character c
	LEFT JOIN races r ON c.race_id = r.id
	LEFT JOIN backgrounds b ON c.background_id = b.id
	LEFT JOIN features f ON c.feature_id = f.id
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
		
		return character_data
	else:
		print("Character not found with ID: " + str(character_id))
		return {}

func get_all_characters() -> Array:
	"""Get all characters with their race, background, and feature information"""
	var query = """
	SELECT c.id, c.name, c.created_at, r.name as race_name, b.name as background_name, f.name as feature_name
	FROM character c
	LEFT JOIN races r ON c.race_id = r.id
	LEFT JOIN backgrounds b ON c.background_id = b.id
	LEFT JOIN features f ON c.feature_id = f.id
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
	SELECT c.*, r.name as race_name, r.description as race_description, b.name as background_name, b.description as background_description, f.name as feature_name, f.description as feature_description
	FROM character c
	LEFT JOIN races r ON c.race_id = r.id
	LEFT JOIN backgrounds b ON c.background_id = b.id
	LEFT JOIN features f ON c.feature_id = f.id
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
		
		print("Found last saved character: " + character_data.name)
		return character_data
	else:
		print("No saved characters found")
		return {}

# Node management methods for skill trees
func save_node(name: String, description: String, icon_name: String = "", node_type: String = "PASSIVE", trait_id: int = -1, skill_id: int = -1, attribute_bonuses: Dictionary = {}, master_attribute_bonuses: Dictionary = {}, ability_bonuses: Dictionary = {}) -> int:
	"""Save a new node to the database"""
	var json = JSON.new()
	var attr_bonuses_json = json.stringify(attribute_bonuses) if attribute_bonuses.size() > 0 else ""
	var master_attr_bonuses_json = json.stringify(master_attribute_bonuses) if master_attribute_bonuses.size() > 0 else ""
	var ability_bonuses_json = json.stringify(ability_bonuses) if ability_bonuses.size() > 0 else ""
	
	var insert_query = """
	INSERT INTO nodes (name, description, icon_name, node_type, trait_id, skill_id, attribute_bonuses, master_attribute_bonuses, ability_bonuses)
	VALUES ('%s', '%s', '%s', '%s', %s, %s, '%s', '%s', '%s')
	""" % [
		name.replace("'", "''"),  # Escape single quotes
		description.replace("'", "''"),
		icon_name,
		node_type,
		str(trait_id) if trait_id > 0 else "NULL",
		str(skill_id) if skill_id > 0 else "NULL",
		attr_bonuses_json,
		master_attr_bonuses_json,
		ability_bonuses_json
	]
	
	db.query(insert_query)
	if is_query_successful():
		var node_id = db.last_insert_rowid
		print("Node saved successfully with ID: ", node_id)
		return node_id
	else:
		print("Error saving node: ", db.error_message)
		return -1

func update_node(node_id: int, name: String, description: String, icon_name: String = "", node_type: String = "PASSIVE", trait_id: int = -1, skill_id: int = -1, attribute_bonuses: Dictionary = {}, master_attribute_bonuses: Dictionary = {}, ability_bonuses: Dictionary = {}) -> bool:
	"""Update an existing node in the database"""
	var json = JSON.new()
	var attr_bonuses_json = json.stringify(attribute_bonuses) if attribute_bonuses.size() > 0 else ""
	var master_attr_bonuses_json = json.stringify(master_attribute_bonuses) if master_attribute_bonuses.size() > 0 else ""
	var ability_bonuses_json = json.stringify(ability_bonuses) if ability_bonuses.size() > 0 else ""
	
	var update_query = """
	UPDATE nodes 
	SET name = '%s', description = '%s', icon_name = '%s', node_type = '%s', trait_id = %s, skill_id = %s, attribute_bonuses = '%s', master_attribute_bonuses = '%s', ability_bonuses = '%s'
	WHERE id = %d
	""" % [
		name.replace("'", "''"),  # Escape single quotes
		description.replace("'", "''"),
		icon_name,
		node_type,
		str(trait_id) if trait_id > 0 else "NULL",
		str(skill_id) if skill_id > 0 else "NULL",
		attr_bonuses_json,
		master_attr_bonuses_json,
		ability_bonuses_json,
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
		
		# Parse JSON master attribute bonuses
		if node_data.master_attribute_bonuses:
			var json = JSON.new()
			if json.parse(node_data.master_attribute_bonuses) == OK:
				node_data.master_attribute_bonuses_dict = json.data
			else:
				node_data.master_attribute_bonuses_dict = {}
		else:
			node_data.master_attribute_bonuses_dict = {}
		
		# Parse JSON ability bonuses
		if node_data.ability_bonuses:
			var json = JSON.new()
			if json.parse(node_data.ability_bonuses) == OK:
				node_data.ability_bonuses_dict = json.data
			else:
				node_data.ability_bonuses_dict = {}
		else:
			node_data.ability_bonuses_dict = {}
		
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
			
			# Parse JSON master attribute bonuses
			if node_data.master_attribute_bonuses:
				var json = JSON.new()
				if json.parse(node_data.master_attribute_bonuses) == OK:
					node_data.master_attribute_bonuses_dict = json.data
				else:
					node_data.master_attribute_bonuses_dict = {}
			else:
				node_data.master_attribute_bonuses_dict = {}
			
			# Parse JSON ability bonuses
			if node_data.ability_bonuses:
				var json = JSON.new()
				if json.parse(node_data.ability_bonuses) == OK:
					node_data.ability_bonuses_dict = json.data
				else:
					node_data.ability_bonuses_dict = {}
			else:
				node_data.ability_bonuses_dict = {}
			
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
	# First check if there are any skill trees
	var count_query = "SELECT COUNT(*) as count FROM skill_tree"
	db.query(count_query)
	if is_query_successful() and db.query_result.size() > 0:
		print("DEBUG: Total skill trees in database: ", db.query_result[0].count)
	else:
		print("DEBUG: Could not get skill tree count")
	
	var query = "SELECT id, name, description, data FROM skill_tree ORDER BY name"
	
	print("DEBUG: Executing query: ", query)
	db.query(query)
	
	if is_query_successful():
		print("DEBUG: Query successful, result size: ", db.query_result.size())
		print("DEBUG: Raw query result: ", db.query_result)
		
		var trees = []
		for i in range(db.query_result.size()):
			var tree_data = db.query_result[i]
			print("DEBUG: Tree data %d: ", i, tree_data)
			print("DEBUG: Tree data type: ", typeof(tree_data))
			
			# Check if this is a proper dictionary with data
			if typeof(tree_data) == TYPE_DICTIONARY and tree_data.has("id") and tree_data.has("name"):
				print("DEBUG: Valid tree data found")
				print("DEBUG: Tree ID: ", tree_data.id)
				print("DEBUG: Tree name: ", tree_data.name)
				
				# Parse JSON data
				if tree_data.has("data") and tree_data.data:
					var json = JSON.new()
					if json.parse(tree_data.data) == OK:
						tree_data.data_dict = json.data
						print("DEBUG: Parsed data_dict: ", tree_data.data_dict)
					else:
						tree_data.data_dict = {}
						print("DEBUG: Failed to parse JSON data")
				else:
					tree_data.data_dict = {}
					print("DEBUG: No data field")
				
				trees.append(tree_data)
			else:
				print("DEBUG: Invalid tree data structure, skipping")
		
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
		# Update existing nodes with icon names if they don't have them
		_update_existing_nodes_with_icons()
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
			"icon_name": "lion",
			"node_type": "MASTER_ATTRIBUTE",
			"trait_id": trait_id,
			"skill_id": -1,
			"attribute_bonuses": {"damage": 15, "critical_chance": 10}
		},
		{
			"name": "Arcane Knowledge",
			"description": "Deep understanding of magical arts",
			"icon_name": "magic_book",
			"node_type": "IMPROVEMENT",
			"trait_id": -1,
			"skill_id": ability_id,
			"attribute_bonuses": {"mana": 20, "resistance": 15}
		},
		{
			"name": "Stealth Expert",
			"description": "Master of stealth and subterfuge",
			"icon_name": "monkey",
			"node_type": "PASSIVE",
			"trait_id": trait_id,
			"skill_id": -1,
			"attribute_bonuses": {"dodge": 20, "accuracy": 10}
		},
		{
			"name": "Leadership",
			"description": "Natural leader and commander",
			"icon_name": "giant",
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
			node.icon_name,
			node.node_type,
			node.trait_id,
			node.skill_id,
			node.attribute_bonuses,
			node.get("master_attribute_bonuses", {}),
			node.get("ability_bonuses", {})
		)
		
		if node_id > 0:
			print("Seeded node: ", node.name)
		else:
			print("Failed to seed node: ", node.name)
	
	print("Node seeding complete")

func seed_backgrounds():
	"""Seed the database with background data"""
	# Check if we already have background data
	var check_query = "SELECT COUNT(*) as count FROM backgrounds"
	db.query(check_query)
	var result = db.query_result
	
	if result.size() > 0 and result[0]["count"] > 0:
		print("Database already contains background data")
		return
	
	print("No existing background data found, seeding backgrounds...")
	
	# Define backgrounds data
	var backgrounds_data = [
		{
			"name": "Acolyte",
			"description": "Religious training and devotion to a higher power",
			"ability_bonuses": {"Persuasion": 1, "Knowledge": 1},
			"display_order": 1
		},
		{
			"name": "Criminal",
			"description": "Life of crime and street smarts",
			"ability_bonuses": {"Sleight of Hand": 1, "Stealth": 1},
			"display_order": 2
		},
		{
			"name": "Entertainer",
			"description": "Performance and artistic expression",
			"ability_bonuses": {"Persuasion": 1, "Athletics": 1},
			"display_order": 3
		},
		{
			"name": "Artisan",
			"description": "Skilled craftsmanship and trade",
			"ability_bonuses": {"Perception": 1, "Persuasion": 1},
			"display_order": 4
		},
		{
			"name": "Noble",
			"description": "High social status and education",
			"ability_bonuses": {"Knowledge": 1, "Arcana": 1},
			"display_order": 5
		},
		{
			"name": "Outlander",
			"description": "Life in the wilderness and survival",
			"ability_bonuses": {"Survival": 1, "Perception": 1},
			"display_order": 6
		},
		{
			"name": "Sage",
			"description": "Academic knowledge and research",
			"ability_bonuses": {"Knowledge": 1, "Arcana": 1},
			"display_order": 7
		},
		{
			"name": "Soldier",
			"description": "Military training and combat experience",
			"ability_bonuses": {"Athletics": 1, "Perception": 1},
			"display_order": 8
		}
	]
	
	for background in backgrounds_data:
		var json = JSON.new()
		var bonuses_json = json.stringify(background.ability_bonuses)
		
		var insert_query = """
		INSERT INTO backgrounds (name, description, ability_bonuses, display_order)
		VALUES ('%s', '%s', '%s', %d)
		""" % [
			background.name,
			background.description,
			bonuses_json,
			background.display_order
		]
		
		db.query(insert_query)
		if is_query_successful():
			print("Inserted background: " + background.name)
		else:
			print("Error inserting " + background.name + " background: " + db.error_message)
	
	print("Background seeding complete")

func seed_features():
	"""Seed the database with feature data"""
	# Check if we already have feature data
	var check_query = "SELECT COUNT(*) as count FROM features"
	db.query(check_query)
	var result = db.query_result
	
	if result.size() > 0 and result[0]["count"] > 0:
		print("Database already contains feature data")
		return
	
	print("No existing feature data found, seeding features...")
	
	# Define features data with 6 features
	var features_data = [
		{
			"name": "Force of Nature",
			"description": "Born with exceptional physical strength and resilience",
			"icon_name": "force_of_nature",
			"attribute_bonuses": {"Strength": 1, "Stamina": 1},
			"ability_bonuses": {"Athletics": 1},
			"skill_bonuses": {},
			"other_bonuses": {},
			"trait_id": 1,  # Polyvalent trait (Human trait)
			"display_order": 1
		},
		{
			"name": "Master Mind",
			"description": "Exceptional intelligence and analytical thinking",
			"icon_name": "master_mind",
			"attribute_bonuses": {"Intelligence": 2},
			"ability_bonuses": {"Knowledge": 1, "Arcana": 1},
			"skill_bonuses": {},
			"other_bonuses": {},
			"trait_id": null,  # No trait for this feature
			"display_order": 2
		},
		{
			"name": "Shadow Walker",
			"description": "Natural stealth and agility abilities",
			"icon_name": "shadow_walker",
			"attribute_bonuses": {"Agility": 1, "Resolution": 1},
			"ability_bonuses": {"Stealth": 1, "Sleight of Hand": 1},
			"skill_bonuses": {},
			"other_bonuses": {},
			"trait_id": null,  # No trait for this feature
			"display_order": 3
		},
		{
			"name": "Iron Will",
			"description": "Unbreakable mental fortitude and determination",
			"icon_name": "iron_will",
			"attribute_bonuses": {"Resolution": 2},
			"ability_bonuses": {"Intimidation": 1},
			"skill_bonuses": {},
			"other_bonuses": {},
			"trait_id": null,  # No trait for this feature
			"display_order": 4
		},
		{
			"name": "Mystic Touch",
			"description": "Natural affinity for magic and mystical energies",
			"icon_name": "mystic_touch",
			"attribute_bonuses": {"Essence": 2},
			"ability_bonuses": {"Arcana": 1, "Perception": 1},
			"skill_bonuses": {},
			"other_bonuses": {},
			"trait_id": null,  # No trait for this feature
			"display_order": 5
		},
		{
			"name": "Swift Reflexes",
			"description": "Lightning-fast reactions and coordination",
			"icon_name": "swift_reflexes",
			"attribute_bonuses": {"Agility": 1, "Intelligence": 1},
			"ability_bonuses": {"Acrobatics": 1, "Perception": 1},
			"skill_bonuses": {},
			"other_bonuses": {},
			"trait_id": null,  # No trait for this feature
			"display_order": 6
		}
	]
	
	for feature in features_data:
		var json = JSON.new()
		var attr_bonuses_json = json.stringify(feature.attribute_bonuses)
		var ability_bonuses_json = json.stringify(feature.ability_bonuses)
		var skill_bonuses_json = json.stringify(feature.skill_bonuses)
		var other_bonuses_json = json.stringify(feature.other_bonuses)
		
		var insert_query = """
		INSERT INTO features (name, description, icon_name, attribute_bonuses, ability_bonuses, skill_bonuses, other_bonuses, trait_id, display_order)
		VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s', %s, %d)
		""" % [
			feature.name,
			feature.description,
			feature.icon_name,
			attr_bonuses_json,
			ability_bonuses_json,
			skill_bonuses_json,
			other_bonuses_json,
			"NULL" if feature.trait_id == null else str(feature.trait_id),
			feature.display_order
		]
		
		db.query(insert_query)
		if is_query_successful():
			print("Inserted feature: " + feature.name)
		else:
			print("Error inserting " + feature.name + " feature: " + db.error_message)
	
	print("Feature seeding complete")

func seed_races_traits():
	"""Seed the races_traits join table with race-trait relationships"""
	# Check if we already have races_traits data
	var check_query = "SELECT COUNT(*) as count FROM races_traits"
	db.query(check_query)
	var result = db.query_result
	
	if result.size() > 0 and result[0]["count"] > 0:
		print("Database already contains races_traits data")
		return
	
	print("No existing races_traits data found, seeding race-trait relationships...")
	
	# Define race-trait relationships
	var race_trait_relationships = [
		{"race_name": "Human", "trait_name": "Polyvalent"},
		{"race_name": "Elf", "trait_name": "Ancient Wisdom"},
		{"race_name": "Celestial-blooded", "trait_name": "Divine Heritage"},
		{"race_name": "Infernal-blooded", "trait_name": "Infernal Power"}
	]
	
	for relationship in race_trait_relationships:
		# Get race ID
		var race_query = "SELECT id FROM races WHERE name = '%s'" % relationship.race_name
		db.query(race_query)
		var race_result = db.query_result
		
		# Get trait ID
		var trait_query = "SELECT id FROM traits WHERE name = '%s'" % relationship.trait_name
		db.query(trait_query)
		var trait_result = db.query_result
		
		if race_result.size() > 0 and trait_result.size() > 0:
			var race_id = race_result[0].id
			var trait_id = trait_result[0].id
			
			var insert_query = """
			INSERT INTO races_traits (race_id, trait_id)
			VALUES (%d, %d)
			""" % [race_id, trait_id]
			
			db.query(insert_query)
			if is_query_successful():
				print("Inserted race-trait relationship: %s - %s" % [relationship.race_name, relationship.trait_name])
			else:
				print("Error inserting race-trait relationship: " + db.error_message)
		else:
			print("Warning: Could not find race or trait for relationship: %s - %s" % [relationship.race_name, relationship.trait_name])
	
	print("Races_traits seeding complete")

func get_race_traits(race_name: String) -> Array:
	"""Get all traits for a specific race"""
	var query = """
	SELECT t.*
	FROM traits t
	JOIN races_traits rt ON t.id = rt.trait_id
	JOIN races r ON rt.race_id = r.id
	WHERE r.name = '%s'
	ORDER BY t.display_order
	""" % race_name
	
	db.query(query)
	
	if is_query_successful():
		var traits = []
		for trait_data in db.query_result:
			# Parse new trait fields
			if trait_data.point_bonuses:
				trait_data.point_bonuses_text = trait_data.point_bonuses
			else:
				trait_data.point_bonuses_text = ""
			
			if trait_data.attribute_scaling_bonuses:
				trait_data.attribute_scaling_bonuses_text = trait_data.attribute_scaling_bonuses
			else:
				trait_data.attribute_scaling_bonuses_text = ""
			
			if trait_data.master_attribute_scaling_bonuses:
				trait_data.master_attribute_scaling_bonuses_text = trait_data.master_attribute_scaling_bonuses
			else:
				trait_data.master_attribute_scaling_bonuses_text = ""
			
			if trait_data.others_bonuses:
				trait_data.others_bonuses_text = trait_data.others_bonuses
			else:
				trait_data.others_bonuses_text = ""
			
			traits.append(trait_data)
		
		print("Successfully fetched %d traits for race: %s" % [traits.size(), race_name])
		return traits
	else:
		print("Error fetching race traits: ", db.error_message)
		return []

func get_all_backgrounds():
	"""Get all backgrounds from the database"""
	var query = "SELECT * FROM backgrounds ORDER BY display_order"
	db.query(query)
	
	if is_query_successful():
		var backgrounds = []
		for background_data in db.query_result:
			# Parse JSON ability bonuses
			if background_data.ability_bonuses:
				var json = JSON.new()
				if json.parse(background_data.ability_bonuses) == OK:
					background_data.ability_bonuses_dict = json.data
				else:
					background_data.ability_bonuses_dict = {}
			else:
				background_data.ability_bonuses_dict = {}
			
			backgrounds.append(background_data)
		
			print("Successfully fetched %d backgrounds from database" % backgrounds.size())
		return backgrounds
	else:
		print("Error fetching backgrounds: ", db.error_message)
		return []

func get_all_features():
	"""Get all features from the database"""
	var query = """
	SELECT f.*, t.name as trait_name, t.description as trait_description, t.icon_name as trait_icon_name
	FROM features f
	LEFT JOIN traits t ON f.trait_id = t.id
	ORDER BY f.display_order
	"""
	db.query(query)
	
	if is_query_successful():
		var features = []
		for feature_data in db.query_result:
			# Parse JSON bonuses
			if feature_data.attribute_bonuses:
				var json = JSON.new()
				if json.parse(feature_data.attribute_bonuses) == OK:
					feature_data.attribute_bonuses_dict = json.data
				else:
					feature_data.attribute_bonuses_dict = {}
			else:
				feature_data.attribute_bonuses_dict = {}
			
			if feature_data.ability_bonuses:
				var json = JSON.new()
				if json.parse(feature_data.ability_bonuses) == OK:
					feature_data.ability_bonuses_dict = json.data
				else:
					feature_data.ability_bonuses_dict = {}
			else:
				feature_data.ability_bonuses_dict = {}
			
			if feature_data.skill_bonuses:
				var json = JSON.new()
				if json.parse(feature_data.skill_bonuses) == OK:
					feature_data.skill_bonuses_dict = json.data
				else:
					feature_data.skill_bonuses_dict = {}
			else:
				feature_data.skill_bonuses_dict = {}
			
			if feature_data.other_bonuses:
				var json = JSON.new()
				if json.parse(feature_data.other_bonuses) == OK:
					feature_data.other_bonuses_dict = json.data
				else:
					feature_data.other_bonuses_dict = {}
			else:
				feature_data.other_bonuses_dict = {}
			
			# Add trait information
			if feature_data.trait_id and feature_data.trait_name:
				feature_data.has_trait = true
				feature_data.trait_data = {
					"name": feature_data.trait_name,
					"description": feature_data.trait_description,
					"icon_name": feature_data.trait_icon_name
				}
			else:
				feature_data.has_trait = false
				feature_data.trait_data = {}
			
			features.append(feature_data)
		
		print("Successfully fetched %d features from database" % features.size())
		return features
	else:
		print("Error fetching features: ", db.error_message)
		return []

func get_all_personalities():
	"""Get all personalities from the database"""
	var query = "SELECT * FROM personalities ORDER BY display_order"
	db.query(query)
	
	if is_query_successful():
		var personalities = []
		for personality_data in db.query_result:
			personalities.append(personality_data)
		
		print("Successfully fetched %d personalities from database" % personalities.size())
		return personalities
	else:
		print("Error fetching personalities: ", db.error_message)
		return []

func get_personality_by_name(personality_name: String):
	"""Get a personality by name"""
	var query = "SELECT * FROM personalities WHERE name = ?"
	var params = [personality_name]
	db.query_with_bindings(query, params)
	var result = db.query_result
	
	if result.size() > 0:
		return result[0]
	else:
		return null

# Clear functions for data seeder tool
func clear_nodes():
	"""Clear all nodes from the database"""
	var query = "DELETE FROM nodes"
	db.query(query)
	
	if is_query_successful():
		print("Successfully cleared all nodes from database")
		# Reset auto-increment counter
		db.query("DELETE FROM sqlite_sequence WHERE name='nodes'")
	else:
		print("Error clearing nodes: ", db.error_message)

func clear_traits():
	"""Clear all traits from the database"""
	var query = "DELETE FROM traits"
	db.query(query)
	
	if is_query_successful():
		print("Successfully cleared all traits from database")
		# Reset auto-increment counter
		db.query("DELETE FROM sqlite_sequence WHERE name='traits'")
	else:
		print("Error clearing traits: ", db.error_message)

func clear_backgrounds():
	"""Clear all backgrounds from the database"""
	var query = "DELETE FROM backgrounds"
	db.query(query)
	
	if is_query_successful():
		print("Successfully cleared all backgrounds from database")
		# Reset auto-increment counter
		db.query("DELETE FROM sqlite_sequence WHERE name='backgrounds'")
	else:
		print("Error clearing backgrounds: ", db.error_message)

func clear_features():
	"""Clear all features from the database"""
	var query = "DELETE FROM features"
	db.query(query)
	
	if is_query_successful():
		print("Successfully cleared all features from database")
		# Reset auto-increment counter
		db.query("DELETE FROM sqlite_sequence WHERE name='features'")
	else:
		print("Error clearing features: ", db.error_message)

# Create functions for data seeder tool
func create_node(node_data: Dictionary) -> bool:
	"""Create a new node in the database"""
	var query = """
	INSERT INTO nodes (name, description, icon_name, node_type, trait_id, skill_id, attribute_bonuses, master_attribute_bonuses, ability_bonuses)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
	"""
	
	var params = [
		node_data.name,
		node_data.description,
		node_data.icon_name,
		node_data.node_type,
		node_data.trait_id,
		node_data.skill_id,
		JSON.stringify(node_data.attribute_bonuses) if node_data.attribute_bonuses else "{}",
		JSON.stringify(node_data.master_attribute_bonuses) if node_data.master_attribute_bonuses else "{}",
		JSON.stringify(node_data.ability_bonuses) if node_data.ability_bonuses else "{}"
	]
	
	db.query_with_bindings(query, params)
	
	if is_query_successful():
		print("Successfully created node: ", node_data.name)
		return true
	else:
		print("Error creating node: ", db.error_message)
		return false

func create_trait(trait_data: Dictionary) -> bool:
	"""Create a new trait in the database"""
	var query = """
	INSERT INTO traits (name, description, icon_name, point_bonuses, attribute_scaling_bonuses, master_attribute_scaling_bonuses, others_bonuses, display_order)
	VALUES (?, ?, ?, ?, ?, ?, ?, 0)
	"""
	
	var params = [
		trait_data.name,
		trait_data.description if trait_data.has("description") else "",
		trait_data.icon_name if trait_data.has("icon_name") else "",
		trait_data.point_bonuses if trait_data.has("point_bonuses") else "",
		trait_data.attribute_scaling_bonuses if trait_data.has("attribute_scaling_bonuses") else "",
		trait_data.master_attribute_scaling_bonuses if trait_data.has("master_attribute_scaling_bonuses") else "",
		trait_data.others_bonuses if trait_data.has("others_bonuses") else ""
	]
	
	db.query_with_bindings(query, params)
	
	if is_query_successful():
		print("Successfully created trait: ", trait_data.name)
		return true
	else:
		print("Error creating trait: ", db.error_message)
		return false

func create_background(background_data: Dictionary) -> bool:
	"""Create a new background in the database"""
	var query = """
	INSERT INTO backgrounds (name, description, attribute_bonuses, ability_bonuses, skill_bonuses, starting_equipment, display_order)
	VALUES (?, ?, ?, ?, ?, ?, 0)
	"""
	
	var params = [
		background_data.name,
		background_data.description,
		JSON.stringify(background_data.attribute_bonuses) if background_data.attribute_bonuses else "{}",
		JSON.stringify(background_data.ability_bonuses) if background_data.ability_bonuses else "{}",
		JSON.stringify(background_data.skill_bonuses) if background_data.skill_bonuses else "{}",
		background_data.starting_equipment if background_data.has("starting_equipment") else ""
	]
	
	db.query_with_bindings(query, params)
	
	if is_query_successful():
		print("Successfully created background: ", background_data.name)
		return true
	else:
		print("Error creating background: ", db.error_message)
		return false

func create_feature(feature_data: Dictionary) -> bool:
	"""Create a new feature in the database"""
	var query = """
	INSERT INTO features (name, description, icon_name, trait_id, attribute_bonuses, ability_bonuses, skill_bonuses, other_bonuses, display_order)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)
	"""
	
	var params = [
		feature_data.name,
		feature_data.description,
		feature_data.icon_name,
		feature_data.trait_id,
		JSON.stringify(feature_data.attribute_bonuses) if feature_data.attribute_bonuses else "{}",
		JSON.stringify(feature_data.ability_bonuses) if feature_data.ability_bonuses else "{}",
		JSON.stringify(feature_data.skill_bonuses) if feature_data.skill_bonuses else "{}",
		feature_data.other_bonuses if feature_data.has("other_bonuses") else ""
	]
	
	db.query_with_bindings(query, params)
	
	if is_query_successful():
		print("Successfully created feature: ", feature_data.name)
		return true
	else:
		print("Error creating feature: ", db.error_message)
		return false

func create_race(race_data: Dictionary) -> bool:
	"""Create a new race in the database"""
	var query = """
	INSERT INTO races (name, description, attribute_bonuses, display_order)
	VALUES (?, ?, ?, 0)
	"""
	
	var params = [
		race_data.name,
		race_data.description,
		JSON.stringify(race_data.attribute_bonuses) if race_data.has("attribute_bonuses") else "{}"
	]
	
	db.query_with_bindings(query, params)
	
	if is_query_successful():
		print("Successfully created race: ", race_data.name)
		# Handle traits if provided
		if race_data.has("traits") and race_data.traits != null and race_data.traits != "":
			handle_race_traits(race_data.name, race_data.traits)
		return true
	else:
		print("Error creating race: ", db.error_message)
		return false

func create_personality(personality_data: Dictionary) -> bool:
	"""Create a new personality in the database"""
	var query = """
	INSERT INTO personalities (name, description, display_order)
	VALUES (?, ?, 0)
	"""
	
	var params = [
		personality_data.name,
		personality_data.description
	]
	
	db.query_with_bindings(query, params)
	
	if is_query_successful():
		print("Successfully created personality: ", personality_data.name)
		return true
	else:
		print("Error creating personality: ", db.error_message)
		return false

func clear_races():
	"""Clear all races from the database"""
	var query = "DELETE FROM races"
	db.query(query)
	if is_query_successful():
		print("Races cleared successfully")
	else:
		print("Error clearing races: ", db.error_message)

func clear_personalities():
	"""Clear all personalities from the database"""
	var query = "DELETE FROM personalities"
	db.query(query)
	if is_query_successful():
		print("Personalities cleared successfully")
	else:
		print("Error clearing personalities: ", db.error_message)

func handle_race_traits(race_name: String, traits_string: String):
	"""Handle race traits by parsing comma-separated trait names and creating associations"""
	if traits_string == null or traits_string == "":
		print("DEBUG: No traits string for race: ", race_name)
		return
	
	print("DEBUG: Processing traits for race '%s': '%s'" % [race_name, traits_string])
	
	# Get race ID
	var race = get_race_by_name(race_name)
	if not race:
		print("ERROR: Race not found for traits: ", race_name)
		return
	
	var race_id = race.id
	var trait_names = traits_string.split(",")
	print("DEBUG: Split trait names: ", trait_names)
	
	for trait_name in trait_names:
		trait_name = trait_name.strip_edges()
		print("DEBUG: Looking for trait: '%s'" % trait_name)
		if trait_name != "":
			var traitv = get_trait_by_name(trait_name)
			if traitv:
				# Create race-trait association
				var query = "INSERT OR IGNORE INTO races_traits (race_id, trait_id) VALUES (?, ?)"
				var params = [race_id, traitv.id]
				db.query_with_bindings(query, params)
				if is_query_successful():
					print("Associated trait '", trait_name, "' with race '", race_name, "'")
				else:
					print("Error associating trait '", trait_name, "' with race '", race_name, "': ", db.error_message)
			else:
				print("WARNING: Trait not found for race association: ", trait_name)
