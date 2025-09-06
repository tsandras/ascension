extends Control
class_name SkillConnection

## SkillConnection - A visual connection between two skill nodes
##
## This scene represents a connection between two skill nodes and can be
## positioned and styled like any other UI element.

# Node references
@onready var line2d: Line2D = $Line2D

# Connection data
var from_node: Control = null
var to_node: Control = null
var from_id: int = -1
var to_id: int = -1

# Visual properties
var connection_color: Color = Color("#FAB85F")
var line_width: float = 3.0
var parallel_offset: float = 8.0
var show_arrows: bool = true

# Update timer
var update_timer: Timer

func _ready():
	"""Initialize the connection"""
	# Set up update timer to refresh the connection when nodes move
	update_timer = Timer.new()
	update_timer.wait_time = 0.016  # ~60 FPS
	update_timer.timeout.connect(_update_connection)
	add_child(update_timer)
	update_timer.start()
	
	# Initial connection update
	_update_connection()

func setup(from: Control, to: Control, from_node_id: int, to_node_id: int, color: Color = Color("#FAB85F"), width: float = 3.0, offset: float = 8.0, arrows: bool = true):
	"""Set up the connection between two nodes"""
	from_node = from
	to_node = to
	from_id = from_node_id
	to_id = to_node_id
	connection_color = color
	line_width = width
	parallel_offset = offset
	show_arrows = arrows
	
	# Update line properties
	if line2d:
		line2d.default_color = connection_color
		line2d.width = line_width
	
	# Connect to node movement signals if available
	if from_node and from_node.has_signal("node_moved"):
		from_node.node_moved.connect(_on_node_moved)
	if to_node and to_node.has_signal("node_moved"):
		to_node.node_moved.connect(_on_node_moved)

func _update_connection():
	"""Update the connection line based on current node positions"""
	if not from_node or not to_node or not is_instance_valid(from_node) or not is_instance_valid(to_node):
		return
	
	# Calculate positions
	var from_pos = from_node.position + from_node.size / 2
	var to_pos = to_node.position + to_node.size / 2
	
	# Skip if nodes are too close
	if from_pos.distance_to(to_pos) < 5.0:
		line2d.clear_points()
		return
	
	# Generate curved line points
	var points = _generate_curved_line_points(from_pos, to_pos)
	line2d.points = points

func _generate_curved_line_points(from_pos: Vector2, to_pos: Vector2) -> PackedVector2Array:
	"""Generate points for a curved connection line"""
	var points = PackedVector2Array()
	
	var distance = from_pos.distance_to(to_pos)
	var direction = (to_pos - from_pos).normalized()
	var perp = Vector2(-direction.y, direction.x)
	
	# Curve intensity
	var curve_intensity = min(distance * 0.3, 30.0)
	var mid_point = (from_pos + to_pos) / 2
	var control_point = mid_point + perp * curve_intensity
	
	# Generate curve points
	var segments = max(int(distance / 8.0), 12)
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var t_inv = 1.0 - t
		var point = t_inv * t_inv * from_pos + 2 * t_inv * t * control_point + t * t * to_pos
		points.append(point)
	
	return points

func _on_node_moved():
	"""Handle when a connected node moves"""
	_update_connection()

func set_color(color: Color):
	"""Set the connection color"""
	connection_color = color
	if line2d:
		line2d.default_color = color

func set_width(width: float):
	"""Set the connection line width"""
	line_width = width
	if line2d:
		line2d.width = width

func set_parallel_offset(offset: float):
	"""Set the parallel offset for curved lines"""
	parallel_offset = offset

func set_show_arrows(show: bool):
	"""Set whether to show arrows"""
	show_arrows = show

func get_from_node() -> Control:
	"""Get the source node"""
	return from_node

func get_to_node() -> Control:
	"""Get the target node"""
	return to_node

func get_from_id() -> int:
	"""Get the source node ID"""
	return from_id

func get_to_id() -> int:
	"""Get the target node ID"""
	return to_id

func is_connected_to_node(node: Control) -> bool:
	"""Check if this connection is connected to the given node"""
	return from_node == node or to_node == node

func cleanup():
	"""Clean up the connection"""
	if update_timer:
		update_timer.stop()
		update_timer.queue_free()
	queue_free()
