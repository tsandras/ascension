extends Control

# Map manager is now a global autoload

# UI references
@onready var game_viewport_container = $GameViewport
@onready var game_viewport = $GameViewport/GameViewport
@onready var game_world = $GameViewport/GameViewport/GameWorld
@onready var camera = $GameViewport/GameViewport/Camera2D
@onready var tile_layer = $GameViewport/GameViewport/GameWorld/TileLayer
@onready var overlay_layer = $GameViewport/GameViewport/GameWorld/OverlayLayer
@onready var character_layer = $GameViewport/GameViewport/GameWorld/CharacterLayer
@onready var character = $GameViewport/GameViewport/GameWorld/CharacterLayer/Character
@onready var info_panel = $InfoPanel
@onready var map_name_label = $InfoPanel/VBoxContainer/MapNameLabel
@onready var character_avatar = $InfoPanel/VBoxContainer/CharacterAvatar
@onready var tile_info_label = $InfoPanel/VBoxContainer/TileInfoLabel
@onready var coordinates_label = $InfoPanel/VBoxContainer/CoordinatesLabel
@onready var character_info_label = $InfoPanel/VBoxContainer/CharacterInfoLabel
@onready var back_button = $InfoPanel/VBoxContainer/BackButton
var character_sheet: Control

# Tile rendering
var hex_tiles = []
var selected_tile = null
var character_grid_pos = Vector2(0, 0)  # Character's grid position
var current_character: Character = null

# Tile image cache
var tile_textures = {}

# Overlay system
var overlay_manager: OverlayManager

# Movement animation
var is_moving = false

# Path preview system
var path_preview_tiles = []
var showing_path_preview = false
var preview_target_grid_pos = Vector2.ZERO

# Camera following
var camera_follow_enabled = true

func _ready():
	print("HexMap scene loaded")
	# Wait for the scene to be fully ready
	await get_tree().process_frame
	
	# Check if we have a loaded character
	check_for_loaded_character()
	
	# Setup character sheet functionality
	setup_character_sheet()
	
	# Debug GameWorld setup
	print("GameViewportContainer setup:")
	print("  Size: ", game_viewport.size)
	print("  Position: ", game_viewport_container.position)
	print("  Visible: ", game_viewport_container.visible)
	print("  GameWorld children: ", game_world.get_child_count())
	print("  TileLayer children: ", tile_layer.get_child_count())
	
	# Set GameViewportContainer to receive mouse events
	game_viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
	print("  Mouse filter set to STOP")
	
	# Connect direct input to GameViewportContainer as backup
	game_viewport_container.gui_input.connect(_on_game_world_input)
	print("  Direct input connected to GameViewportContainer")
	
	# Debug InfoPanel
	print("InfoPanel setup:")
	print("  Size: ", info_panel.size)
	print("  Position: ", info_panel.position)
	print("  Visible: ", info_panel.visible)
	
	# Show debug controls
	show_debug_help()
	
	# Preload tile images
	load_tile_textures()
	
	# Initialize overlay system
	print("=== OVERLAY LAYER DEBUG ===")
	print("Overlay layer reference: ", overlay_layer)
	if overlay_layer:
		print("Overlay layer children: ", overlay_layer.get_child_count())
		print("Overlay layer visible: ", overlay_layer.visible)
		print("Overlay layer z_index: ", overlay_layer.z_index)
		print("Tile layer z_index: ", tile_layer.z_index)
		print("GameWorld z_index: ", game_world.z_index)
	else:
		print("ERROR: Overlay layer is null!")
	print("===========================")
	
	overlay_manager = OverlayManager.new(overlay_layer)
	
	# Initialize the game map (MapManager is now global)
	print("MapManager reference: ", MapManager)
	if MapManager.initialize_game_map():
		setup_map_display()
		update_info_panel()
		update_character_info()
	else:
		print("Failed to initialize map")
		show_error_message("Failed to load map data")

	if back_button:
		CursorUtils.add_cursor_to_button(back_button)

	Dialogic.start('test')

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
	
	# Clear existing overlays
	if overlay_manager:
		overlay_manager.clear_all_overlays()
	
	# Get map data
	if MapManager == null:
		print("ERROR: MapManager is null!")
		return
	var map_data = MapManager.get_current_map_info()
	if not map_data:
		print("No map data available")
		return
	
	print("Map data received:")
	print("  Name: ", map_data.get("name", "Unknown"))
	print("  Width: ", map_data.get("width", 0))
	print("  Height: ", map_data.get("height", 0))
	
	var map_width = map_data.get("width", 0)
	var map_height = map_data.get("height", 0)
	if MapManager == null:
		print("ERROR: MapManager is null when getting tiles!")
		return
	var tiles = MapManager.get_current_tiles()
	
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
	
	# Set up camera to follow character
	setup_camera_following()
	
	# Debug viewport setup
	print("=== VIEWPORT SETUP ===")
	print("HexMap size: ", size)
	print("GameViewport size: ", game_viewport.size)
	print("InfoPanel size: ", info_panel.size)
	print("InfoPanel position: ", info_panel.position)
	print("=====================")

func initialize_character_position():
	"""Place character on the first walkable tile"""
	print("Initializing character position...")
	
	# Place character on hex (4, 4) tile
	print("Placing character on hex (4, 4) tile")
	var target_grid_pos = Vector2(4, 4)
	var target_tile = get_tile_at_grid_position(target_grid_pos)
	if not target_tile:
		print("ERROR: No tile found at position: ", target_grid_pos)
		return

	var grid_pos = target_tile.get_meta("grid_pos")
	character_grid_pos = grid_pos
	character.position = hex_grid_to_world_position(grid_pos)
	print("Character initialized at grid position: ", grid_pos)
	print("Character world position: ", character.position)
	
	# Center camera on character
	center_camera_on_character()
	
	update_character_info()


func setup_camera_following():
	"""Set up GameWorld to follow the character"""
	print("Setting up GameWorld following...")
	
	# Enable camera following
	camera_follow_enabled = true
	
	# Set camera to follow character
	camera.enabled = true
	camera.make_current()
	
	# Set initial zoom using constants
	camera.zoom = CameraConstants.INITIAL_ZOOM
	print("Initial camera zoom set to: ", camera.zoom)
	
	# Set initial GameWorld position to center character
	center_camera_on_character()
	
	print("GameWorld following enabled")

func center_camera_on_character():
	"""Center the camera on the character position"""
	if not camera_follow_enabled:
		return
	
	# Simply set camera position to character position
	camera.position = character.position
	
	print("Camera centered on character at: ", character.position)
	print("Camera zoom: ", camera.zoom)

func check_for_loaded_character():
	"""Check if we have a loaded character and update the UI accordingly"""
	# Try to load character from creation first, then from database
	current_character = Character.load_from_creation()
	if current_character == null:
		current_character = Character.load_from_db()
	
	if current_character and current_character.is_valid():
		print("=== LOADED CHARACTER DETECTED ===")
		print("Character Name: ", current_character.name)
		print("Character Race: ", current_character.race_name)
		print("Character Sex: ", current_character.sex)
		print("Character Attributes: ", current_character.attributes)
		print("Character Abilities: ", current_character.abilities)
		print("Character Competences: ", current_character.competences)
	
		print("================================")
		
		# Update character info display
		update_character_info()
		
		# Update character avatar
		update_character_avatar()
		
		# You could also update other UI elements here
		# For example, show character stats in the InfoPanel
		update_info_panel()
	else:
		print("No loaded character found - using default setup")

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
	
	# print("  Creating hex tile at grid: ", grid_pos)
	
	# Get tile type and texture
	var tile_type = tile_data.get("type_name", "grass")
	var texture = tile_textures.get(tile_type)
	
	if texture:
		hex_tile.texture = texture
		# print("  Loaded texture for: ", tile_type, " (", texture.get_size(), ")")
	else:
		# print("Warning: No texture found for tile type: ", tile_type)
		# Use a default texture or create a colored rectangle
		hex_tile.texture = tile_textures.get("grass", load("res://icon.svg"))
		if hex_tile.texture:
			print("  Using fallback texture: ", hex_tile.texture.get_size())
	
	# Apply blur shader to the tile
	if hex_tile.texture:
		var shader = load("res://shaders/tile_blur.gdshader")
		if shader:
			hex_tile.material = ShaderMaterial.new()
			hex_tile.material.shader = shader
			print("Applied blur shader to tile: ", tile_type)
		else:
			print("Warning: Could not load blur shader")
	
	# Position the tile using hexagonal grid layout
	var world_pos = hex_grid_to_world_position(grid_pos)
	hex_tile.position = world_pos
	
	# Use textures at original size - no scaling to avoid pixelation
	hex_tile.scale = Vector2.ONE
	
	# Set texture filtering for crisp rendering
	# hex_tile.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hex_tile.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	# print("  Tile world position: ", world_pos)
	# print("  Tile scale: ", hex_tile.scale, " (", HexTileConstants.TILE_WIDTH, "px target from ", HexTileConstants.SOURCE_TEXTURE_WIDTH, "px source)")
	
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
	
	# Set up collision shape based on original texture size
	shape.size = Vector2(HexTileConstants.SOURCE_TEXTURE_WIDTH, HexTileConstants.SOURCE_TEXTURE_HEIGHT)
	collision.shape = shape
	collision.position = Vector2.ZERO
	
	area.add_child(collision)
	hex_tile.add_child(area)
	
	# Add to tile layer
	tile_layer.add_child(hex_tile)
	hex_tiles.append(hex_tile)
	
	# Add overlays to tile based on database data
	if overlay_manager:
		overlay_manager.add_overlay_to_tile(hex_tile, tile_data)
		
		# Debug: Add a very obvious test overlay to the first tile
		if hex_tiles.size() == 1:
			print("=== ADDING TEST OVERLAY ===")
			var test_overlay = Sprite2D.new()
			test_overlay.texture = load("res://icon.svg")
			test_overlay.scale = Vector2(2.0, 2.0)
			test_overlay.z_index = 100
			test_overlay.modulate = Color.RED
			overlay_layer.add_child(test_overlay)
			test_overlay.global_position = hex_tile.global_position
			print("Test overlay added at: ", test_overlay.global_position)
			print("Test overlay visible: ", test_overlay.visible)
			print("Test overlay z_index: ", test_overlay.z_index)
			print("==========================")
	
	# print("  Tile added to layer. Total tiles: ", hex_tiles.size())

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
	
	if is_moving:
		return
	
	# Check if the target tile exists and is walkable
	var target_tile = get_tile_at_grid_position(target_grid_pos)
	if not target_tile:
		print("ERROR: No tile found at position: ", target_grid_pos)
		return
	
	var tile_data = target_tile.get_meta("tile_data")
	print("Target tile walkable: ", tile_data.get("is_walkable", false))
	
	# TODO: integrate the blocked path and non-walkable tiles
	if not tile_data.get("is_walkable", false):
		print("Cannot move to non-walkable tile: ", tile_data.get("type_name", "unknown"))
		return
	
	# Find path from current position to target
	var path = find_path(character_grid_pos, target_grid_pos)
	if path.size() == 0:
		print("No path found to target!")
		return
	
	print("Path found with %d steps: %s" % [path.size(), path])
	
	# Start moving along the path
	is_moving = true
	move_along_path(path)

func find_path(start: Vector2, goal: Vector2) -> Array:
	"""Find path using A* algorithm for hex grid"""
	
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
			if not _neighbor_data.get("is_walkable", false):
				continue
			
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

func show_path_preview(target_grid_pos: Vector2):
	"""Show path preview with arrows on each tile"""
	print("=== PATH PREVIEW ===")
	print("Target grid position: ", target_grid_pos)
	print("Current character position: ", character_grid_pos)
	
	# Clear any existing preview
	clear_path_preview()
	
	# Find path to target
	var path = find_path(character_grid_pos, target_grid_pos)
	if path.size() == 0:
		print("No path found to target!")
		return
	
	print("Path found with %d steps: %s" % [path.size(), path])
	
	# Store preview data
	showing_path_preview = true
	preview_target_grid_pos = target_grid_pos
	
	# Create path preview tiles
	for i in range(path.size()):
		var grid_pos = path[i]
		var tile = get_tile_at_grid_position(grid_pos)
		if tile:
			# Create arrow overlay for this tile
			create_path_arrow(tile, i, path.size(), path)
			path_preview_tiles.append(tile)
	
	print("Path preview created with %d arrows" % path_preview_tiles.size())
	print("===================")

func create_path_arrow(tile: Sprite2D, step_index: int, total_steps: int, path: Array):
	"""Create an arrow overlay on a tile to show path direction"""
	var is_final_tile = (step_index == total_steps - 1)
	
	if is_final_tile:
		# Create cross for final destination
		var cross = Sprite2D.new()
		var cross_texture = load("res://assets/ui/cross.png")
		if cross_texture:
			cross.texture = cross_texture
			cross.scale = Vector2(4, 4)  # Scale up by 4x
			cross.position = Vector2.ZERO  # Center on tile
			cross.z_index = 1  # Ensure it appears above the tile
			tile.add_child(cross)
			tile.set_meta("path_arrow", cross)
		else:
			print("Warning: Could not load cross.png")
	else:
		# Create pointer for intermediate tiles
		var pointer = Sprite2D.new()
		var pointer_texture = load("res://assets/ui/pointer.png")
		if pointer_texture:
			pointer.texture = pointer_texture
			pointer.scale = Vector2(4, 4)  # Scale up by 4x
			pointer.position = Vector2.ZERO  # Center on tile
			pointer.z_index = 1  # Ensure it appears above the tile
			
			# Calculate direction to next tile
			var next_step_index = step_index + 1
			if next_step_index < total_steps:
				var next_tile = get_tile_at_grid_position(path[next_step_index])
				if next_tile:
					# Use world positions for more accurate direction calculation
					var current_world_pos = tile.position
					var next_world_pos = next_tile.position
					var world_direction = next_world_pos - current_world_pos
					
					# Calculate rotation angle based on world direction
					var angle = atan2(world_direction.y, world_direction.x)
					print("  Raw angle: ", angle, " (", rad_to_deg(angle), " degrees)")
					angle += 3*PI/4
					
					pointer.rotation = angle
			
			tile.add_child(pointer)
			tile.set_meta("path_arrow", pointer)
		else:
			print("Warning: Could not load pointer.png")

func clear_path_preview():
	"""Clear all path preview arrows"""
	print("Clearing path preview...")
	
	for tile in path_preview_tiles:
		var arrow = tile.get_meta("path_arrow", null)
		if arrow:
			arrow.queue_free()
			tile.set_meta("path_arrow", null)
	
	path_preview_tiles.clear()
	showing_path_preview = false
	preview_target_grid_pos = Vector2.ZERO
	
	print("Path preview cleared")

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
	
	# Also tween camera to follow character smoothly
	if camera_follow_enabled:
		tween.parallel().tween_property(camera, "position", next_world_pos, 0.3)
		
		# Debug: Check if InfoPanel is being affected
		print("InfoPanel position during movement: ", info_panel.position)
		print("GameWorld position: ", game_world.position)
	
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
	
	# print("Selected tile at grid (%d, %d): %s" % [grid_pos.x, grid_pos.y, tile.get_meta("tile_data")["type_name"]])
	# print("Tile world position: ", tile.position)
	
	# Handle path preview or movement
	if showing_path_preview and grid_pos == preview_target_grid_pos:
		# Second click on same tile - execute movement
		print("Second click detected - executing movement to: ", grid_pos)
		clear_path_preview()
		move_character_to_tile(grid_pos)
	elif showing_path_preview and grid_pos != preview_target_grid_pos:
		# Click on different tile while showing preview - show new preview
		print("Click on different tile - showing new path preview to: ", grid_pos)
		show_path_preview(grid_pos)
	else:
		# First click - show path preview
		print("First click detected - showing path preview to: ", grid_pos)
		show_path_preview(grid_pos)
	
	print("=====================")

func update_tile_info(tile_data: Dictionary):
	var type_name = tile_data.get("type_name", "unknown")
	var is_walkable = tile_data.get("is_walkable", false)
	var time_to_cross = tile_data.get("time_to_cross", 1)
	var description = tile_data.get("description", "No description available")
	
	var walkable_text = "Walkable" if is_walkable else "Blocked"
	
	tile_info_label.text = "%s\n%s (Time: %d)\n%s" % [
		type_name.capitalize(),
		walkable_text,
		time_to_cross,
		description
	]

func update_character_info():
	"""Update the character info display"""
	if current_character and current_character.is_valid():
		# Show loaded character info
		character_info_label.text = "%s\n%s" % [
			current_character.get_display_name(),
			current_character.get_position_display(character_grid_pos)
		]
		# Also update avatar when character info changes
		update_character_avatar()
	else:
		# Show default character info
		character_info_label.text = "Character: (%d, %d)" % [character_grid_pos.x, character_grid_pos.y]

func setup_character_sheet():
	"""Setup character sheet functionality"""
	# Try to load the character sheet scene
	var character_sheet_scene = load("res://scenes/ui/character_sheet.tscn")
	
	if character_sheet_scene == null:
		print("WARNING: Failed to load character sheet scene, creating instance directly...")
		# Fallback: create character sheet instance directly
		character_sheet = CharacterSheet.new()
		character_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(character_sheet)
		character_sheet.visible = false
		print("Character sheet created directly: ", character_sheet)
	else:
		print("Character sheet scene loaded successfully: ", character_sheet_scene)
		character_sheet = character_sheet_scene.instantiate()
		if character_sheet == null:
			print("ERROR: Failed to instantiate character sheet!")
			return
		add_child(character_sheet)
		character_sheet.visible = false
		print("Character sheet loaded from scene: ", character_sheet)
	
	# Make character avatar clickable
	character_avatar.mouse_filter = Control.MOUSE_FILTER_STOP
	character_avatar.gui_input.connect(_on_character_avatar_input)
	
	# Setup cursor handling for avatar
	setup_avatar_cursor()
	
	# Add a visual indicator that it's clickable
	character_avatar.modulate = Color(1.2, 1.2, 1.2)  # Slightly brighter
	print("Character sheet setup complete - avatar is clickable")



func _on_character_sheet_close():
	"""Handle character sheet close button"""
	if character_sheet:
		character_sheet.visible = false

func setup_avatar_cursor():
	"""Setup cursor handling for character avatar"""
	if CursorManager:
		# Connect mouse enter/exit for avatar
		character_avatar.mouse_entered.connect(_on_avatar_mouse_entered)
		character_avatar.mouse_exited.connect(_on_avatar_mouse_exited)

func _on_avatar_mouse_entered():
	"""Handle mouse entering avatar area"""
	if CursorManager:
		CursorManager.set_clickable_cursor()

func _on_avatar_mouse_exited():
	"""Handle mouse leaving avatar area"""
	if CursorManager:
		CursorManager.reset_cursor()

func _on_character_avatar_input(event: InputEvent):
	"""Handle character avatar input events"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		show_character_sheet()

func show_character_sheet():
	"""Show the character sheet with current character data"""
	if character_sheet == null:
		print("ERROR: Character sheet is null in show_character_sheet!")
		return
	
	# Show the character sheet using the proper show_sheet function
	character_sheet.show_sheet(current_character)
	print("Character sheet displayed")



func update_character_avatar():
	"""Update the character avatar display"""
	if current_character and current_character.is_valid():
		var avatar_path = current_character.get_avatar_path()
		
		print("Loading avatar from: ", avatar_path)
		var avatar_texture = load(avatar_path)
		
		if avatar_texture:
			character_avatar.texture = avatar_texture
			print("Avatar loaded successfully")
		else:
			print("Warning: Failed to load avatar from: ", avatar_path)
			# Clear the avatar if loading fails
			character_avatar.texture = null
	else:
		# Clear avatar if no character data
		character_avatar.texture = null
		print("No character data available for avatar")

func update_info_panel():
	"""Update the map info panel"""
	if MapManager == null:
		print("ERROR: MapManager is null in update_info_panel!")
		map_name_label.text = "Map: Error - MapManager null"
		return
	var map_data = MapManager.get_current_map_info()
	if map_data:
		map_name_label.text = "Map: " + map_data.get("name", "Unknown")
	else:
		map_name_label.text = "Map: Unknown"
	
	# Update character avatar when info panel is updated
	update_character_avatar()
	
	# Show character info if we have a loaded character
	if current_character and current_character.is_valid():
		var character_info = "Character: %s\nRace: %s\nSex: %s" % [
			current_character.name,
			current_character.race_name,
			current_character.sex
		]
		
		# Add some key attributes if available
		if current_character.attributes.has("strength"):
			character_info += "\nStrength: " + str(current_character.attributes.strength)
		if current_character.attributes.has("essence"):
			character_info += "\nEssence: " + str(current_character.attributes.essence)
		
		
		
		# Update tile info label to show character info instead
		tile_info_label.text = character_info

func show_error_message(message: String):
	map_name_label.text = "Error"
	tile_info_label.text = message
	coordinates_label.text = ""

func _on_back_button_pressed():
	print("Returning to main menu...")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

# Debug functions
func _input(event):
	# Cancel path preview with ESC key
	if event.is_action_pressed("ui_cancel") and showing_path_preview:
		print("ESC pressed - canceling path preview")
		clear_path_preview()
		return
	
	# Global input test for debugging
	if event is InputEventMouseButton and event.pressed:
		# Check if mouse is over any Area2D
		if hex_tiles.size() > 0:
			print("Checking first few tiles:")
			for i in range(min(3, hex_tiles.size())):
				var tile = hex_tiles[i]
				var area = tile.get_child(0) as Area2D
				if area:
					var area_global_pos = area.global_position
					var distance = event.position.distance_to(area_global_pos)
					print("Tile %d Area2D global pos: %s, distance to mouse: %.1f" % [i, area_global_pos, distance])
	
	if event.is_action_pressed("ui_accept"):  # Space key or Enter
		if MapManager != null:
			MapManager.print_map_debug()
		else:
			print("ERROR: MapManager is null in input handler!")
	
	# Camera controls
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_H: # Show debug help
				show_debug_help()
			KEY_SPACE: # Print debug info
				print_debug_info()
			KEY_C: # Toggle camera following
				toggle_camera_following()
			KEY_R: # Regenerate overlays
				regenerate_overlays()
	
	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(CameraConstants.ZOOM_IN_FACTOR)  # Zoom in
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(CameraConstants.ZOOM_OUT_FACTOR)  # Zoom out
	
	# Keyboard zoom controls
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_PLUS, KEY_KP_ADD, 61:  # Plus key or numpad plus
				zoom_camera(CameraConstants.ZOOM_IN_FACTOR)  # Zoom in
			KEY_MINUS, KEY_KP_SUBTRACT, 45:  # Minus key or numpad minus
				zoom_camera(CameraConstants.ZOOM_OUT_FACTOR)  # Zoom out
			KEY_0, KEY_KP_0, 48:  # Zero key or numpad zero
				reset_zoom()  # Reset zoom

# Show debug help controls
func show_debug_help():
	print("=== HEX MAP DEBUG CONTROLS ===")
	print("Space - Print debug info")
	print("H - Show this help")
	print("C - Toggle GameWorld following")
	print("R - Regenerate overlays")
	print("Mouse wheel - Zoom in/out")
	print("+ / - keys - Zoom in/out")
	print("0 key - Reset zoom")
	print("First click - Show path preview")
	print("Second click - Execute movement")
	print("ESC - Cancel path preview")
	print("==============================")

func reset_zoom():
	"""Reset zoom to default scale with smooth animation"""
	var tween = create_tween()
	tween.tween_property(camera, "zoom", CameraConstants.INITIAL_ZOOM, CameraConstants.ZOOM_ANIMATION_DURATION)
	
	# Don't auto-center when resetting zoom - let user control the view
	
	print("Zoom reset to default scale (", CameraConstants.INITIAL_ZOOM, ")")

func toggle_camera_following():
	"""Toggle GameWorld following on/off"""
	camera_follow_enabled = !camera_follow_enabled
	print("GameWorld following: ", "ENABLED" if camera_follow_enabled else "DISABLED")
	
	if camera_follow_enabled:
		center_camera_on_character()

func print_debug_info():
	"""Print current map and character debug information"""
	print("=== MAP DEBUG INFO ===")
	print("Character position: ", character_grid_pos)
	print("Character world pos: ", character.position)
	print("GameWorld position: ", game_world.position)
	print("GameWorld following: ", "ENABLED" if camera_follow_enabled else "DISABLED")
	print("GameWorld scale: ", game_world.scale)
	print("Total tiles: ", hex_tiles.size())
	
	# Overlay statistics
	if overlay_manager:
		var overlay_count = overlay_layer.get_child_count()
		print("Overlays placed: ", overlay_count)
		print("Overlay textures loaded: ", overlay_manager.overlay_textures.size())
	
	if selected_tile:
		var tile_data = selected_tile.get_meta("tile_data")
		print("Selected tile: ", tile_data.get("type_name", "unknown"))
		print("Selected tile walkable: ", tile_data.get("is_walkable", false))
		var overlay = selected_tile.get_meta("overlay", null)
		if overlay:
			print("Selected tile has overlay: ", overlay.texture.resource_path.get_file())
		else:
			print("Selected tile has no overlay")
	print("=====================")

func zoom_camera(zoom_factor: float):
	"""Zoom the game world by scaling the Camera2D zoom with smooth animation"""
	var new_zoom = camera.zoom * zoom_factor
	# Clamp zoom using constants
	new_zoom.x = clampf(new_zoom.x, CameraConstants.MIN_ZOOM, CameraConstants.MAX_ZOOM)
	new_zoom.y = clampf(new_zoom.y, CameraConstants.MIN_ZOOM, CameraConstants.MAX_ZOOM)
	
	# Create smooth zoom animation
	var tween = create_tween()
	tween.tween_property(camera, "zoom", new_zoom, CameraConstants.ZOOM_ANIMATION_DURATION)
	
	# Don't auto-center when zooming - let user control the view
	
	print("Camera zoom: ", camera.zoom, " -> ", new_zoom)
	print("Zoom factor applied: ", zoom_factor)

func regenerate_overlays():
	"""Regenerate all overlays for testing"""
	print("=== REGENERATING OVERLAYS ===")
	
	if not overlay_manager:
		print("Overlay manager not initialized")
		return
	
	# Clear existing overlays
	overlay_manager.clear_all_overlays()
	
	# Remove overlay references from tiles
	for tile in hex_tiles:
		tile.set_meta("overlay", null)
	
	# Regenerate overlays for all tiles
	var overlay_count = 0
	for tile in hex_tiles:
		var tile_data = tile.get_meta("tile_data")
		if overlay_manager.should_add_overlay(tile_data):
			overlay_manager.add_overlay_to_tile(tile, tile_data)
			overlay_count += 1
	
	print("Regenerated %d overlays" % overlay_count)
	print("=============================")



func _on_game_world_input(event: InputEvent):
	"""Direct input handler for GameViewportContainer as backup for Area2D"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Convert click position to world coordinates using camera
		var world_click_pos = camera.get_global_mouse_position()
		print("Click position in world coordinates: ", world_click_pos)
		
		# Find which tile was clicked
		var clicked_tile = find_tile_at_world_position(world_click_pos)
		if clicked_tile:
			print("Found clicked tile!")
			select_tile(clicked_tile)
		else:
			print("No tile found at click position")

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
