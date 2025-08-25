extends Control

const NODE_SCENES = {
	"PASSIVE": preload("res://tools/skill_node.tscn"),
	"ACTIVE": preload("res://tools/skill_node.tscn"),
	"IMPROVEMENT": preload("res://tools/skill_node.tscn"),
	"MASTER_ATTRIBUTE": preload("res://tools/skill_node.tscn"),
	"ATTRIBUTE": preload("res://tools/skill_node.tscn"),
	"EMPTY": preload("res://tools/skill_node.tscn")
}

const NODE_SIZES = {
	"PASSIVE": Vector2(40, 40),
	"ACTIVE": Vector2(60, 60),
	"IMPROVEMENT": Vector2(50, 50),
	"MASTER_ATTRIBUTE": Vector2(80, 80),
	"ATTRIBUTE": Vector2(60, 60),
	"EMPTY": Vector2(40, 40)
}

var skill_tree_creator: Control
var current_node_type: String = "PASSIVE"
var current_mode: String = "PLACE"

var nodes: Array[Control] = []
var connections: Array[Dictionary] = []
var selected_node: Control = null
var connecting_node: Control = null
var drag_offset: Vector2 = Vector2.ZERO

func setup(creator: Control):
	skill_tree_creator = creator
	# Enable input processing
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func get_current_mode() -> String:
	return current_mode



func set_node_type(node_type):
	if node_type is int:
		# Convert enum to string
		match node_type:
			0: current_node_type = "PASSIVE"
			1: current_node_type = "ACTIVE"
			2: current_node_type = "IMPROVEMENT"
			3: current_node_type = "MASTER_ATTRIBUTE"
			4: current_node_type = "ATTRIBUTE"
			5: current_node_type = "EMPTY"
	else:
		current_node_type = str(node_type)

func set_mode(mode):
	if mode is int:
		# Convert enum to string
		match mode:
			0: current_mode = "PLACE"
			1: current_mode = "CONNECT"
			2: current_mode = "EDIT"
	else:
		current_mode = str(mode)
	
	print("Mode changed to: ", current_mode)  # Debug output
	
	# Update cursor and interaction behavior
	match current_mode:
		"PLACE":
			# Default cursor for placing nodes
			pass
		"CONNECT":
			# Show connection cursor
			pass
		"EDIT":
			# Show edit cursor
			pass

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_left_click(event.position)
			else:
				_handle_left_release(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_handle_right_click(event.position)
	
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event.position)

func _handle_left_click(position: Vector2):
	match current_mode:
		"PLACE":
			_place_node(position)
		"CONNECT":
			_handle_connection_click(position)
		"EDIT":
			_select_node_at_position(position)

func _handle_left_release(position: Vector2):
	if current_mode == "EDIT" and selected_node:
		selected_node = null

func _handle_right_click(position: Vector2):
	if current_mode == "EDIT":
		_delete_node_at_position(position)

func _handle_mouse_motion(position: Vector2):
	if current_mode == "EDIT" and selected_node:
		selected_node.position = position - drag_offset
		# Redraw connections when nodes move
		queue_redraw()
		
		# Force immediate redraw for smooth dragging
		if Engine.get_process_frames() % 2 == 0:  # Redraw every other frame for performance
			queue_redraw()

func _place_node(position: Vector2):
	var node_scene = NODE_SCENES[current_node_type]
	var node = node_scene.instantiate()
	
	# Set node properties - each node has only one type
	node.setup(current_node_type, position)
	node.position = position
	
	# Connect node signals
	node.node_selected.connect(_on_node_selected)
	node.node_dragged.connect(_on_node_dragged)
	
	add_child(node)
	nodes.append(node)
	
	# Update node info panel
	skill_tree_creator.update_node_info("", "")

func _handle_connection_click(position: Vector2):
	print("Connection click at position: ", position)  # Debug output
	var clicked_node = _get_node_at_position(position)
	if not clicked_node:
		print("No node found at position")  # Debug output
		return
	
	print("Node found: ", clicked_node.name)  # Debug output
	
	if not connecting_node:
		connecting_node = clicked_node
		# Visual feedback for connection mode
		clicked_node.modulate = Color.YELLOW
		print("First node selected for connection")  # Debug output
	else:
		if connecting_node != clicked_node:
			print("Creating connection between nodes")  # Debug output
			_create_connection(connecting_node, clicked_node)
		else:
			print("Same node clicked twice, ignoring")  # Debug output
		
		# Reset connection mode
		connecting_node.modulate = Color.WHITE
		connecting_node = null

func _create_connection(from_node: Control, to_node: Control):
	print("Creating connection from ", from_node.name, " to ", to_node.name)  # Debug output
	
	# Check if connection already exists
	for connection in connections:
		if (connection.from_node == from_node and connection.to_node == to_node) or \
		   (connection.from_node == to_node and connection.to_node == from_node):
			print("Connection already exists, skipping")  # Debug output
			return
	
	var connection = {
		"from_node": from_node,
		"to_node": to_node,
		"id": str(randi())
	}
	
	connections.append(connection)
	print("Connection created! Total connections: ", connections.size())  # Debug output
	
	# Create visual connection line
	queue_redraw()

func _select_node_at_position(position: Vector2):
	var node = _get_node_at_position(position)
	if node:
		selected_node = node
		drag_offset = position - node.position
		# Update node info panel
		skill_tree_creator.update_node_info(node.get_node_name(), node.get_node_description())

func _delete_node_at_position(position: Vector2):
	var node = _get_node_at_position(position)
	if node:
		# Remove connections involving this node
		connections = connections.filter(func(conn): 
			return conn.from_node != node and conn.to_node != node
		)
		
		# Remove node
		nodes.erase(node)
		node.queue_free()
		
		# Clear selection if this was the selected node
		if selected_node == node:
			selected_node = null
			skill_tree_creator.update_node_info("", "")
		
		queue_redraw()

func _get_node_at_position(position: Vector2) -> Control:
	print("Looking for node at position: ", position)  # Debug output
	print("Total nodes: ", nodes.size())  # Debug output
	
	for i in range(nodes.size()):
		var node = nodes[i]
		var node_rect = Rect2(node.position, node.size)
		
		print("Node ", i, " position: ", node.position, " size: ", node.size)  # Debug output
		print("  Node rect: ", node_rect, " (from ", node_rect.position, " to ", node_rect.end, ")")  # Debug output
		print("  Distance from click: ", position.distance_to(node.position + node.size/2))  # Debug output
		
		# Try both exact rect check and distance check
		var in_rect = node_rect.has_point(position)
		var close_enough = position.distance_to(node.position + node.size/2) < 100  # Increased to 100px tolerance
		
		print("  In rect: ", in_rect, " Close enough: ", close_enough)  # Debug output
		
		if in_rect or close_enough:
			print("Found node at index: ", i)  # Debug output
			return node
	
	print("No node found at position")  # Debug output
	return null

func _on_node_selected(node: Control):
	selected_node = node
	skill_tree_creator.update_node_info(node.get_node_name(), node.get_node_description())

func _on_node_dragged(node: Control, offset: Vector2):
	if current_mode == "EDIT":
		drag_offset = offset

func _is_valid_polygon(points: Array) -> bool:
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



func _draw():
	# Draw connections
	for connection in connections:
		if connection.from_node and connection.to_node and is_instance_valid(connection.from_node) and is_instance_valid(connection.to_node):
			var from_pos = connection.from_node.position + connection.from_node.size / 2
			var to_pos = connection.to_node.position + connection.to_node.size / 2
			
			# Check if positions are valid and not too close
			if from_pos.distance_to(to_pos) < 5.0:
				continue  # Skip connections that are too close
			
			# Draw connection line
			draw_line(from_pos, to_pos, Color.WHITE, 3.0)
			
			# Draw arrow at the end (only if there's enough distance)
			if from_pos.distance_to(to_pos) > 20.0:
				var direction = (to_pos - from_pos).normalized()
				var arrow_size = 8.0
				var arrow_pos = to_pos - direction * arrow_size
				
				# Ensure arrow points are valid
				var perp = Vector2(-direction.y, direction.x)
				var arrow_point1 = arrow_pos + direction * arrow_size + perp * arrow_size * 0.5
				var arrow_point2 = arrow_pos + direction * arrow_size - perp * arrow_size * 0.5
				
				# Validate polygon points before drawing
				var polygon_points = [to_pos, arrow_point1, arrow_point2]
				if _is_valid_polygon(polygon_points):
					draw_colored_polygon(polygon_points, Color.WHITE)

func get_nodes_data() -> Array:
	var nodes_data = []
	for node in nodes:
		nodes_data.append({
			"type": node.get_node_type(),
			"position": node.position,
			"name": node.get_node_name(),
			"description": node.get_node_description()
		})
	return nodes_data

func get_connections_data() -> Array:
	var connections_data = []
	for connection in connections:
		var from_index = nodes.find(connection.from_node)
		var to_index = nodes.find(connection.to_node)
		if from_index != -1 and to_index != -1:
			connections_data.append({
				"from": from_index,
				"to": to_index
			})
	return connections_data

func load_skill_tree_data(skill_tree_data: Dictionary):
	clear_all()
	
	var nodes_data = skill_tree_data.get("nodes", [])
	var connections_data = skill_tree_data.get("connections", [])
	
	# Load nodes
	for node_data in nodes_data:
		var node_scene = NODE_SCENES[node_data.type]
		var node = node_scene.instantiate()
		
		node.setup(node_data.type, node_data.position)
		node.position = node_data.position
		node.set_node_name(node_data.name)
		node.set_node_description(node_data.description)
		
		# Connect node signals
		node.node_selected.connect(_on_node_selected)
		node.node_dragged.connect(_on_node_dragged)
		
		add_child(node)
		nodes.append(node)
	
	# Load connections
	for connection_data in connections_data:
		var from_index = connection_data.from
		var to_index = connection_data.to
		
		if from_index < nodes.size() and to_index < nodes.size():
			var from_node = nodes[from_index]
			var to_node = nodes[to_index]
			_create_connection(from_node, to_node)

func clear_all():
	# Clear connections
	connections.clear()
	
	# Clear nodes
	for node in nodes:
		node.queue_free()
	nodes.clear()
	
	# Clear selection
	selected_node = null
	connecting_node = null
	
	# Clear node info
	skill_tree_creator.update_node_info("", "")
	
	queue_redraw()

func update_selected_node_name(name: String):
	if selected_node:
		selected_node.set_node_name(name)

func update_selected_node_description(description: String):
	if selected_node:
		selected_node.set_node_description(description)
