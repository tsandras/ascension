extends Node
class_name CursorManagerClass

# Cursor states
enum CursorState {
	DEFAULT,
	CLICKABLE,
	MOVE,
	ATTACK,
	INTERACT,
	WAIT
}

# Current cursor state
var current_state: CursorState = CursorState.DEFAULT

# Cursor textures for each state
var cursor_textures: Dictionary = {}

# Cursor hotspots (center point of cursor)
var cursor_hotspots: Dictionary = {}

func _ready():
	print("=== CURSOR MANAGER INITIALIZING ===")
	load_cursor_textures()
	setup_default_cursor()
	print("=== CURSOR MANAGER INITIALIZATION COMPLETE ===")

func load_cursor_textures():
	"""Load cursor textures for different states"""
	# Try to load cursor textures, fallback to system cursor if not found
	var default_cursor = load("res://assets/ui/default_cursor.png")
	var clickable_cursor = load("res://assets/ui/clickable_cursor.png")
	
	if default_cursor:
		var scaled_default = scale_texture(default_cursor, 0.8)
		cursor_textures[CursorState.DEFAULT] = scaled_default
		cursor_hotspots[CursorState.DEFAULT] = Vector2(0, 0)
		print("Loaded default cursor texture (scaled to 0.8)")
	else:
		print("Warning: Could not load default cursor texture")
	
	if clickable_cursor:
		var scaled_clickable = scale_texture(clickable_cursor, 0.8)
		cursor_textures[CursorState.CLICKABLE] = scaled_clickable
		cursor_hotspots[CursorState.CLICKABLE] = Vector2(8, 8)
		print("Loaded clickable cursor texture (scaled to 0.8)")
	else:
		print("Warning: Could not load clickable cursor texture")

func scale_texture(texture: Texture2D, scale: float) -> Texture2D:
	"""Scale a texture by the given factor"""
	var image = texture.get_image()
	var new_size = image.get_size() * scale
	
	# Create a new image and copy the original
	var scaled_image = image.duplicate()
	
	# Resize the duplicated image
	scaled_image.resize(int(new_size.x), int(new_size.y), Image.INTERPOLATE_LANCZOS)
	
	# Create a new texture from the scaled image
	var scaled_texture = ImageTexture.create_from_image(scaled_image)
	return scaled_texture
	
	# # Move cursor
	# cursor_textures[CursorState.MOVE] = preload("res://assets/cursors/move_cursor.png")
	# cursor_hotspots[CursorState.MOVE] = Vector2(8, 8)
	
	# # Attack cursor
	# cursor_textures[CursorState.ATTACK] = preload("res://assets/cursors/attack_cursor.png")
	# cursor_hotspots[CursorState.ATTACK] = Vector2(8, 8)
	
	# # Interact cursor
	# cursor_textures[CursorState.INTERACT] = preload("res://assets/cursors/interact_cursor.png")
	# cursor_hotspots[CursorState.INTERACT] = Vector2(8, 8)
	
	# # Wait cursor
	# cursor_textures[CursorState.WAIT] = preload("res://assets/cursors/wait_cursor.png")
	# cursor_hotspots[CursorState.WAIT] = Vector2(8, 8)

func setup_default_cursor():
	"""Set up the default cursor"""
	print("Setting up default cursor...")
	set_cursor_state(CursorState.DEFAULT)
	print("Default cursor setup complete")
	
	# Also set the default cursor globally to ensure it's applied everywhere
	if cursor_textures.has(CursorState.DEFAULT):
		var default_texture = cursor_textures[CursorState.DEFAULT]
		var default_hotspot = cursor_hotspots.get(CursorState.DEFAULT, Vector2.ZERO)
		Input.set_custom_mouse_cursor(default_texture, Input.CURSOR_ARROW, default_hotspot)
		print("Global default cursor set")
	else:
		print("Warning: No default cursor texture available")

func set_cursor_state(state: CursorState):
	"""Change the cursor to the specified state"""
	if state == current_state:
		return
	
	current_state = state
	
	var texture = cursor_textures.get(state)
	var hotspot = cursor_hotspots.get(state, Vector2.ZERO)
	
	if texture:
		Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW, hotspot)
	else:
		# Fallback to default cursor texture if available, otherwise system cursor
		var default_texture = cursor_textures.get(CursorState.DEFAULT)
		if default_texture:
			var default_hotspot = cursor_hotspots.get(CursorState.DEFAULT, Vector2.ZERO)
			Input.set_custom_mouse_cursor(default_texture, Input.CURSOR_ARROW, default_hotspot)
		else:
			Input.set_custom_mouse_cursor(null)
		print("Warning: No texture for cursor state: ", state, " - using default cursor")

func set_clickable_cursor():
	"""Set cursor to clickable state"""
	set_cursor_state(CursorState.CLICKABLE)

# func set_move_cursor():
# 	"""Set cursor to move state"""
# 	set_cursor_state(CursorState.MOVE)

# func set_attack_cursor():
# 	"""Set cursor to attack state"""
# 	set_cursor_state(CursorState.ATTACK)

# func set_interact_cursor():
# 	"""Set cursor to interact state"""
# 	set_cursor_state(CursorState.INTERACT)

# func set_wait_cursor():
# 	"""Set cursor to wait state"""
# 	set_cursor_state(CursorState.WAIT)

func reset_cursor():
	"""Reset cursor to default state"""
	set_cursor_state(CursorState.DEFAULT)

func get_current_state() -> CursorState:
	"""Get the current cursor state"""
	return current_state 
