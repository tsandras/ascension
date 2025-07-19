extends Node

# Current map data
var current_map_data = null
var current_tiles = []
var map_width: int = 0
var map_height: int = 0

# Hexagonal positioning variables (will be set based on actual image size)
var hex_image_width: float = 0
var hex_image_height: float = 0
var hex_horiz_spacing: float = 0
var hex_vert_spacing: float = 0

func _ready():
	print("MapManager initialized")
	# Load the reference tile image to get dimensions
	load_hex_tile_dimensions()

# Load actual hex tile dimensions from constants
func load_hex_tile_dimensions():
	# Use constants for consistent tile sizing across the system
	hex_image_width = HexTileConstants.TILE_WIDTH
	hex_image_height = HexTileConstants.TILE_HEIGHT
	
	# Use pre-calculated spacing from constants for optimal hexagonal layout
	hex_horiz_spacing = HexTileConstants.HORIZONTAL_SPACING
	hex_vert_spacing = HexTileConstants.VERTICAL_SPACING
	
	print("Using standardized hex tile dimensions: %dx%d, spacing: %.1fx%.1f" % [hex_image_width, hex_image_height, hex_horiz_spacing, hex_vert_spacing])

# Initialize the first map for a new game - now using new database structure
func initialize_game_map(game_id: int = 1) -> bool:
	print("Initializing game map for game_id: ", game_id)
	
	# Check if a current map already exists for this game
	var existing_map = DatabaseManager.get_current_map_info(game_id)
	if existing_map != null:
		print("Game already has a current map: ", existing_map["name"])
		load_current_map(game_id)
		return true
	
	# Create a new game with the Simple Map Test map
	if DatabaseManager.create_new_game("Simple Map Test", game_id):
		# Load the newly created map
		load_current_map(game_id)
		print("Successfully initialized game map: ", current_map_data["name"])
		return true
	else:
		print("Error: Failed to create simple map test map")
		return false

# Load the current map for the game
func load_current_map(game_id: int = 1) -> bool:
	current_map_data = DatabaseManager.get_current_map_info(game_id)
	if current_map_data == null:
		print("Error: No current map found for game_id: ", game_id)
		return false
	
	# Load the tiles for this game
	current_tiles = DatabaseManager.get_game_map_tiles(game_id)
	map_width = current_map_data["width"]
	map_height = current_map_data["height"]
	
	print("Loaded map: %s (%dx%d) with %d tiles" % [current_map_data["name"], map_width, map_height, current_tiles.size()])
	return true

# Get current map information
func get_current_map_info() -> Dictionary:
	if current_map_data == null:
		return {}
	
	return {
		"id": current_map_data.get("id", -1),
		"name": current_map_data.get("name", "Unknown Map"),
		"width": map_width,
		"height": map_height,
		"description": current_map_data.get("description", "No description available"),
		"tile_count": current_tiles.size()
	}

# Get all tiles for the current map
func get_current_tiles() -> Array:
	return current_tiles

# Get a specific tile at coordinates
func get_tile_at(x: int, y: int) -> Dictionary:
	for tile in current_tiles:
		if tile["x"] == x and tile["y"] == y:
			return tile
	return {}

# Convert grid coordinates to screen position (hexagonal layout using actual image size)
func grid_to_screen_position(grid_x: int, grid_y: int) -> Vector2:
	var screen_x = grid_x * hex_horiz_spacing
	var screen_y = grid_y * hex_vert_spacing
	
	# Offset every other row for hexagonal pattern (offset by half the horizontal spacing)
	if grid_y % 2 == 1:
		screen_x += hex_horiz_spacing / 2
	
	return Vector2(screen_x, screen_y)

# Convert screen position to grid coordinates (hexagonal layout)
func screen_to_grid_position(screen_pos: Vector2) -> Vector2i:
	# This is a simplified version - exact hex coordinate conversion is complex
	var grid_y = int(screen_pos.y / hex_vert_spacing)
	var offset = (grid_y % 2) * (hex_horiz_spacing / 2)
	var grid_x = int((screen_pos.x - offset) / hex_horiz_spacing)
	
	return Vector2i(grid_x, grid_y)

# Check if a position is valid (within map bounds)
func is_valid_position(x: int, y: int) -> bool:
	return x >= 0 and x < map_width and y >= 0 and y < map_height

# Check if a tile is walkable
func is_tile_walkable(x: int, y: int) -> bool:
	var tile = get_tile_at(x, y)
	if tile.is_empty():
		return false
	return tile.get("is_walkable", false)

# Get tile movement cost
func get_tile_movement_cost(x: int, y: int) -> int:
	var tile = get_tile_at(x, y)
	if tile.is_empty():
		return HexTileConstants.IMPASSABLE_MOVEMENT_COST
	return tile.get("movement_cost", HexTileConstants.DEFAULT_MOVEMENT_COST)

# Get tile color for rendering
func get_tile_color(x: int, y: int) -> Color:
	var tile = get_tile_at(x, y)
	if tile.is_empty():
		return Color.BLACK
	
	var color_hex = tile.get("color_hex", "#FFFFFF")
	return Color(color_hex)

# Get tile type name
func get_tile_type(x: int, y: int) -> String:
	var tile = get_tile_at(x, y)
	if tile.is_empty():
		return "unknown"
	return tile.get("type_name", "unknown")

# Get hexagonal neighbors of a tile (6 directions)
func get_hex_neighbors(x: int, y: int) -> Array:
	var neighbors = []
	
	# Hexagonal grid has different neighbor patterns for even/odd rows
	var neighbor_offsets
	if y % 2 == 0:  # Even row
		neighbor_offsets = HexTileConstants.HEX_NEIGHBORS_EVEN_ROW
	else:  # Odd row
		neighbor_offsets = HexTileConstants.HEX_NEIGHBORS_ODD_ROW
	
	for offset in neighbor_offsets:
		var neighbor_x = x + offset.x
		var neighbor_y = y + offset.y
		if is_valid_position(neighbor_x, neighbor_y):
			neighbors.append(Vector2i(neighbor_x, neighbor_y))
	
	return neighbors

# Get the distance between two hexagonal tiles
func get_hex_distance(x1: int, y1: int, x2: int, y2: int) -> int:
	# Convert to cube coordinates for easier distance calculation
	var cube1 = offset_to_cube(x1, y1)
	var cube2 = offset_to_cube(x2, y2)
	
	return (abs(cube1.x - cube2.x) + abs(cube1.y - cube2.y) + abs(cube1.z - cube2.z)) / 2

# Convert offset coordinates to cube coordinates (for hex distance calculation)
func offset_to_cube(col: int, row: int) -> Vector3:
	var x = col - (row - (row & 1)) / 2.0
	var z = row
	var y = -x - z
	return Vector3(x, y, z)

# Print debug information about current map
func print_map_debug():
	if current_map_data == null:
		print("No current map loaded")
		return
	
	print("=== MAP DEBUG INFO ===")
	print("Map: %s (%d x %d)" % [current_map_data.get("name", "Unknown"), map_width, map_height])
	print("Description: %s" % current_map_data.get("description", "No description"))
	print("Total tiles: %d" % current_tiles.size())
	
	# Count tile types
	var tile_counts = {}
	for tile in current_tiles:
		var type_name = tile["type_name"]
		tile_counts[type_name] = tile_counts.get(type_name, 0) + 1
	
	print("Tile distribution:")
	for type_name in tile_counts:
		print("  %s: %d tiles" % [type_name, tile_counts[type_name]])
	
	print("Hex image size: %.1fx%.1f, spacing: %.1fx%.1f" % [hex_image_width, hex_image_height, hex_horiz_spacing, hex_vert_spacing])
	print("=======================") 
