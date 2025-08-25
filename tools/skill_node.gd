extends Control

signal node_selected(node: Control)
signal node_dragged(node: Control, offset: Vector2)

var node_type: String = "PASSIVE"
var node_types: Array[String] = []
var node_name: String = ""
var description: String = ""
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

@onready var background: ColorRect = $Background
@onready var node_type_label: Label = $NodeTypeLabel
@onready var name_label: Label = $NameLabel

const NODE_SIZES = {
	"PASSIVE": Vector2(40, 40),
	"ACTIVE": Vector2(60, 60),
	"IMPROVEMENT": Vector2(50, 50),
	"MASTER_ATTRIBUTE": Vector2(80, 80),
	"ATTRIBUTE": Vector2(60, 60),
	"EMPTY": Vector2(40, 40)
}

const NODE_COLORS = {
	"PASSIVE": Color(0.5, 0.5, 0.5, 0.8),
	"ACTIVE": Color(0.7, 0.7, 0.7, 0.8),
	"IMPROVEMENT": Color(0.6, 0.6, 0.6, 0.8),
	"MASTER_ATTRIBUTE": Color(0.9, 0.9, 0.9, 0.8),
	"ATTRIBUTE": Color(0.8, 0.8, 0.8, 0.8),
	"EMPTY": Color(0.4, 0.4, 0.4, 0.8)
}

func _ready():
	# Enable input processing
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	
	# Set up visual appearance after scene is ready
	call_deferred("_update_appearance")

func setup(type: String, pos: Vector2):
	node_type = type
	node_types = [type]  # Each node has only one type
	position = pos
	
	# Set size based on node type
	custom_minimum_size = NODE_SIZES[type]
	size = NODE_SIZES[type]
	
	# Update visual appearance after setup
	call_deferred("_update_appearance")

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
	# Set background color based on node type
	if background:
		background.color = NODE_COLORS[node_type]
	
	# Update node type label text - show single type
	if node_type_label:
		node_type_label.text = node_type
	
	# Update name label
	if name_label:
		name_label.text = node_name if node_name != "" else "Node"
	
	# Update size
	custom_minimum_size = NODE_SIZES[node_type]
	size = NODE_SIZES[node_type]

func get_node_type() -> String:
	return node_type

func get_node_types() -> Array[String]:
	return node_types.duplicate()

func get_node_name() -> String:
	return node_name

func get_node_description() -> String:
	return description

func set_node_name(new_name: String):
	node_name = new_name
	call_deferred("_update_appearance")

func set_node_description(new_description: String):
	description = new_description



func _draw():
	# Draw node type indicator (single type per node)
	var color = _get_node_type_color(node_type)
	var rect = Rect2(Vector2(5, 5), Vector2(10, 10))
	draw_rect(rect, color, true)
	draw_rect(rect, Color.WHITE, false, 1.0)

func _get_node_type_color(type: String) -> Color:
	match type:
		"PASSIVE":
			return Color.BLUE
		"ACTIVE":
			return Color.RED
		"IMPROVEMENT":
			return Color.GREEN
		"MASTER_ATTRIBUTE":
			return Color.GOLD
		"ATTRIBUTE":
			return Color.CYAN
		"EMPTY":
			return Color.GRAY
		_:
			return Color.GRAY
