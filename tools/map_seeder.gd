extends Node

# CSV file paths
var maps_csv_path = "res://tools/data/ref_map.csv"
var tiles_csv_path = "res://tools/data/ref_tile.csv"
var map_tiles_csv_path = "res://tools/data/ref_map_tile.csv"

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
	
	if not FileAccess.file_exists(map_tiles_csv_path):
		create_sample_map_tiles_csv()
	else:
		print("Map tiles CSV already exists: ", map_tiles_csv_path)

func force_create_sample_csv_files():
	"""Force create sample CSV files (overwrites existing files)"""
	print("Force creating sample CSV files...")
	create_sample_maps_csv()
	create_sample_tiles_csv()
	create_sample_map_tiles_csv()
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
	"""Create a sample map tiles CSV file in grid format"""
	var file = FileAccess.open(map_tiles_csv_path, FileAccess.WRITE)
	if file:
		# Create a 9x9 grid format where each cell is a tile initial
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
		
		# Write each row as a comma-separated line
		for row in terrain_map:
			var line = ""
			for i in range(row.size()):
				if i > 0:
					line += ","
				line += row[i]
			file.store_line(line)
		
		file.close()
		print("Created sample map tiles CSV file in grid format")
	else:
		print("ERROR: Could not create map tiles CSV file")

func generate_texture_path(type_name: String) -> String:
	"""Generate texture path based on tile type name"""
	return "res://assets/tiles/tilev3_" + type_name + ".png"

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
	"""Seed map tiles from CSV file in grid format"""
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
			var initial = grid_data[y][x]
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
	
	# Insert map tiles from grid
	var inserted_count = 0
	for y in range(grid_data.size()):
		for x in range(grid_data[y].size()):
			var initial = grid_data[y][x]
			var tile_id = tile_ids.get(initial)
			
			if tile_id:
				var insert_query = """
				INSERT INTO ref_map_tile (ref_map_id, ref_tile_id, x, y)
				VALUES (%d, %d, %d, %d)
				""" % [ref_map_id, tile_id, x, y]
				
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
	seed_map_tiles_from_csv()
	
	print("=== ALL SEEDING COMPLETE ===")

# Export functions for external use
func export_seed_functions():
	"""Export the current database state as seed functions"""
	print("=== EXPORTING SEED FUNCTIONS ===")
	
	# Export maps
	var maps = database_manager.get_all_ref_maps()
	var maps_code = "func seed_ref_maps():\n"
	maps_code += "\t# Check if we already have ref_map data\n"
	maps_code += "\tvar check_query = \"SELECT COUNT(*) as count FROM ref_map\"\n"
	maps_code += "\tdb.query(check_query)\n"
	maps_code += "\tvar result = db.query_result\n"
	maps_code += "\tif result.size() > 0 and result[0][\"count\"] > 0:\n"
	maps_code += "\t\tprint(\"Database already contains ref_map data\")\n"
	maps_code += "\t\treturn\n"
	maps_code += "\tprint(\"No existing ref_map data found, seeding ref_maps...\")\n"
	maps_code += "\tvar maps_data = [\n"
	
	for map in maps:
		maps_code += "\t\t{\"name\": \"%s\", \"width\": %d, \"height\": %d, \"description\": \"%s\"},\n" % [
			map.name, map.width, map.height, map.description
		]
	
	maps_code += "\t]\n"
	maps_code += "\tfor map_data in maps_data:\n"
	maps_code += "\t\tvar insert_query = \"\"\"\n"
	maps_code += "\t\tINSERT INTO ref_map (name, width, height, description)\n"
	maps_code += "\t\tVALUES ('%s', %d, %d, '%s')\n"
	maps_code += "\t\t\"\"\" % [map_data.name, map_data.width, map_data.height, map_data.description]\n"
	maps_code += "\t\tdb.query(insert_query)\n"
	maps_code += "\t\tif is_query_successful():\n"
	maps_code += "\t\t\tprint(\"Inserted ref_map: \", map_data.name)\n"
	maps_code += "\t\telse:\n"
	maps_code += "\t\t\tprint(\"Error inserting ref_map \" + map_data.name + \": \" + db.error_message)\n"
	
	# Export tiles
	var tiles = database_manager.get_all_ref_tiles()
	var tiles_code = "func seed_ref_tiles():\n"
	tiles_code += "\t# Check if we already have ref_tile data\n"
	tiles_code += "\tvar check_query = \"SELECT COUNT(*) as count FROM ref_tile\"\n"
	tiles_code += "\tdb.query(check_query)\n"
	tiles_code += "\tvar result = db.query_result\n"
	tiles_code += "\tif result.size() > 0 and result[0][\"count\"] > 0:\n"
	tiles_code += "\t\tprint(\"Database already contains ref_tile data\")\n"
	tiles_code += "\t\treturn\n"
	tiles_code += "\tprint(\"No existing ref_tile data found, seeding ref_tiles...\")\n"
	tiles_code += "\tvar tiles_data = [\n"
	
	for tile in tiles:
		tiles_code += "\t\t{\"type_name\": \"%s\", \"is_walkable\": %s, \"color_hex\": \"%s\", \"movement_cost\": %d, \"texture_path\": \"%s\", \"description\": \"%s\"},\n" % [
			tile.type_name, str(tile.is_walkable).to_lower(), tile.color_hex, tile.movement_cost, tile.texture_path, tile.description
		]
	
	tiles_code += "\t]\n"
	tiles_code += "\tfor tile_data in tiles_data:\n"
	tiles_code += "\t\tvar insert_query = \"\"\"\n"
	tiles_code += "\t\tINSERT INTO ref_tile (type_name, is_walkable, color_hex, movement_cost, texture_path, tileset_x, tileset_y, tile_size, description)\n"
	tiles_code += "\t\tVALUES ('%s', %s, '%s', %d, '%s', %d, %d, %d, '%s')\n"
	tiles_code += "\t\t\"\"\" % [tile_data.type_name, str(tile_data.is_walkable).to_lower(), tile_data.color_hex, tile_data.movement_cost, tile_data.texture_path, 0, 0, 50, tile_data.description]\n"
	tiles_code += "\t\tdb.query(insert_query)\n"
	tiles_code += "\t\tif is_query_successful():\n"
	tiles_code += "\t\t\tprint(\"Inserted ref_tile: \", tile_data.type_name)\n"
	tiles_code += "\t\telse:\n"
	tiles_code += "\t\t\tprint(\"Error inserting ref_tile \" + tile_data.type_name + \": \" + db.error_message)\n"
	
	# Save to file
	var export_file = FileAccess.open("res://tools/exported_seed_functions.gd", FileAccess.WRITE)
	if export_file:
		export_file.store_line("# Exported seed functions from Map Seeder Tool")
		export_file.store_line("# Generated on: " + Time.get_datetime_string_from_system())
		export_file.store_line("")
		export_file.store_line(maps_code)
		export_file.store_line("")
		export_file.store_line(tiles_code)
		export_file.close()
		print("Exported seed functions to: res://tools/exported_seed_functions.gd")
	else:
		print("ERROR: Could not create export file") 
