extends Control

# Map manager instance
var map_manager: MapManager

# UI references
@onready var scroll_container = $ScrollContainer
@onready var map_canvas = $ScrollContainer/MapCanvas
@onready var info_panel = $InfoPanel
@onready var map_name_label = $InfoPanel/VBoxContainer/MapNameLabel
@onready var tile_info_label = $InfoPanel/VBoxContainer/TileInfoLabel
@onready var coordinates_label = $InfoPanel/VBoxContainer/CoordinatesLabel
@onready var back_button = $InfoPanel/VBoxContainer/BackButton

# Tile rendering
var hex_tiles = []
var selected_tile = null

# Tile image cache
var tile_textures = {}

func _ready():
	print("HexMap scene loaded")
	
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
	else:
		print("Failed to initialize map")
		show_error_message("Failed to load map data")

func load_tile_textures():
	print("Loading tile textures...")
	
	# Get all ref_tiles from database to load their textures
	var ref_tiles = DatabaseManager.get_all_ref_tiles()
	
	for tile_ref in ref_tiles:
		var texture_path = tile_ref.get("texture_path", "")
		var type_name = tile_ref.get("type_name", "")
		
		if texture_path != "":
			var texture = load(texture_path)
			if texture != null:
				# Resize source textures to display size for consistent fixed size
				var resized_texture = resize_texture(texture, HexTileConstants.TILE_WIDTH, HexTileConstants.TILE_HEIGHT)
				tile_textures[type_name] = resized_texture
				print("Loaded and resized texture for %s: %s (%dx%d -> %dx%d)" % [type_name, texture_path, HexTileConstants.SOURCE_TEXTURE_WIDTH, HexTileConstants.SOURCE_TEXTURE_HEIGHT, HexTileConstants.TILE_WIDTH, HexTileConstants.TILE_HEIGHT])
			else:
				print("Warning: Could not load texture: %s" % texture_path)
	
	print("Loaded %d tile textures" % tile_textures.size())

# Resize a texture to specified dimensions
func resize_texture(original_texture: Texture2D, new_width: int, new_height: int) -> ImageTexture:
	# Get the image from the texture
	var image = original_texture.get_image()
	
	# Resize the image using Lanczos interpolation for good quality
	image.resize(new_width, new_height, Image.INTERPOLATE_LANCZOS)
	
	# Create a new ImageTexture from the resized image
	var new_texture = ImageTexture.new()
	new_texture.set_image(image)
	
	return new_texture

func setup_map_display():
	print("Setting up map display...")
	
	# Clear any existing tiles
	for child in map_canvas.get_children():
		child.queue_free()
	hex_tiles.clear()
	
	# Get map info and tiles
	var map_info = map_manager.get_current_map_info()
	var tiles = map_manager.get_current_tiles()
	
	print("Rendering %d tiles for map: %s" % [tiles.size(), map_info["name"]])
	print("Using hex spacing: %.1fx%.1f" % [map_manager.hex_horiz_spacing, map_manager.hex_vert_spacing])
	
	# Calculate map canvas size needed
	var max_x = 0
	var max_y = 0
	
	# Create hexagonal tiles
	for tile_data in tiles:
		var grid_x = tile_data["x"]
		var grid_y = tile_data["y"]
		
		# Convert grid position to screen position using actual image-based calculations
		var screen_pos = map_manager.grid_to_screen_position(grid_x, grid_y)
		
		# Track maximum positions for canvas sizing (add image dimensions for proper bounds)
		max_x = max(max_x, screen_pos.x + map_manager.hex_image_width)
		max_y = max(max_y, screen_pos.y + map_manager.hex_image_height)
		
		# Create the hex tile visual
		print("Creating hex tile at (%d, %d)" % [grid_x, grid_y])
		print("Screen position: %s" % str(screen_pos))
		print("Tile data: %s" % str(tile_data))
		create_hex_tile(tile_data, screen_pos)
	
	# Set canvas size to fit all tiles with padding
	map_canvas.custom_minimum_size = Vector2(max_x + HexTileConstants.MAP_CANVAS_PADDING, max_y + HexTileConstants.MAP_CANVAS_PADDING)
	
	print("Map canvas size set to: %s" % str(map_canvas.custom_minimum_size))

func create_hex_tile(tile_data: Dictionary, tile_position: Vector2):
	# Create a TextureRect for each hex tile using actual image dimensions
	var hex_tile = TextureRect.new()
	
	# Load the tile texture based on type_name
	var type_name = tile_data.get("type_name", "forest")
	var texture = tile_textures.get(type_name)
	
	if texture != null:
		# Use the actual image size
		var image_width = texture.get_width()
		var image_height = texture.get_height()
		
		hex_tile.size = Vector2(image_width, image_height)
		hex_tile.position = tile_position
		hex_tile.texture = texture
		hex_tile.stretch_mode = TextureRect.STRETCH_KEEP
		
		print("Created tile at (%d,%d) using texture for: %s (size: %dx%d)" % [tile_data["x"], tile_data["y"], type_name, image_width, image_height])
	else:
		# Fallback to colored rectangle if texture not available
		print("Warning: No texture found for type: %s, using fallback color" % type_name)
		
		# Use the map manager's hex dimensions for fallback
		var fallback_width = map_manager.hex_image_width
		var fallback_height = map_manager.hex_image_height
		
		hex_tile.size = Vector2(fallback_width, fallback_height)
		hex_tile.position = tile_position
		
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(fallback_width, fallback_height)
		var color_hex = tile_data.get("color_hex", HexTileConstants.DEFAULT_FALLBACK_COLOR)
		color_rect.color = Color(color_hex)
		hex_tile.add_child(color_rect)
	
	# Store tile data for interaction
	hex_tile.set_meta("tile_data", tile_data)
	hex_tile.set_meta("grid_pos", Vector2i(tile_data["x"], tile_data["y"]))
	hex_tile.set_meta("original_modulate", hex_tile.modulate)
	
	# Add mouse interaction
	hex_tile.mouse_entered.connect(_on_tile_mouse_entered.bind(hex_tile))
	hex_tile.mouse_exited.connect(_on_tile_mouse_exited.bind(hex_tile))
	hex_tile.gui_input.connect(_on_tile_input.bind(hex_tile))
	
	# Add to canvas and track
	map_canvas.add_child(hex_tile)
	hex_tiles.append(hex_tile)

func _on_tile_mouse_entered(tile: TextureRect):
	# Highlight tile on hover (using modulate for TextureRect)
	tile.modulate = Color(HexTileConstants.HOVER_BRIGHTNESS, HexTileConstants.HOVER_BRIGHTNESS, HexTileConstants.HOVER_BRIGHTNESS, 1.0)
	
	# Update tile info
	update_tile_info(tile.get_meta("tile_data"))

func _on_tile_mouse_exited(tile: TextureRect):
	# Remove highlight only if this tile is not selected
	if tile != selected_tile:
		tile.modulate = tile.get_meta("original_modulate")

func _on_tile_input(event: InputEvent, tile: TextureRect):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_tile(tile)

func select_tile(tile: TextureRect):
	# Deselect previous tile
	if selected_tile != null:
		selected_tile.modulate = selected_tile.get_meta("original_modulate")
	
	# Select new tile
	selected_tile = tile
	tile.modulate = Color(HexTileConstants.SELECTION_BRIGHTNESS, HexTileConstants.SELECTION_BRIGHTNESS, HexTileConstants.SELECTION_YELLOW_TINT, 1.0)
	
	# Update info panel
	update_tile_info(tile.get_meta("tile_data"))
	
	# Update coordinates
	var grid_pos = tile.get_meta("grid_pos")
	coordinates_label.text = "Position: (%d, %d)" % [grid_pos.x, grid_pos.y]
	
	print("Selected tile at (%d, %d): %s" % [grid_pos.x, grid_pos.y, tile.get_meta("tile_data")["type_name"]])

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

func update_info_panel():
	var map_info = map_manager.get_current_map_info()
	if map_info.is_empty():
		map_name_label.text = "Unknown Map"
		return
	
	map_name_label.text = "%s\n%dx%d tiles" % [map_info["name"], map_info["width"], map_info["height"]]

func show_error_message(message: String):
	map_name_label.text = "Error"
	tile_info_label.text = message
	coordinates_label.text = ""

func _on_back_button_pressed():
	print("Returning to main menu...")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

# Debug functions
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key or Enter
		if map_manager:
			map_manager.print_map_debug()
	
	# Update tile paths with U key (for development/migration)
	if event.is_action_pressed("ui_cancel"):  # Escape key, or use a custom key
		update_tile_paths_debug()
	
	# Real-time spacing adjustment for debugging gaps
	if event is InputEventKey and event.pressed:
		var spacing_changed = false
		var step_size = HexTileConstants.DEBUG_SPACING_STEP
		
		match event.keycode:
			KEY_Q: # Decrease horizontal spacing
				map_manager.hex_horiz_spacing -= step_size
				spacing_changed = true
			KEY_W: # Increase horizontal spacing
				map_manager.hex_horiz_spacing += step_size
				spacing_changed = true
			KEY_A: # Decrease vertical spacing
				map_manager.hex_vert_spacing -= step_size
				spacing_changed = true
			KEY_S: # Increase vertical spacing
				map_manager.hex_vert_spacing += step_size
				spacing_changed = true
			KEY_R: # Reset to default spacing
				map_manager.load_hex_tile_dimensions()
				spacing_changed = true
				print("Reset to default spacing")
			KEY_T: # Save current spacing (print values to copy to code)
				save_current_spacing()
		
		if spacing_changed:
			print("=== SPACING ADJUSTMENT ===")
			print("Horizontal: %.1f (Q/W to adjust)" % map_manager.hex_horiz_spacing)
			print("Vertical: %.1f (A/S to adjust)" % map_manager.hex_vert_spacing)
			print("Press R to reset, T to save current values")
			print("========================")
			# Refresh the map with new spacing
			setup_map_display()
	
	# Show debug help
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		show_debug_help()
	
	# Zoom with mouse wheel (simple zoom)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_map(HexTileConstants.ZOOM_IN_FACTOR)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_map(HexTileConstants.ZOOM_OUT_FACTOR)

# Show debug help controls
func show_debug_help():
	print("=== HEX MAP DEBUG CONTROLS ===")
	print("Space/Enter - Print map debug info")
	print("Escape - Update tile texture paths")
	print("Q/W - Decrease/Increase horizontal spacing")
	print("A/S - Decrease/Increase vertical spacing")
	print("R - Reset spacing to defaults")
	print("T - Save current spacing values")
	print("H - Show this help")
	print("Mouse Wheel - Zoom in/out")
	print("==============================")

# Debug function to update tile texture paths (press Escape key)
func update_tile_paths_debug():
	print("=== UPDATING TILE TEXTURE PATHS ===")
	if DatabaseManager.update_tile_texture_paths():
		print("Successfully updated tile texture paths")
		# Reload textures with new paths
		tile_textures.clear()
		load_tile_textures()
		# Refresh the map display
		setup_map_display()
	else:
		print("Failed to update tile texture paths")
	print("=====================================")

# Debug function to save current spacing values
func save_current_spacing():
	print("=== CURRENT OPTIMAL SPACING ===")
	print("Copy these values to map_manager.gd:")
	print("")
	var h_multiplier = map_manager.hex_horiz_spacing / map_manager.hex_image_width
	var v_multiplier = map_manager.hex_vert_spacing / map_manager.hex_image_height
	print("hex_horiz_spacing = hex_image_width * %.3f  # %.1fpx" % [h_multiplier, map_manager.hex_horiz_spacing])
	print("hex_vert_spacing = hex_image_height * %.3f  # %.1fpx" % [v_multiplier, map_manager.hex_vert_spacing])
	print("")
	print("================================")

func zoom_map(factor: float):
	var current_scale = map_canvas.scale
	var new_scale = current_scale * factor
	
	# Limit zoom levels
	new_scale = new_scale.clamp(Vector2(HexTileConstants.MIN_ZOOM_SCALE, HexTileConstants.MIN_ZOOM_SCALE), Vector2(HexTileConstants.MAX_ZOOM_SCALE, HexTileConstants.MAX_ZOOM_SCALE))
	
	map_canvas.scale = new_scale 
