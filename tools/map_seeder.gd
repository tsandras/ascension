extends Node

# CSV file paths
var maps_csv_path = "res://tools/data/ref_map.csv"
var tiles_csv_path = "res://tools/data/ref_tile.csv"
var map_tiles_csv_path = "res://tools/data/ref_map_tile.csv"
var overlays_csv_path = "res://tools/data/overlays.csv"
var abilities_csv_path = "res://tools/data/abilities.csv"


# Database manager reference
var database_manager: Node

func _ready():
	print("=== MAP SEEDER TOOL ===")
	
	# Get database manager reference
	database_manager = get_node("/root/DatabaseManager")
	if not database_manager:
		print("ERROR: DatabaseManager not found!")
		return
	
	# Create tools directory if it doesn't exist
	create_tools_directory()
	
	# Create sample CSV files if they don't exist
	create_sample_csv_files()
	
	print("Map Seeder Tool initialized")
	print("CSV files:")
	print("  Maps: ", maps_csv_path)
	print("  Tiles: ", tiles_csv_path)
	print("  Map Tiles: ", map_tiles_csv_path)
	print("  Abilities: ", abilities_csv_path)


func create_tools_directory():
	"""Create the tools directory structure"""
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("tools"):
		dir.make_dir("tools")
		print("Created tools directory")
	
	if not dir.dir_exists("tools/data"):
		dir.make_dir("tools/data")
		print("Created tools/data directory")

func create_sample_csv_files():
	"""Create sample CSV files if they don't exist"""
	if not FileAccess.file_exists(maps_csv_path):
		create_sample_maps_csv()
	else:
		print("Maps CSV already exists: ", maps_csv_path)
	
	if not FileAccess.file_exists(tiles_csv_path):
		create_sample_tiles_csv()
	else:
		print("Tiles CSV already exists: ", tiles_csv_path)
	
	if not FileAccess.file_exists(overlays_csv_path):
		create_sample_overlays_csv()
	else:
		print("Overlays CSV already exists: ", overlays_csv_path)
	
	if not FileAccess.file_exists(map_tiles_csv_path):
		create_sample_map_tiles_csv()
	else:
		print("Map tiles CSV already exists: ", map_tiles_csv_path)
	
	if not FileAccess.file_exists(abilities_csv_path):
		create_sample_abilities_csv()
	else:
		print("Abilities CSV already exists: ", abilities_csv_path)
	


func force_create_sample_csv_files():
	"""Force create sample CSV files (overwrites existing files)"""
	print("Force creating sample CSV files...")
	create_sample_maps_csv()
	create_sample_tiles_csv()
	create_sample_overlays_csv()
	create_sample_map_tiles_csv()
	create_sample_abilities_csv()
	print("Sample CSV files recreated")

func create_sample_maps_csv():
	"""Create a sample maps CSV file"""
	var file = FileAccess.open(maps_csv_path, FileAccess.WRITE)
	if file:
		# CSV header
		file.store_line("name,width,height,description,starting_tileset_x,starting_tileset_y")
		# Sample data
		file.store_line("Simple Map Test,9,9,A diverse world with forests, mountains, arid lands, and varied terrain in a 9x9 grid,0,0")
		file.store_line("Tutorial Forest,20,15,A small forest area perfect for learning the basics,0,0")
		file.store_line("Ancient Ruins,30,25,Mysterious ruins filled with secrets and danger,0,0")
		file.store_line("Crystal Caves,25,20,Underground caverns with magical crystal formations,0,0")
		file.close()
		print("Created sample maps CSV file")
	else:
		print("ERROR: Could not create maps CSV file")

func create_sample_tiles_csv():
	"""Create a sample tiles CSV file"""
	var file = FileAccess.open(tiles_csv_path, FileAccess.WRITE)
	if file:
		# CSV header
		file.store_line("type_name,initials,is_walkable,is_top_blocked,is_bottom_blocked,is_middle_blocked,time_to_cross,description")
		# Sample data
		file.store_line("forest,F,true,false,false,false,1,Dense forest with trees")
		file.store_line("mountain,M,false,true,true,true,999,Tall impassable mountains")
		file.store_line("green_mountain,N,false,true,true,true,999,Forested mountains")
		file.store_line("grassland,G,true,false,false,false,1,Open grassland plains")
		file.store_line("empty_grassland,E,true,false,false,false,1,Empty green fields")
		file.store_line("arid_varap,A,true,false,false,false,2,Arid wasteland with sparse vegetation")
		file.store_line("glade,V,true,false,false,false,1,Peaceful forest glade")
		file.store_line("cliff,C,false,true,true,true,2,Steep rocky cliffs")
		file.store_line("ruins,R,false,true,true,true,1,Ruins of a long-lost civilization")
		file.store_line("settlement,S,true,false,false,false,1,Settlement with buildings and people")
		file.store_line("left_sea,LS,false,true,true,true,999,Left sea")
		file.store_line("right_sea,RS,false,true,true,true,999,Right sea")
		file.store_line("top_sea,TS,false,true,true,true,999,Top sea")
		file.store_line("bottom_sea,BS,false,true,true,true,999,Bottom sea")
		file.close()
		print("Created sample tiles CSV file")
	else:
		print("ERROR: Could not create tiles CSV file")

func create_sample_map_tiles_csv():
	"""Create a sample map tiles CSV file in grid format with overlay codes"""
	var file = FileAccess.open(map_tiles_csv_path, FileAccess.WRITE)
	if file:
		# Create a 9x9 grid format where each cell is a tile initial with optional overlay codes
		# Format: "G" = grassland, "G1" = grassland with overlay 1, "G1-R1" = grassland with overlays 1 and R1
		# F=forest, M=mountain, G=grassland, E=empty_grassland, A=arid_varap, V=glade, C=cliff, N=green_mountain
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
		
		# Add some overlay codes to demonstrate the format
		# G1-R1 means grassland with overlay R1
		# G1-R1-S1 means grassland with overlays R1 and S1
		terrain_map[1] = ["G1", "G1-R1", "G1-R1-S1", "F", "F", "F", "G", "G", "G"]
		terrain_map[3] = ["F", "F", "F", "V1", "A", "A", "A", "C", "M"]
		terrain_map[5] = ["F", "G1-S1", "G", "A", "A", "V", "V", "N", "G"]
		
		# Write each row as a comma-separated line
		for row in terrain_map:
			var line = ""
			for i in range(row.size()):
				if i > 0:
					line += ","
				line += row[i]
			file.store_line(line)
		
		file.close()
		print("Created sample map tiles CSV file in grid format with overlay codes")
	else:
		print("ERROR: Could not create map tiles CSV file")

func create_sample_abilities_csv():
	"""Create a sample abilities CSV file"""
	var file = FileAccess.open(abilities_csv_path, FileAccess.WRITE)
	if file:
		# CSV header
		file.store_line("name,base_value,max_value,display_order,description")
		# Sample data
		file.store_line("Scoundrel,0,6,1,Sneaking, thievery, and cunning")
		file.store_line("Warrior,0,6,2,One-handed weapon mastery")
		file.store_line("Berserker,0,6,3,Two-handed weapon expertise")
		file.store_line("Ranger,0,6,4,Bows, crossbows, and throwing weapons")
		file.store_line("Juggernaut,0,6,5,Defensive and armor mastery")
		file.store_line("Tactician,0,6,6,Battlefield strategy")
		file.store_line("Pyromancer,0,6,7,Destructive fire spells and pyromancy")
		file.store_line("Aeromancer,0,6,8,Destructive air spells and aeromancy")
		file.store_line("Hydromancer,0,6,9,Destructive water spells and hydromancy")
		file.store_line("Lithomancer,0,6,10,Destructive earth spells and lithomancy")
		file.store_line("Arcanist,0,6,11,Pure magical energy manipulation")
		file.store_line("Bloodmage,0,6,12,Dark magic using life force")
		file.close()
		print("Created sample abilities CSV file")
	else:
		print("ERROR: Could not create abilities CSV file")



func create_sample_overlays_csv():
	"""Create a sample overlays CSV file"""
	var file = FileAccess.open(overlays_csv_path, FileAccess.WRITE)
	if file:
		# CSV header
		file.store_line("name,initials,texture_path,description,display_order")
		# Sample data based on existing overlay files with initials
		file.store_line("Desert Landmark 1,D1,res://assets/overlays/landmark_desert_1.png,A mysterious desert landmark,1")
		file.store_line("Desert Landmark 2,D2,res://assets/overlays/landmark_desert_2.png,An ancient desert structure,2")
		file.store_line("Desert Landmark 4,D4,res://assets/overlays/landmark_desert_4.png,A weathered desert monument,3")
		file.store_line("Desert Landmark 7,D7,res://assets/overlays/landmark_desert_7.png,A hidden desert oasis,4")
		file.store_line("Desert Landmark 9,D9,res://assets/overlays/landmark_desert_9.png,A grand desert temple,5")
		file.store_line("Sample Landmark 1,S1,res://assets/overlays/landmark_sample_1.png,A mysterious landmark,6")
		file.store_line("Sample Landmark 4,S4,res://assets/overlays/landmark_sample_4.png,An ancient structure,7")
		file.store_line("Sample Landmark 5,S5,res://assets/overlays/landmark_sample_5.png,A weathered monument,8")
		file.close()
		print("Created sample overlays CSV file")
	else:
		print("ERROR: Could not create overlays CSV file")

func generate_texture_path(type_name: String) -> String:
	"""Generate texture path based on tile type name"""
	return "res://assets/tiles/tilev3_" + type_name + ".png"

func extract_tile_initial(cell_content: String) -> String:
	"""Extract tile initial from cell content (e.g., 'G1-R1' -> 'G1')"""
	if cell_content.is_empty():
		return ""
	
	# Split by '-' to get the tile part (first part)
	var parts = cell_content.split("-")
	return parts[0]

func extract_overlay_codes(cell_content: String) -> Array:
	"""Extract overlay codes from cell content (e.g., 'G1-R1-S1' -> ['R1', 'S1'])"""
	var codes = []
	
	if cell_content.is_empty():
		return codes
	
	# Split by '-' to get all parts
	var parts = cell_content.split("-")
	
	# Skip the first part (tile initial) and collect overlay codes
	for i in range(1, parts.size()):
		var code = parts[i]
		if not code.is_empty():
			codes.append(code)
	
	return codes

func read_csv_file(file_path: String) -> Array:
	"""Read a CSV file and return an array of dictionaries"""
	var data = []
	
	if not FileAccess.file_exists(file_path):
		print("ERROR: CSV file not found: ", file_path)
		return data
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("ERROR: Could not open CSV file: ", file_path)
		return data
	
	# Read header line
	var header_line = file.get_line()
	var headers = header_line.split(",")
	
	# Read data lines
	while not file.eof_reached():
		var line = file.get_line()
		if line.strip_edges() == "":
			continue
		
		var values = line.split(",")
		var row = {}
		
		for i in range(headers.size()):
			if i < values.size():
				row[headers[i].strip_edges()] = values[i].strip_edges()
			else:
				row[headers[i].strip_edges()] = ""
		
		data.append(row)
	
	file.close()
	return data

func seed_maps_from_csv():
	"""Seed maps from CSV file"""
	print("=== SEEDING MAPS FROM CSV ===")
	
	var maps_data = read_csv_file(maps_csv_path)
	if maps_data.size() == 0:
		print("No maps data found in CSV")
		return
	
	# Clear existing ref_map data
	var clear_query = "DELETE FROM ref_map"
	database_manager.db.query(clear_query)
	if not database_manager.is_query_successful():
		print("Error clearing ref_map data: " + database_manager.db.error_message)
		return
	print("Cleared existing ref_map data")
	
	# Insert maps from CSV
	for map_data in maps_data:
		var insert_query = """
		INSERT INTO ref_map (name, width, height, description, starting_tileset_x, starting_tileset_y)
		VALUES ('%s', %d, %d, '%s', %d, %d)
		""" % [map_data.name, int(map_data.width), int(map_data.height), map_data.description, int(map_data.get("starting_tileset_x", 0)), int(map_data.get("starting_tileset_y", 0))]
		
		database_manager.db.query(insert_query)
		if database_manager.is_query_successful():
			print("Inserted map: ", map_data.name)
		else:
			print("Error inserting map " + map_data.name + ": " + database_manager.db.error_message)
	
	print("Maps seeding complete")

func seed_tiles_from_csv():
	"""Seed tiles from CSV file"""
	print("=== SEEDING TILES FROM CSV ===")
	
	var tiles_data = read_csv_file(tiles_csv_path)
	if tiles_data.size() == 0:
		print("No tiles data found in CSV")
		return
	
	# Clear existing ref_tile data
	var clear_query = "DELETE FROM ref_tile"
	database_manager.db.query(clear_query)
	if not database_manager.is_query_successful():
		print("Error clearing ref_tile data: " + database_manager.db.error_message)
		return
	print("Cleared existing ref_tile data")
	
	# Insert tiles from CSV
	for tile_data in tiles_data:
		# Generate texture path automatically
		var texture_path = generate_texture_path(tile_data.type_name)
		
		var insert_query = """
		INSERT INTO ref_tile (type_name, initials, is_walkable, is_top_blocked, is_bottom_blocked, is_middle_blocked, time_to_cross, texture_path, tileset_x, tileset_y, description, extra_content)
		VALUES ('%s', '%s', %s, %s, %s, %s, %d, '%s', %d, %d, '%s', '{}')
		""" % [
			tile_data.type_name, 
			tile_data.initials,
			str(tile_data.is_walkable).to_lower(),
			str(tile_data.get("is_top_blocked", "false")).to_lower(),
			str(tile_data.get("is_bottom_blocked", "false")).to_lower(),
			str(tile_data.get("is_middle_blocked", "false")).to_lower(),
			int(tile_data.get("time_to_cross", 1)), 
			texture_path, 
			0, 0,
			tile_data.description
		]
		
		database_manager.db.query(insert_query)
		if database_manager.is_query_successful():
			print("Inserted tile: ", tile_data.type_name)
		else:
			print("Error inserting tile " + tile_data.type_name + ": " + database_manager.db.error_message)
	
	print("Tiles seeding complete")

func read_grid_csv_file(file_path: String) -> Array:
	"""Read a grid format CSV file and return a 2D array"""
	var grid_data = []
	
	if not FileAccess.file_exists(file_path):
		print("ERROR: Grid CSV file not found: ", file_path)
		return grid_data
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("ERROR: Could not open grid CSV file: ", file_path)
		return grid_data
	
	# Read each line as a row
	while not file.eof_reached():
		var line = file.get_line()
		if line.strip_edges() == "":
			continue
		
		# Split the line by commas to get each cell
		var row = line.split(",")
		var clean_row = []
		for cell in row:
			clean_row.append(cell.strip_edges())
		
		grid_data.append(clean_row)
	
	file.close()
	return grid_data

func seed_map_tiles_from_csv():
	"""Seed map tiles from CSV file in grid format with overlay codes"""
	print("=== SEEDING MAP TILES FROM CSV ===")
	
	# Read the grid format CSV file
	var grid_data = read_grid_csv_file(map_tiles_csv_path)
	if grid_data.size() == 0:
		print("No map tiles data found in CSV")
		return
	
	print("Grid size: %d rows x %d columns" % [grid_data.size(), grid_data[0].size() if grid_data.size() > 0 else 0])
	
	# Clear existing ref_map_tile data
	var clear_query = "DELETE FROM ref_map_tile"
	database_manager.db.query(clear_query)
	if not database_manager.is_query_successful():
		print("Error clearing ref_map_tile data: " + database_manager.db.error_message)
		return
	print("Cleared existing ref_map_tile data")
	
	# Get the first map (assuming single map for now)
	var map_query = "SELECT id FROM ref_map ORDER BY id LIMIT 1"
	database_manager.db.query(map_query)
	if not database_manager.is_query_successful() or database_manager.db.query_result.size() == 0:
		print("Error: No maps found in database")
		return
	
	var ref_map_id = database_manager.db.query_result[0]["id"]
	print("Using ref_map_id: " + str(ref_map_id))
	
	# Get all tile IDs for the initials we'll encounter
	var tile_ids = {}
	var all_initials = []
	
	# Collect all unique initials from the grid
	for y in range(grid_data.size()):
		for x in range(grid_data[y].size()):
			var cell_content = grid_data[y][x]
			var initial = extract_tile_initial(cell_content)
			if not all_initials.has(initial):
				all_initials.append(initial)
	
	print("Found initials in grid: ", all_initials)
	
	# Get tile IDs for each initial
	for initial in all_initials:
		var tile_query = "SELECT id FROM ref_tile WHERE initials = '%s'" % initial
		database_manager.db.query(tile_query)
		if not database_manager.is_query_successful() or database_manager.db.query_result.size() == 0:
			print("Warning: Tile initial '" + initial + "' not found in database")
			continue
		tile_ids[initial] = database_manager.db.query_result[0]["id"]
		print("Found tile ID %d for initial %s" % [tile_ids[initial], initial])
	
	# Get all overlay IDs for overlay codes
	var overlay_ids = {}
	var all_overlay_codes = []
	
	# Collect all unique overlay codes from the grid
	for y in range(grid_data.size()):
		for x in range(grid_data[y].size()):
			var cell_content = grid_data[y][x]
			var overlay_codes = extract_overlay_codes(cell_content)
			for code in overlay_codes:
				if not all_overlay_codes.has(code):
					all_overlay_codes.append(code)
	
	print("Found overlay codes in grid: ", all_overlay_codes)
	
	# Get overlay IDs for each overlay code
	for code in all_overlay_codes:
		var overlay_query = "SELECT id FROM ref_overlay WHERE initials = '%s'" % code
		database_manager.db.query(overlay_query)
		if not database_manager.is_query_successful() or database_manager.db.query_result.size() == 0:
			print("Warning: Overlay code '" + code + "' not found in database")
			continue
		overlay_ids[code] = database_manager.db.query_result[0]["id"]
		print("Found overlay ID %d for code %s" % [overlay_ids[code], code])
	
	# Insert map tiles from grid
	var inserted_count = 0
	for y in range(grid_data.size()):
		for x in range(grid_data[y].size()):
			var cell_content = grid_data[y][x]
			var initial = extract_tile_initial(cell_content)
			var tile_id = tile_ids.get(initial)
			
			# Debug: Print cell processing
			print("Processing cell at (%d, %d): '%s' -> initial: '%s', tile_id: %s" % [x, y, cell_content, initial, tile_id])
			
			if tile_id:
				# Parse overlay codes
				var overlay_codes = extract_overlay_codes(cell_content)
				var first_overlay_id = null
				var second_overlay_id = null
				
				if overlay_codes.size() > 0:
					first_overlay_id = overlay_ids.get(overlay_codes[0])
				if overlay_codes.size() > 1:
					second_overlay_id = overlay_ids.get(overlay_codes[1])
				
				# Build insert query with overlay fields
				var insert_query = """
				INSERT INTO ref_map_tile (ref_map_id, ref_tile_id, x, y, first_overlay_id, second_overlay_id)
				VALUES (%d, %d, %d, %d, %s, %s)
				""" % [
					ref_map_id, 
					tile_id, 
					x, 
					y,
					"NULL" if first_overlay_id == null else str(first_overlay_id),
					"NULL" if second_overlay_id == null else str(second_overlay_id)
				]
				
				database_manager.db.query(insert_query)
				if database_manager.is_query_successful():
					inserted_count += 1
					if inserted_count % 10 == 0:  # Print every 10th insertion to avoid spam
						print("Placed tile with initial %s at (%d, %d)" % [initial, x, y])
				else:
					print("Error creating ref_map_tile at (%d, %d): %s" % [x, y, database_manager.db.error_message])
			else:
				print("Warning: No tile found for initial '%s' at (%d, %d)" % [initial, x, y])
	
	print("Map tiles seeding complete. Inserted %d tiles." % inserted_count)

func seed_abilities_from_csv():
	"""Seed abilities from CSV file"""
	print("=== SEEDING ABILITIES FROM CSV ===")
	
	var abilities_data = read_csv_file(abilities_csv_path)
	if abilities_data.size() == 0:
		print("No abilities data found in CSV")
		return
	
	# Clear existing abilities data
	var clear_query = "DELETE FROM abilities"
	database_manager.db.query(clear_query)
	if not database_manager.is_query_successful():
		print("Error clearing abilities data: " + database_manager.db.error_message)
		return
	print("Cleared existing abilities data")
	
	# Insert abilities from CSV
	for ability_data in abilities_data:
		var insert_query = """
		INSERT INTO abilities (name, base_value, max_value, display_order, description)
		VALUES ('%s', %d, %d, %d, '%s')
		""" % [ability_data.name, int(ability_data.base_value), int(ability_data.max_value), int(ability_data.display_order), ability_data.description]
		
		database_manager.db.query(insert_query)
		if database_manager.is_query_successful():
			print("Inserted ability: ", ability_data.name)
		else:
			print("Error inserting ability " + ability_data.name + ": " + database_manager.db.error_message)
	
	print("Abilities seeding complete")


	


func seed_overlays_from_csv():
	"""Seed overlays from CSV file"""
	print("=== SEEDING OVERLAYS FROM CSV ===")
	
	# Clear existing overlays data
	var clear_query = "DELETE FROM ref_overlay"
	database_manager.db.query(clear_query)
	if not database_manager.is_query_successful():
		print("Error clearing overlays data: " + database_manager.db.error_message)
		return
	print("Cleared existing overlays data")
	
	# Read CSV file
	var overlays_data = read_csv_file(overlays_csv_path)
	if overlays_data.size() == 0:
		print("No overlays data found in CSV")
		return
	
	# Insert overlays
	for overlay_data in overlays_data:
		var insert_query = """
		INSERT INTO ref_overlay (name, initials, texture_path, description, display_order)
		VALUES ('%s', '%s', '%s', '%s', %d)
		""" % [
			overlay_data.get("name", ""),
			overlay_data.get("initials", ""),
			overlay_data.get("texture_path", ""),
			overlay_data.get("description", ""),
			int(overlay_data.get("display_order", 0))
		]
		
		database_manager.db.query(insert_query)
		if database_manager.is_query_successful():
			print("Inserted overlay: ", overlay_data.get("name", ""))
		else:
			print("Error inserting overlay " + overlay_data.get("name", "") + ": " + database_manager.db.error_message)
	
	print("Overlays seeding complete")

func clear_all_map_data():
	"""Clear all map-related data from database"""
	print("=== CLEARING ALL MAP DATA ===")
	
	# Clear in correct order to avoid foreign key constraint issues
	var clear_map_tiles = "DELETE FROM ref_map_tile"
	database_manager.db.query(clear_map_tiles)
	print("Cleared ref_map_tile data")
	
	var clear_tiles = "DELETE FROM ref_tile"
	database_manager.db.query(clear_tiles)
	print("Cleared ref_tile data")
	
	var clear_overlays = "DELETE FROM ref_overlay"
	database_manager.db.query(clear_overlays)
	print("Cleared overlay data")
	
	var clear_maps = "DELETE FROM ref_map"
	database_manager.db.query(clear_maps)
	print("Cleared ref_map data")
	
	print("=== ALL MAP DATA CLEARED ===")

func seed_all_from_csv():
	"""Seed all data from CSV files"""
	print("=== SEEDING ALL DATA FROM CSV FILES ===")
	
	# Clear all existing data first
	clear_all_map_data()
	
	seed_maps_from_csv()
	seed_tiles_from_csv()
	seed_overlays_from_csv()
	seed_map_tiles_from_csv()
	seed_abilities_from_csv()
	
	print("=== ALL SEEDING COMPLETE ===")
