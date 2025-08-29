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
@onready var node_type_label: Label = $NodeTypeLabel
@onready var name_label: Label = $NameLabel

const NODE_SIZES = {
	"PASSIVE": Vector2(150, 150),
	"ACTIVE": Vector2(100, 100),
	"IMPROVEMENT": Vector2(100, 100),
	"MASTER_ATTRIBUTE": Vector2(150, 150),
	"ATTRIBUTE": Vector2(100, 100),
	"ABILITY": Vector2(75, 75),
	"EMPTY": Vector2(40, 40)
}



# Frame mapping for different node types
const NODE_FRAMES = {
	"PASSIVE": "res://assets/ui/frame_passive.svg",
	"ACTIVE": "res://assets/ui/ability_frame.svg",
	"IMPROVEMENT": "res://assets/ui/skill_improvement_frame.svg",
	"MASTER_ATTRIBUTE": "res://assets/ui/master_attribute_frame.svg",
	"ATTRIBUTE": "res://assets/ui/attribute_frame.svg",
	"ABILITY": "res://assets/ui/ability_frame.svg",
	"EMPTY": "res://assets/ui/frame_passive.svg"
}

# Icon base path
const ICON_BASE_PATH = "res://assets/icons/svgs/"

# Icon sizes for each node type (should be smaller than node size)
const ICON_SIZES = {
	"PASSIVE": Vector2(120, 120),      # 150x150 node, 120x120 icon
	"ACTIVE": Vector2(80, 80),         # 100x100 node, 80x80 icon
	"IMPROVEMENT": Vector2(80, 80),    # 100x100 node, 80x80 icon
	"MASTER_ATTRIBUTE": Vector2(120, 120), # 150x150 node, 120x120 icon
	"ATTRIBUTE": Vector2(80, 80),      # 100x100 node, 80x80 icon
	"ABILITY": Vector2(60, 60),        # 75x75 node, 60x60 icon
	"EMPTY": Vector2(30, 30)           # 40x40 node, 30x30 icon
}

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
	custom_minimum_size = NODE_SIZES[type]
	size = NODE_SIZES[type]
	
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
		
		var icon_path = "res://assets/icons/svgs/" + icon_name + ".svg"
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
		# Fallback to old method if utility class not available
		match node_type:
			"PASSIVE":
				return "res://assets/icons/svgs/stealth.svg"
			"ACTIVE":
				return "res://assets/icons/svgs/sword.svg"
			"IMPROVEMENT":
				return "res://assets/icons/svgs/magic_book.svg"
			"MASTER_ATTRIBUTE":
				return "res://assets/icons/svgs/lion.svg"
			"ATTRIBUTE":
				return "res://assets/icons/svgs/strenght.svg"
			"ABILITY":
				return "res://assets/icons/svgs/anchor.svg"
			"EMPTY":
				return "res://assets/icons/svgs/stealth.svg"
			_:
				return "res://assets/icons/svgs/stealth.svg"

func _load_frame():
	"""Load the frame based on node type"""
	# Check if frame node is ready
	if not frame:
		print("Warning: Frame node not ready yet")
		return
	
	if SkillTreeRenderer:
		frame.texture = SkillTreeRenderer.load_frame_texture(node_type)
	else:
		# Fallback to old method if utility class not available
		var frame_path = "res://assets/ui/frame_passive.svg"  # Default fallback
		if ResourceLoader.exists(frame_path):
			frame.texture = load(frame_path)
			print("Loaded fallback frame: ", frame_path)
		else:
			print("Fallback frame not found: ", frame_path)

func _on_gui_input(event: InputEvent):
	# Let SkillTreeEditor handle input in connect mode
	var skill_tree_editor = get_parent()
	if skill_tree_editor.has_method("get_current_mode") and skill_tree_editor.get_current_mode() == "CONNECT":
		return  # Don't consume the event in connect mode
	
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
	
	# Update node type label text - show single type
	if node_type_label:
		node_type_label.text = node_type
	
	# Update name label
	if name_label:
		name_label.text = node_name if node_name != "" else "Node"
	
	# Update size
	custom_minimum_size = NODE_SIZES.get(node_type, NODE_SIZES["PASSIVE"])
	size = NODE_SIZES.get(node_type, NODE_SIZES["PASSIVE"])
	
	# Update icon container size based on node type
	_update_icon_container_size()

func _update_icon_container_size():
	"""Update the icon container size based on the current node type"""
	if not icon or not icon.get_parent():
		return
	
	var icon_container = icon.get_parent()
	var icon_size = ICON_SIZES.get(node_type, ICON_SIZES["PASSIVE"])
	
	# Calculate the offset to center the icon
	var offset = icon_size / 2
	
	# Update icon container position and size
	icon_container.custom_minimum_size = icon_size
	icon_container.size = icon_size
	icon_container.position = Vector2.ZERO  # Reset position
	
	# Center the icon container within the node
	var node_size = NODE_SIZES.get(node_type, NODE_SIZES["PASSIVE"])
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

func set_node_name(new_name: String):
	node_name = new_name
	call_deferred("_update_appearance")

func set_node_description(new_description: String):
	description = new_description

func _draw():
	# Draw node type indicator (single type per node)
	pass
