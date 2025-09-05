extends Control

signal node_selected(node: Control)
signal node_dragged(node: Control, offset: Vector2)

var node_type: String = "PASSIVE"
var node_types: Array[String] = []
var node_name: String = ""
var description: String = ""
var icon_name: String = ""
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

@onready var frame: TextureRect = $FrameContainer/Frame
@onready var icon: TextureRect = $IconContainer/Icon
@onready var name_label: Label = $NameLabel

# Use centralized constants from SkillTreeConstants

func _ready():
	# Enable input processing
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	
	# Verify that required nodes are ready
	if not icon:
		print("Warning: Icon node not found in skill_node")
	if not frame:
		print("Warning: Frame node not found in skill_node")
	
	# Set up visual appearance after scene is ready
	call_deferred("_update_appearance")

func setup(type: String, pos: Vector2):
	node_type = type
	node_types = [type]  # Each node has only one type
	position = pos
	
	# Set size based on node type
	custom_minimum_size = SkillTreeConstants.get_node_size(type)
	size = SkillTreeConstants.get_node_size(type)
	
	# Update visual appearance after setup - ensure nodes are ready
	call_deferred("_update_appearance")

func set_icon_name(icon_name_value: String):
	"""Set the icon name and load the corresponding icon"""
	icon_name = icon_name_value
	# Only try to load icon if the node is ready
	if icon:
		_load_icon()
	call_deferred("_update_appearance")

func _load_icon():
	"""Load the icon based on icon_name"""
	# Check if icon node is ready
	if not icon:
		print("Warning: Icon node not ready yet")
		return
	
	if SkillTreeRenderer:
		icon.texture = SkillTreeRenderer.load_icon_texture(icon_name, node_type)
	else:
		# Fallback to old method if utility class not available
		if icon_name.is_empty():
			var default_icon_path = _get_default_icon_path()
			if default_icon_path and ResourceLoader.exists(default_icon_path):
				icon.texture = load(default_icon_path)
			return
		
		var icon_path = SkillTreeConstants.get_icon_path(icon_name, node_type)
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
			print("Loaded icon: ", icon_path)
		else:
			print("Icon not found: ", icon_path)
			# Try to load a default icon as fallback
			var default_icon_path = _get_default_icon_path()
			if default_icon_path and ResourceLoader.exists(default_icon_path):
				icon.texture = load(default_icon_path)

func _get_default_icon_path() -> String:
	"""Get a default icon path based on node type"""
	if SkillTreeRenderer:
		return SkillTreeRenderer.get_icon_path("", node_type)
	else:
		# Use centralized constants
		return SkillTreeConstants.get_icon_path("", node_type)

func _load_frame():
	"""Load the frame based on node type"""
	# Check if frame node is ready
	if not frame:
		print("Warning: Frame node not ready yet")
		return
	
	print("Loading frame for node type: ", node_type)
	
	if SkillTreeRenderer:
		var frame_texture = SkillTreeRenderer.load_frame_texture(node_type)
		if frame_texture:
			frame.texture = frame_texture
			print("Loaded frame via SkillTreeRenderer: ", node_type)
		else:
			print("Failed to load frame via SkillTreeRenderer for: ", node_type)
	else:
		# Fallback to old method if utility class not available
		var frame_path = SkillTreeConstants.get_frame_path(node_type)
		print("Using fallback frame path: ", frame_path)
		if ResourceLoader.exists(frame_path):
			frame.texture = load(frame_path)
			print("Loaded fallback frame: ", frame_path)
		else:
			print("Fallback frame not found: ", frame_path)

func _on_gui_input(event: InputEvent):
	# Let SkillTreeEditor handle input in connect mode and edit mode
	var skill_tree_editor = get_parent()
	if skill_tree_editor.has_method("get_current_mode"):
		var current_mode = skill_tree_editor.get_current_mode()
		if current_mode == "CONNECT" or current_mode == "EDIT":
			return  # Don't consume the event in connect or edit mode
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_left_click(event.position)
			else:
				_handle_left_release(event.position)
	
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event.position)

func _handle_left_click(position: Vector2):
	# Emit selection signal
	node_selected.emit(self)
	
	# Start dragging
	is_dragging = true
	drag_start = position
	# Change appearance to show selection
	modulate = Color.YELLOW

func _handle_left_release(position: Vector2):
	is_dragging = false
	# Reset appearance
	modulate = Color.WHITE

func _handle_mouse_motion(position: Vector2):
	if is_dragging:
		var offset = position - drag_start
		node_dragged.emit(self, offset)

func _update_appearance():
	# Load frame based on node type (only if frame node is ready)
	if frame:
		_load_frame()
	
	# Load icon if not already loaded (only if icon node is ready)
	if icon and not icon.texture:
		_load_icon()
	
	# Update name label
	if name_label:
		name_label.text = node_name if node_name != "" else "Node"
	
	# Update size
	custom_minimum_size = SkillTreeConstants.get_node_size(node_type)
	size = SkillTreeConstants.get_node_size(node_type)
	
	# Update icon container size based on node type
	_update_icon_container_size()

func _update_icon_container_size():
	"""Update the icon container size based on the current node type"""
	if not icon or not icon.get_parent():
		return
	
	var icon_container = icon.get_parent()
	var icon_size = SkillTreeConstants.get_icon_size(node_type)
	
	# Calculate the offset to center the icon
	var offset = icon_size / 2
	
	# Update icon container position and size
	icon_container.custom_minimum_size = icon_size
	icon_container.size = icon_size
	icon_container.position = Vector2.ZERO  # Reset position
	
	# Center the icon container within the node
	var node_size = SkillTreeConstants.get_node_size(node_type)
	icon_container.position = (node_size - icon_size) / 2

func get_node_type() -> String:
	return node_type

func get_node_types() -> Array[String]:
	return node_types.duplicate()

func get_node_name() -> String:
	return node_name

func get_node_description() -> String:
	return description

func get_icon_name() -> String:
	return icon_name

func set_node_name(new_name):
	# Handle null, undefined, or empty names
	if new_name == null or new_name == "":
		node_name = "Node"
	else:
		node_name = str(new_name)
	call_deferred("_update_appearance")

func set_node_description(new_description):
	# Handle null, undefined, or empty descriptions
	if new_description == null or new_description == "":
		description = ""
	else:
		description = str(new_description)

func _draw():
	# Draw node type indicator (single type per node)
	pass
