extends Control

# Map manager instance
var map_manager: MapManager

# UI references
@onready var game_world_clip = $GameWorldClip
@onready var game_world = $GameWorldClip/GameWorld
@onready var camera = $GameWorldClip/GameWorld/Camera2D
@onready var tile_layer = $GameWorldClip/GameWorld/TileLayer
@onready var character_layer = $GameWorldClip/GameWorld/CharacterLayer
@onready var character = $GameWorldClip/GameWorld/CharacterLayer/Character
@onready var info_panel = $InfoPanel
@onready var map_name_label = $InfoPanel/VBoxContainer/MapNameLabel
@onready var tile_info_label = $InfoPanel/VBoxContainer/TileInfoLabel
@onready var coordinates_label = $InfoPanel/VBoxContainer/CoordinatesLabel
@onready var character_info_label = $InfoPanel/VBoxContainer/CharacterInfoLabel
@onready var back_button = $InfoPanel/VBoxContainer/BackButton

# Tile rendering
var hex_tiles = []
var selected_tile = null
var character_grid_pos = Vector2(0, 0)  # Character's grid position

# Tile image cache
var tile_textures = {}

# Movement animation
var is_moving = false

func _ready():
	print("HexMap scene loaded")
	
	# Debug GameWorld setup
	print("GameWorldClip setup:")
	print("  Size: ", game_world_clip.size)
	print("  Position: ", game_world_clip.position)
	print("  Visible: ", game_world_clip.visible)
	print("  GameWorld children: ", game_world.get_child_count())
	print("  TileLayer children: ", tile_layer.get_child_count())
	
	# Set GameWorldClip to receive mouse events
	game_world_clip.mouse_filter = Control.MOUSE_FILTER_STOP
	print("  Mouse filter set to STOP")
	
	# Connect direct input to GameWorldClip as backup
	game_world_clip.gui_input.connect(_on_game_world_input)
	print("  Direct input connected to GameWorldClip")
	
	# Debug InfoPanel
	print("InfoPanel setup:")
	print("  Size: ", info_panel.size)
	print("  Position: ", info_panel.position)
	print("  Visible: ", info_panel.visible)
	
	# Show debug controls
	show_debug_help()
	
	# Preload tile images
	load_tile_textures()
	
	# Initialize map manager
	map_manager = MapManager.new()
	
	# Wait for database to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Initialize the game map
	if map_manager.initialize_game_map():
		setup_map_display()
		update_info_panel()
		update_character_info()
	else:
		print("Failed to initialize map")
		show_error_message("Failed to load map data")

func load_tile_textures():
	print("Loading tile textures...")
	
	# Get all ref_tiles from database to load their textures
	var ref_tiles = DatabaseManager.get_all_ref_tiles()
	
	for ref_tile in ref_tiles:
		var texture_path = ref_tile.get("texture_path", "")
		if texture_path != "" and texture_path != "null":
			var texture = load(texture_path)
			if texture:
				tile_textures[ref_tile.type_name] = texture
				print("Loaded texture for: ", ref_tile.type_name)
			else:
				print("Warning: Failed to load texture: ", texture_path)
		else:
			print("Warning: No texture path for tile type: ", ref_tile.type_name)

func setup_map_display():
	print("Setting up map display...")
	
	# Clear existing tiles
	for child in tile_layer.get_children():
		child.queue_free()
	hex_tiles.clear()
	
	# Get map data
	var map_data = map_manager.get_current_map_info()
	if not map_data:
		print("No map data available")
		return
	
	print("Map data received:")
	print("  Name: ", map_data.get("name", "Unknown"))
	print("  Width: ", map_data.get("width", 0))
	print("  Height: ", map_data.get("height", 0))
	
	var map_width = map_data.get("width", 0)
	var map_height = map_data.get("height", 0)
	var tiles = map_manager.get_current_tiles()
	
	print("Creating %d hex tiles for %dx%d map" % [tiles.size(), map_width, map_height])
	
	if tiles.size() == 0:
		print("ERROR: No tiles returned from map manager!")
		return
	
	# Create tiles as Sprite2D nodes
	for i in range(tiles.size()):
		var tile = tiles[i]
		print("Creating tile %d: %s at (%d, %d)" % [i, tile.get("type_name", "unknown"), tile.get("x", 0), tile.get("y", 0)])
		create_hex_tile(tile)
	
	print("Map display setup complete with %d tiles" % hex_tiles.size())
	print("Tile layer children: ", tile_layer.get_child_count())
	
	# Debug Area2D setup after all tiles are created
	await get_tree().process_frame  # Wait for Area2D to be fully setup
	print("=== AREA2D DEBUG ===")
	for i in range(min(3, hex_tiles.size())):  # Check first 3 tiles
		var tile = hex_tiles[i]
		var area = tile.get_child(0) as Area2D
		if area:
			var global_pos = area.global_position
			var local_pos = area.position
			print("Tile %d Area2D - Local: %s, Global: %s, Input pickable: %s" % [i, local_pos, global_pos, area.input_pickable])
			var collision = area.get_child(0) as CollisionShape2D
			if collision:
				print("  Collision shape: %s, Size: %s" % [collision.shape, collision.shape.size if collision.shape else "none"])
		else:
			print("Tile %d has no Area2D child!" % i)
	print("==================")
	
	# Initialize character position on first walkable tile
	initialize_character_position()

func initialize_character_position():
	"""Place character on the first walkable tile"""
	print("Initializing character position...")
	
	# Calculate the bounds of all tiles
	var tile_bounds = calculate_tile_bounds()
	var tile_center = Vector2(
		(tile_bounds.x + tile_bounds.z) / 2.0,  # x min + x max / 2
		(tile_bounds.y + tile_bounds.w) / 2.0   # y min + y max / 2
	)
	
	# Calculate where to position the GameWorld Node2D to center tiles in the visible area
	var visible_area_center = Vector2(
		game_world_clip.size.x / 2.0,  # Center of the clipped area
		game_world_clip.size.y / 2.0
	)
	
	# Offset the entire GameWorld to center the tiles
	var world_offset = visible_area_center - tile_center
	game_world.position = world_offset
	
	print("Tile center: ", tile_center)
	print("Visible area center: ", visible_area_center)
	print("GameWorld offset: ", world_offset)
	print("GameWorld position: ", game_world.position)
	
	# Place character on first walkable tile
	for tile in hex_tiles:
		var tile_data = tile.get_meta("tile_data")
		if tile_data.get("is_walkable", false):
			var grid_pos = tile.get_meta("grid_pos")
			character_grid_pos = grid_pos
			character.position = hex_grid_to_world_position(grid_pos)
			print("Character initialized at grid position: ", grid_pos)
			print("Character world position: ", character.position)
			
			update_character_info()
			return
	
	# Fallback: place at origin if no walkable tiles found
	print("Warning: No walkable tiles found, placing character at origin")
	character_grid_pos = Vector2(0, 0)
	character.position = hex_grid_to_world_position(Vector2(0, 0))
	print("Character fallback position: ", character.position)
	update_character_info()

func calculate_tile_bounds() -> Vector4:
	"""Calculate the min/max world coordinates of all tiles"""
	if hex_tiles.size() == 0:
		return Vector4(0, 0, 0, 0)
	
	var min_x = hex_tiles[0].position.x
	var min_y = hex_tiles[0].position.y
	var max_x = min_x
	var max_y = min_y
	
	for tile in hex_tiles:
		min_x = min(min_x, tile.position.x)
		min_y = min(min_y, tile.position.y)
		max_x = max(max_x, tile.position.x)
		max_y = max(max_y, tile.position.y)
	
	print("Tile bounds: min(", min_x, ", ", min_y, ") max(", max_x, ", ", max_y, ")")
	return Vector4(min_x, min_y, max_x, max_y)

func create_hex_tile(tile_data: Dictionary):
	# Create a Sprite2D for each hex tile
	var hex_tile = Sprite2D.new()
	var grid_pos = Vector2(tile_data.x, tile_data.y)
	
	print("  Creating hex tile at grid: ", grid_pos)
	
	# Get tile type and texture
	var tile_type = tile_data.get("type_name", "grass")
	var texture = tile_textures.get(tile_type)
	
	if texture:
		hex_tile.texture = texture
		print("  Loaded texture for: ", tile_type, " (", texture.get_size(), ")")
	else:
		print("Warning: No texture found for tile type: ", tile_type)
		# Use a default texture or create a colored rectangle
		hex_tile.texture = tile_textures.get("grass", load("res://icon.svg"))
		if hex_tile.texture:
			print("  Using fallback texture: ", hex_tile.texture.get_size())
	
	# Position the tile using hexagonal grid layout
	var world_pos = hex_grid_to_world_position(grid_pos)
	hex_tile.position = world_pos
	
	# Calculate scale based on constants
	var scale_factor = float(HexTileConstants.TILE_WIDTH) / float(HexTileConstants.SOURCE_TEXTURE_WIDTH)
	hex_tile.scale = Vector2(scale_factor, scale_factor)
	
	print("  Tile world position: ", world_pos)
	print("  Tile scale: ", hex_tile.scale, " (", HexTileConstants.TILE_WIDTH, "px target from ", HexTileConstants.SOURCE_TEXTURE_WIDTH, "px source)")
	
	# Store tile data and grid position
	hex_tile.set_meta("tile_data", tile_data)
	hex_tile.set_meta("grid_pos", grid_pos)
	hex_tile.set_meta("original_modulate", Color.WHITE)
	
	# Create Area2D for input detection
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Configure Area2D for input detection
	area.input_pickable = true
	area.monitoring = false  # We don't need collision detection, just input
	area.monitorable = false
	
	# Set up collision shape based on target tile size
	shape.size = Vector2(HexTileConstants.TILE_WIDTH, HexTileConstants.TILE_HEIGHT)
	collision.shape = shape
	collision.position = Vector2.ZERO
	
	print("  Collision size: ", shape.size)
	
	area.add_child(collision)
	hex_tile.add_child(area)
	
	print("  Area2D configured - input_pickable: ", area.input_pickable)
	
	# Connect Area2D signals for input detection
	var input_connection = area.input_event.connect(_on_tile_input.bind(hex_tile))
	var mouse_enter_connection = area.mouse_entered.connect(_on_tile_mouse_entered.bind(hex_tile))
	var mouse_exit_connection = area.mouse_exited.connect(_on_tile_mouse_exited.bind(hex_tile))
	
	print("  Signal connections - input: ", input_connection == OK, ", mouse_enter: ", mouse_enter_connection == OK, ", mouse_exit: ", mouse_exit_connection == OK)
	
	# Add to tile layer
	tile_layer.add_child(hex_tile)
	hex_tiles.append(hex_tile)
	print("  Tile added to layer. Total tiles: ", hex_tiles.size())

func hex_grid_to_world_position(grid_pos: Vector2) -> Vector2:
	"""Convert hex grid coordinates to world position"""
	# Use spacing constants from HexTileConstants
	var x_offset = HexTileConstants.HORIZONTAL_SPACING
	var y_offset = HexTileConstants.VERTICAL_SPACING
	
	var world_x = grid_pos.x * x_offset
	var world_y = grid_pos.y * y_offset
	
	# Offset every other row for hexagonal pattern
	if int(grid_pos.y) % 2 == 1:
		world_x += x_offset * 0.5
	
	print("Hex grid ", grid_pos, " -> world ", Vector2(world_x, world_y), " (x_offset: ", x_offset, ", y_offset: ", y_offset, ")")
	return Vector2(world_x, world_y)

func world_position_to_hex_grid(world_pos: Vector2) -> Vector2:
	"""Convert world position back to hex grid coordinates (approximate)"""
	# Use same spacing values as hex_grid_to_world_position
	var x_offset = HexTileConstants.HORIZONTAL_SPACING
	var y_offset = HexTileConstants.VERTICAL_SPACING
	
	var grid_y = round(world_pos.y / y_offset)
	var grid_x = world_pos.x / x_offset
	
	# Adjust for hexagonal offset
	if int(grid_y) % 2 == 1:
		grid_x -= 0.5
	
	grid_x = round(grid_x)
	
	return Vector2(grid_x, grid_y)

func move_character_to_tile(target_grid_pos: Vector2):
	"""Move character to the specified tile with pathfinding animation"""
	print("=== CHARACTER PATHFINDING ===")
	print("Target grid position: ", target_grid_pos)
	print("Current character grid position: ", character_grid_pos)
	print("Is moving: ", is_moving)
	
	if is_moving:
		print("Character is already moving")
		return
	
	# Check if the target tile exists and is walkable
	var target_tile = get_tile_at_grid_position(target_grid_pos)
	if not target_tile:
		print("ERROR: No tile found at position: ", target_grid_pos)
		return
	
	var tile_data = target_tile.get_meta("tile_data")
	print("Target tile data: ", tile_data)
	print("Target tile walkable: ", tile_data.get("is_walkable", false))
	
	# if not tile_data.get("is_walkable", false):
	# 	print("Cannot move to non-walkable tile: ", tile_data.get("type_name", "unknown"))
	# 	return
	
	# Find path from current position to target
	var path = find_path(character_grid_pos, target_grid_pos)
	if path.size() == 0:
		print("No path found to target!")
		return
	
	print("Path found with %d steps: %s" % [path.size(), path])
	
	# Start moving along the path
	is_moving = true
	move_along_path(path)
	print("=========================")

func find_path(start: Vector2, goal: Vector2) -> Array:
	"""Find path using A* algorithm for hex grid"""
	print("Finding path from ", start, " to ", goal)
	
	# If start and goal are the same, no movement needed
	if start == goal:
		return []
	
	var open_set = [start]
	var came_from = {}
	var g_score = {start: 0}
	var f_score = {start: hex_distance(start, goal)}
	
	while open_set.size() > 0:
		# Find node with lowest f_score
		var current = open_set[0]
		var current_f = f_score.get(current, INF)
		
		for node in open_set:
			var node_f = f_score.get(node, INF)
			if node_f < current_f:
				current = node
				current_f = node_f
		
		# If we reached the goal, reconstruct path
		if current == goal:
			var path = [goal]
			while came_from.has(current):
				current = came_from[current]
				if current != start:  # Don't include starting position
					path.push_front(current)
			print("Path reconstruction complete: ", path)
			return path
		
		open_set.erase(current)
		
		# Check all neighbors
		var neighbors = get_hex_neighbors(current)
		for neighbor in neighbors:
			# Check if neighbor is walkable
			var neighbor_tile = get_tile_at_grid_position(neighbor)
			if not neighbor_tile:
				continue
			
			var _neighbor_data = neighbor_tile.get_meta("tile_data")
			# For now, allow movement to any tile (remove walkable check for testing)
			# if not _neighbor_data.get("is_walkable", false):
			# 	continue
			
			var tentative_g = g_score.get(current, INF) + 1  # Each step costs 1
			
			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + hex_distance(neighbor, goal)
				
				if neighbor not in open_set:
					open_set.append(neighbor)
	
	print("No path found!")
	return []

func get_hex_neighbors(grid_pos: Vector2) -> Array:
	"""Get the 6 neighboring hex tiles"""
	var neighbors = []
	var x = int(grid_pos.x)
	var y = int(grid_pos.y)
	
	# Use neighbor offsets from HexTileConstants
	var offsets = []
	if y % 2 == 0:  # Even row
		offsets = HexTileConstants.HEX_NEIGHBORS_EVEN_ROW
	else:  # Odd row
		offsets = HexTileConstants.HEX_NEIGHBORS_ODD_ROW
	
	for offset in offsets:
		var neighbor = Vector2(x + offset.x, y + offset.y)
		# Check if neighbor is within valid grid bounds
		if neighbor.x >= 0 and neighbor.y >= 0:
			neighbors.append(neighbor)
	
	return neighbors

func hex_distance(a: Vector2, b: Vector2) -> int:
	"""Calculate hex grid distance between two positions"""
	# Convert to cube coordinates for easier distance calculation
	var ac = offset_to_cube(a)
	var bc = offset_to_cube(b)
	
	return int((abs(ac.x - bc.x) + abs(ac.y - bc.y) + abs(ac.z - bc.z)) / 2)

func offset_to_cube(hex: Vector2) -> Vector3:
	"""Convert offset coordinates to cube coordinates"""
	var x = hex.x - (hex.y - int(hex.y) % 2) / 2
	var z = hex.y
	var y = -x - z
	return Vector3(x, y, z)

func move_along_path(path: Array):
	"""Animate character movement along the given path"""
	if path.size() == 0:
		is_moving = false
		return
	
	# Move to first position in path
	var next_grid_pos = path[0]
	var next_world_pos = hex_grid_to_world_position(next_grid_pos)
	
	print("Moving to step: ", next_grid_pos, " (world: ", next_world_pos, ")")
	
	# Update character grid position
	character_grid_pos = next_grid_pos
	
	# Create tween for this step
	var tween = create_tween()
	tween.tween_property(character, "position", next_world_pos, 0.3)  # Faster steps
	
	# When this step completes, continue with remaining path
	var remaining_path = path.slice(1)  # Remove first element
	tween.tween_callback(func():
		if remaining_path.size() > 0:
			move_along_path(remaining_path)  # Continue with remaining path
		else:
			is_moving = false
			print("Path completed!")
			update_character_info()
	)

func get_tile_at_grid_position(grid_pos: Vector2) -> Sprite2D:
	"""Find the tile at the given grid position"""
	for tile in hex_tiles:
		if tile.get_meta("grid_pos") == grid_pos:
			return tile
	return null

func _on_tile_mouse_entered(tile: Sprite2D):
	# Highlight tile on hover
	tile.modulate = Color(1.1, 1.1, 1.1, 1.0)
	
	# Update tile info
	update_tile_info(tile.get_meta("tile_data"))

func _on_tile_mouse_exited(tile: Sprite2D):
	# Remove highlight only if this tile is not selected
	if tile != selected_tile:
		tile.modulate = tile.get_meta("original_modulate")

func _on_tile_input(_viewport: Node, event: InputEvent, _shape_idx: int, tile: Sprite2D):
	print("Tile input event received: ", event)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Left mouse button clicked on tile!")
		select_tile(tile)
	else:
		print("Non-click event on tile: ", event)

func select_tile(tile: Sprite2D):
	print("=== TILE SELECTION ===")
	print("Tile clicked!")
	
	# Deselect previous tile
	if selected_tile != null:
		selected_tile.modulate = selected_tile.get_meta("original_modulate")
	
	# Select new tile
	selected_tile = tile
	tile.modulate = Color(1.2, 1.2, 0.8, 1.0)  # Bright yellow tint for selection
	
	# Update info panel
	update_tile_info(tile.get_meta("tile_data"))
	
	# Update coordinates
	var grid_pos = tile.get_meta("grid_pos")
	coordinates_label.text = "Position: (%d, %d)" % [grid_pos.x, grid_pos.y]
	
	print("Selected tile at grid (%d, %d): %s" % [grid_pos.x, grid_pos.y, tile.get_meta("tile_data")["type_name"]])
	print("Tile world position: ", tile.position)
	
	# Move character to selected tile
	print("Attempting to move character to grid: ", grid_pos)
	move_character_to_tile(grid_pos)
	print("=====================")

func update_tile_info(tile_data: Dictionary):
	var type_name = tile_data.get("type_name", "unknown")
	var is_walkable = tile_data.get("is_walkable", false)
	var movement_cost = tile_data.get("movement_cost", 1)
	var description = tile_data.get("description", "No description available")
	
	var walkable_text = "Walkable" if is_walkable else "Blocked"
	
	tile_info_label.text = "%s\n%s (Cost: %d)\n%s" % [
		type_name.capitalize(),
		walkable_text,
		movement_cost,
		description
	]

func update_character_info():
	"""Update the character info display"""
	character_info_label.text = "Character: (%d, %d)" % [character_grid_pos.x, character_grid_pos.y]

func update_info_panel():
	"""Update the map info panel"""
	var map_data = map_manager.get_current_map_info()
	if map_data:
		map_name_label.text = "Map: " + map_data.get("name", "Unknown")
	else:
		map_name_label.text = "Map: Unknown"

func show_error_message(message: String):
	map_name_label.text = "Error"
	tile_info_label.text = message
	coordinates_label.text = ""

func _on_back_button_pressed():
	print("Returning to main menu...")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

# Debug functions
func _input(event):
	# Global input test for debugging
	if event is InputEventMouseButton and event.pressed:
		print("=== GLOBAL MOUSE INPUT ===")
		print("Mouse button pressed: ", event.button_index)
		print("Mouse position: ", event.position)
		
		# Test coordinate transformation
		var local_mouse_pos = game_world.to_local(event.position)
		print("Local mouse position in GameWorld: ", local_mouse_pos)
		
		# Check if mouse is over any Area2D
		if hex_tiles.size() > 0:
			print("Checking first few tiles:")
			for i in range(min(3, hex_tiles.size())):
				var tile = hex_tiles[i]
				var area = tile.get_child(0) as Area2D
				if area:
					var area_global_pos = area.global_position
					var distance = event.position.distance_to(area_global_pos)
					print("  Tile %d Area2D global pos: %s, distance to mouse: %.1f" % [i, area_global_pos, distance])
		print("===========================")
	
	if event.is_action_pressed("ui_accept"):  # Space key or Enter
		if map_manager:
			map_manager.print_map_debug()
	

	
	# Camera controls
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_H: # Show debug help
				show_debug_help()
			KEY_SPACE: # Print debug info
				print_debug_info()
	
	# Zoom with mouse wheel using Camera2D
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(1.1)  # Zoom in
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(0.9)  # Zoom out

# Show debug help controls
func show_debug_help():
	print("=== HEX MAP DEBUG CONTROLS ===")
	print("Space - Print debug info")
	print("H - Show this help")
	print("Mouse wheel - Zoom camera")
	print("Click tiles - Move character")
	print("==============================")

func print_debug_info():
	"""Print current map and character debug information"""
	print("=== MAP DEBUG INFO ===")
	print("Character position: ", character_grid_pos)
	print("Character world pos: ", character.position)
	print("GameWorld position: ", game_world.position)
	print("GameWorld scale: ", game_world.scale)
	print("Total tiles: ", hex_tiles.size())
	if selected_tile:
		var tile_data = selected_tile.get_meta("tile_data")
		print("Selected tile: ", tile_data.get("type_name", "unknown"))
		print("Selected tile walkable: ", tile_data.get("is_walkable", false))
	print("=====================")

func zoom_camera(zoom_factor: float):
	"""Zoom the game world by scaling the GameWorld node"""
	var new_scale = game_world.scale * zoom_factor
	# Clamp zoom between reasonable values
	new_scale = new_scale.clamp(Vector2(0.2, 0.2), Vector2(3.0, 3.0))
	game_world.scale = new_scale
	print("GameWorld scale: ", game_world.scale)



func _on_game_world_input(event: InputEvent):
	"""Direct input handler for GameWorldClip as backup for Area2D"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("=== DIRECT TILE CLICK DETECTION ===")
		print("Click position in GameWorldClip: ", event.position)
		
		# Convert click position to GameWorld coordinates
		var world_click_pos = event.position - game_world.position
		print("Click position in GameWorld: ", world_click_pos)
		
		# Find which tile was clicked
		var clicked_tile = find_tile_at_world_position(world_click_pos)
		if clicked_tile:
			print("Found clicked tile!")
			select_tile(clicked_tile)
		else:
			print("No tile found at click position")
		print("===================================")

func find_tile_at_world_position(world_pos: Vector2) -> Sprite2D:
	"""Find which tile contains the given world position"""
	var closest_tile = null
	var closest_distance = INF
	
	for tile in hex_tiles:
		var tile_pos = tile.position
		var distance = world_pos.distance_to(tile_pos)
		
		# Check if within tile bounds using constants
		var tile_radius = HexTileConstants.TILE_WIDTH / 2.0
		if distance < tile_radius and distance < closest_distance:
			closest_distance = distance
			closest_tile = tile
			print("  Checking tile at %s, distance: %.1f (within bounds: %s)" % [tile_pos, distance, distance < tile_radius])
	
	return closest_tile
