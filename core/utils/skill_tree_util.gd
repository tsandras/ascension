extends RefCounted
class_name SkillTreeUtil

## SkillTreeUtil - Common utilities for skill tree operations
##
## This utility class contains shared functionality used by skill tree
## display, editor, and creator components to avoid code duplication.

# Constants
const SKILL_NODE_SCENE = preload("res://tools/skill_node.tscn")

# Default configuration
const DEFAULT_CONNECTION_COLOR = Color("#FAB85F")
const DEFAULT_LINE_WIDTH = 3.0
const DEFAULT_PARALLEL_OFFSET = 8.0
const DEFAULT_CURVE_INTENSITY_MULTIPLIER = 0.3
const DEFAULT_MAX_CURVE_INTENSITY = 30.0
const DEFAULT_SEGMENTS_PER_DISTANCE = 8.0
const DEFAULT_MIN_SEGMENTS = 12

# Dotted line configuration
const DEFAULT_MIN_DOT_LENGTH = 4.0
const DEFAULT_MAX_DOT_LENGTH = 10.0
const DEFAULT_MIN_GAP_LENGTH = 10.0
const DEFAULT_MAX_GAP_LENGTH = 16.0

## Create a skill node from database data
static func create_skill_node(node_data: Dictionary, position: Vector2, parent_container: Control, is_interactive: bool = true) -> Control:
	"""Create a visual skill node from database data"""
	var node_scene = SKILL_NODE_SCENE.instantiate()
	
	# Set up the node
	var node_type = node_data.get("node_type", "PASSIVE")
	node_scene.setup(node_type, position)
	node_scene.set_node_name(node_data.get("name", ""))
	node_scene.set_node_description(node_data.get("description", ""))
	
	# Set icon if available
	if node_data.has("icon_name") and node_data.icon_name:
		node_scene.set_icon_name(node_data.icon_name)
	
	# Store node data
	node_scene.set_meta("node_data", node_data)
	node_scene.set_meta("database_id", node_data.id)
	
	# Add to container
	parent_container.add_child(node_scene)
	
	return node_scene

## Draw curved connection between two points
static func draw_curved_connection(canvas_item: CanvasItem, from_pos: Vector2, to_pos: Vector2, color: Color = DEFAULT_CONNECTION_COLOR, line_width: float = DEFAULT_LINE_WIDTH, parallel_offset: float = DEFAULT_PARALLEL_OFFSET):
	"""Draw a fancy curved connection with two parallel lines - one solid and one dotted"""
	var distance = from_pos.distance_to(to_pos)
	
	# Calculate control points for the curve
	var mid_point = (from_pos + to_pos) / 2
	var direction = (to_pos - from_pos).normalized()
	var perp = Vector2(-direction.y, direction.x)
	
	# Curve intensity - adjust this value to control how curved the lines are
	var curve_intensity = min(distance * DEFAULT_CURVE_INTENSITY_MULTIPLIER, DEFAULT_MAX_CURVE_INTENSITY)
	
	# Control point for the main curve
	var control_point = mid_point + perp * curve_intensity
	
	# Control point for the parallel curve (offset)
	var parallel_control_point = mid_point + perp * (curve_intensity + parallel_offset)
	
	# Draw the curved lines using multiple line segments
	var segments = max(int(distance / DEFAULT_SEGMENTS_PER_DISTANCE), DEFAULT_MIN_SEGMENTS)
	var prev_point_main = from_pos
	var prev_point_parallel = from_pos + perp * parallel_offset
	
	for i in range(1, segments + 1):
		var t = float(i) / float(segments)
		
		# Quadratic Bezier curve calculation for main line
		var t_inv = 1.0 - t
		var current_point_main = t_inv * t_inv * from_pos + 2 * t_inv * t * control_point + t * t * to_pos
		
		# Quadratic Bezier curve calculation for parallel line
		var parallel_start = from_pos + perp * parallel_offset
		var parallel_end = to_pos + perp * parallel_offset
		var current_point_parallel = t_inv * t_inv * parallel_start + 2 * t_inv * t * parallel_control_point + t * t * parallel_end
		
		# Draw main solid line
		canvas_item.draw_line(prev_point_main, current_point_main, color, line_width)
		
		# Draw parallel dotted line
		draw_dotted_line(canvas_item, prev_point_parallel, current_point_parallel, color, line_width * 0.7)
		
		prev_point_main = current_point_main
		prev_point_parallel = current_point_parallel

## Draw dotted line with irregular segments
static func draw_dotted_line(canvas_item: CanvasItem, from_pos: Vector2, to_pos: Vector2, color: Color, width: float, min_dot_length: float = DEFAULT_MIN_DOT_LENGTH, max_dot_length: float = DEFAULT_MAX_DOT_LENGTH, min_gap_length: float = DEFAULT_MIN_GAP_LENGTH, max_gap_length: float = DEFAULT_MAX_GAP_LENGTH):
	"""Draw a dotted line with irregular segments between two points"""
	var distance = from_pos.distance_to(to_pos)
	
	var direction = (to_pos - from_pos).normalized()
	var current_pos = from_pos
	var total_distance = 0.0
	var is_dot = true  # Start with a dot
	
	while total_distance < distance:
		var remaining_distance = distance - total_distance
		
		# Generate random segment length based on whether we're drawing a dot or gap
		var segment_length = 0.0
		if is_dot:
			# Random dot length
			segment_length = randf_range(min_dot_length, max_dot_length)
		else:
			# Random gap length
			segment_length = randf_range(min_gap_length, max_gap_length)
		
		# Don't exceed remaining distance
		segment_length = min(segment_length, remaining_distance)
		
		if is_dot:
			# Draw the dot segment
			var dot_end = current_pos + direction * segment_length
			canvas_item.draw_line(current_pos, dot_end, color, width)
		
		# Move to next segment
		current_pos = current_pos + direction * segment_length
		total_distance += segment_length
		
		# Toggle between dot and gap
		is_dot = !is_dot

## Draw arrow at the end of a connection
static func draw_connection_arrow(canvas_item: CanvasItem, from_pos: Vector2, to_pos: Vector2, color: Color, arrow_size: float = 8.0):
	"""Draw an arrow at the end of a connection"""
	var distance = from_pos.distance_to(to_pos)
	
	# Only draw arrow if there's enough distance
	if distance > 20.0:
		var direction = (to_pos - from_pos).normalized()
		var arrow_pos = to_pos - direction * arrow_size
		
		# Ensure arrow points are valid
		var perp = Vector2(-direction.y, direction.x)
		var arrow_point1 = arrow_pos + direction * arrow_size + perp * arrow_size * 0.5
		var arrow_point2 = arrow_pos + direction * arrow_size - perp * arrow_size * 0.5
		
		# Validate polygon points before drawing
		var polygon_points = [to_pos, arrow_point1, arrow_point2]
		if is_valid_polygon(polygon_points):
			canvas_item.draw_colored_polygon(polygon_points, color)

## Check if polygon is valid for drawing
static func is_valid_polygon(points: Array) -> bool:
	"""Check if polygon has at least 3 points and valid Vector2s"""
	# Check if polygon has at least 3 points
	if points.size() < 3:
		return false
	
	# Check if all points are valid Vector2
	for point in points:
		if not point is Vector2:
			return false
		if point.x == INF or point.y == INF or point.x == -INF or point.y == -INF:
			return false
		if point.x == NAN or point.y == NAN:
			return false
	
	# Check if polygon has area (not all points in a line)
	var first_point = points[0]
	var second_point = points[1]
	var direction = (second_point - first_point).normalized()
	
	var all_in_line = true
	for i in range(2, points.size()):
		var point = points[i]
		var to_first = (point - first_point).normalized()
		if abs(to_first.dot(direction)) < 0.99:  # Allow small deviation
			all_in_line = false
			break
	
	return not all_in_line

## Get node at position
static func get_node_at_position(nodes: Array[Control], position: Vector2) -> Control:
	"""Get the node at the specified position"""
	for node in nodes:
		var node_rect = Rect2(node.position, node.size)
		if node_rect.has_point(position):
			return node
	return null

## Get node by database ID
static func get_node_by_database_id(nodes: Array[Control], database_id: int) -> Control:
	"""Get a skill node by its database ID"""
	for node in nodes:
		if node.has_meta("database_id") and node.get_meta("database_id") == database_id:
			return node
	return null

## Deselect all nodes
static func deselect_all_nodes(nodes: Array[Control]):
	"""Deselect all skill nodes"""
	for node in nodes:
		if node.has_method("set_selected"):
			node.set_selected(false)

## Clear skill tree nodes
static func clear_skill_tree_nodes(nodes: Array[Control]):
	"""Clear all skill tree nodes"""
	for node in nodes:
		node.queue_free()
	nodes.clear()

## Load skill tree data from database
static func load_skill_tree_from_database(skill_tree_id: int) -> Dictionary:
	"""Load skill tree data from database by ID"""
	if not DatabaseManager:
		print("Error: DatabaseManager not available")
		return {}
	
	var skill_tree_data = DatabaseManager.get_skill_tree_by_id(skill_tree_id)
	if skill_tree_data.size() == 0:
		print("Error: Skill tree not found with ID: ", skill_tree_id)
		return {}
	
	return skill_tree_data

## Load skill tree data by name
static func load_skill_tree_by_name(skill_tree_name: String) -> Dictionary:
	"""Load skill tree data from database by name"""
	if not DatabaseManager:
		print("Error: DatabaseManager not available")
		return {}
	
	# Get all skill trees and find by name
	var skill_trees = DatabaseManager.get_all_skill_trees()
	for skill_tree in skill_trees:
		if skill_tree.name == skill_tree_name:
			return load_skill_tree_from_database(skill_tree.id)
	
	print("Error: Skill tree not found with name: ", skill_tree_name)
	return {}

## Parse skill tree data
static func parse_skill_tree_data(skill_tree_data: Dictionary) -> Dictionary:
	"""Parse skill tree data and return nodes and connections"""
	print("Parsing skill tree data: ", skill_tree_data)
	
	var result = {
		"nodes": [],
		"connections": []
	}
	
	if skill_tree_data.has("data_dict"):
		print("Found data_dict, extracting nodes and connections")
		result.nodes = skill_tree_data.data_dict.get("nodes", [])
		result.connections = skill_tree_data.data_dict.get("connections", [])
		print("Extracted nodes: ", result.nodes)
		print("Extracted connections: ", result.connections)
	else:
		print("No data_dict found, using direct access")
		result.nodes = skill_tree_data.get("nodes", [])
		result.connections = skill_tree_data.get("connections", [])
		print("Direct nodes: ", result.nodes)
		print("Direct connections: ", result.connections)
	
	print("Final result: ", result)
	return result

## Create connection between two nodes
static func create_connection(from_node: Control, to_node: Control, from_id: int, to_id: int) -> Dictionary:
	"""Create a connection data structure between two nodes"""
	return {
		"from_node": from_node,
		"to_node": to_node,
		"from_id": from_id,
		"to_id": to_id
	}

## Draw all connections
static func draw_all_connections(canvas_item: CanvasItem, connections: Array[Dictionary], color: Color = DEFAULT_CONNECTION_COLOR, line_width: float = DEFAULT_LINE_WIDTH, parallel_offset: float = DEFAULT_PARALLEL_OFFSET, show_arrows: bool = true):
	"""Draw all connections in a skill tree"""
	for connection in connections:
		var from_node = connection.from_node
		var to_node = connection.to_node
		
		if from_node and to_node and is_instance_valid(from_node) and is_instance_valid(to_node):
			var from_pos = from_node.position + from_node.size / 2
			var to_pos = to_node.position + to_node.size / 2
			
			# Skip connections that are too close
			if from_pos.distance_to(to_pos) < 5.0:
				continue
			
			# Draw curved connection line
			draw_curved_connection(canvas_item, from_pos, to_pos, color, line_width, parallel_offset)
			
			# Draw arrow at the end (only if there's enough distance)
			if show_arrows:
				draw_connection_arrow(canvas_item, from_pos, to_pos, color)

## Draw all connections with offset
static func draw_all_connections_with_offset(canvas_item: CanvasItem, connections: Array[Dictionary], color: Color = DEFAULT_CONNECTION_COLOR, line_width: float = DEFAULT_LINE_WIDTH, parallel_offset: float = DEFAULT_PARALLEL_OFFSET, show_arrows: bool = true, offset: Vector2 = Vector2.ZERO):
	"""Draw all connections in a skill tree with a coordinate offset"""
	for connection in connections:
		var from_node = connection.from_node
		var to_node = connection.to_node
		
		if from_node and to_node and is_instance_valid(from_node) and is_instance_valid(to_node):
			var from_pos = from_node.position + from_node.size / 2 + offset
			var to_pos = to_node.position + to_node.size / 2 + offset
			
			# Skip connections that are too close
			if from_pos.distance_to(to_pos) < 5.0:
				continue
			
			# Draw curved connection line
			draw_curved_connection(canvas_item, from_pos, to_pos, color, line_width, parallel_offset)
			
			# Draw arrow at the end (only if there's enough distance)
			if show_arrows:
				draw_connection_arrow(canvas_item, from_pos, to_pos, color)