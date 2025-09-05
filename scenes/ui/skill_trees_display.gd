extends Control
class_name SkillTreesDisplay

## SkillTreesDisplay - A reusable skill trees display component
##
## This scene displays multiple skill trees from the database with tabs
## and allows interaction with skill nodes. It can be used in character 
## creation, character sheets, or any other part of the game that needs 
## to show skill trees.
##
## Usage:
##   var skill_trees_display = preload("res://scenes/ui/skill_trees_display.tscn").instantiate()
##   parent_node.add_child(skill_trees_display)
##   skill_trees_display.load_all_skill_trees()
##   skill_trees_display.skill_trees_closed.connect(_on_skill_trees_closed)

# Node references
@onready var main_container: HBoxContainer = $MainContainer
@onready var left_sidebar: VBoxContainer = $MainContainer/LeftSidebar
@onready var title_label: Label = $MainContainer/LeftSidebar/HeaderContainer/TitleLabel
@onready var description_label: Label = $MainContainer/LeftSidebar/HeaderContainer/DescriptionLabel
@onready var tabs_vbox: VBoxContainer = $MainContainer/LeftSidebar/TabsContainer/TabsScrollContainer/TabsVBox
@onready var skill_tree_viewer: Control = $MainContainer/SkillTreeViewer
@onready var scroll_container: ScrollContainer = $MainContainer/SkillTreeViewer/ScrollContainer
@onready var skill_tree_container: Control = $MainContainer/SkillTreeViewer/ScrollContainer/SkillTreeContainer
@onready var no_skill_tree_label: Label = $MainContainer/SkillTreeViewer/NoSkillTreeLabel
@onready var close_button: Button = $CloseButton

# Skill trees data
var all_skill_trees: Array = []
var current_skill_tree_id: int = -1
var current_skill_tree_data: Dictionary = {}
var skill_nodes: Array[Control] = []
var connections: Array[Dictionary] = []
var tab_buttons: Array[Button] = []
var skill_trees_loaded: bool = false

# Signals
signal skill_trees_closed()
signal node_selected(node_data: Dictionary)
signal node_activated(node_data: Dictionary)

# Configuration
var is_interactive: bool = true
var show_connections: bool = true
var node_spacing: float = 100.0
var connection_color: Color = SkillTreeUtil.DEFAULT_CONNECTION_COLOR

func _ready():
	"""Initialize the skill trees display"""
	print("SkillTreesDisplay initialized")
	
	# Connect signals
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# Set up mouse input
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	
	# Initialize with empty state
	_clear_skill_tree()
	
	# Try to load skill trees immediately, but also set up a deferred call as fallback
	load_all_skill_trees()
	
	# Fallback: Try again after a short delay in case DatabaseManager wasn't ready
	call_deferred("_delayed_load_skill_trees")

func load_all_skill_trees():
	"""Load all skill trees from the database and create tabs"""
	print("Loading all skill trees...")
	
	# Check if already loaded and valid - but also verify data integrity
	if skill_trees_loaded and not all_skill_trees.is_empty():
		# Verify that the data is still valid (not empty dictionaries)
		var has_valid_data = false
		for skill_tree in all_skill_trees:
			if typeof(skill_tree) == TYPE_DICTIONARY and skill_tree.has("id") and skill_tree.has("name"):
				has_valid_data = true
				break
		
		if has_valid_data:
			print("DEBUG: Skill trees already loaded with valid data, skipping reload")
			return true
		else:
			print("DEBUG: Skill trees loaded but data corrupted, forcing reload")
			skill_trees_loaded = false
	
	if not DatabaseManager:
		print("Error: DatabaseManager not available")
		return false
	
	# Get all skill trees from database
	var raw_skill_trees = DatabaseManager.get_all_skill_trees()
	print("Found %d skill trees from database" % raw_skill_trees.size())
	
	# Debug: Print skill tree names
	for i in range(raw_skill_trees.size()):
		var skill_tree = raw_skill_trees[i]
		print("Skill tree %d: %s (ID: %d)" % [i, skill_tree.get("name", "Unknown"), skill_tree.get("id", -1)])
		print("  Type: ", typeof(skill_tree))
		if typeof(skill_tree) == TYPE_DICTIONARY:
			print("  Keys: ", skill_tree.keys())
		else:
			print("  Not a dictionary")
	
	# Filter out invalid skill trees (empty dictionaries) and create deep copies
	var valid_skill_trees = []
	for skill_tree in raw_skill_trees:
		if typeof(skill_tree) == TYPE_DICTIONARY and skill_tree.has("id") and skill_tree.has("name"):
			# Create a deep copy to prevent corruption
			var skill_tree_copy = {}
			for key in skill_tree.keys():
				skill_tree_copy[key] = skill_tree[key]
			valid_skill_trees.append(skill_tree_copy)
			print("DEBUG: Created copy of skill tree: ", skill_tree_copy.name, " (ID: ", skill_tree_copy.id, ")")
		else:
			print("DEBUG: Skipping invalid skill tree: ", skill_tree)
	
	# Only update all_skill_trees if we have valid data
	if not valid_skill_trees.is_empty():
		all_skill_trees = valid_skill_trees
		print("Valid skill trees after filtering: %d" % all_skill_trees.size())
		skill_trees_loaded = true
	else:
		print("WARNING: No valid skill trees found, keeping existing data")
		return false
	
	# Clear existing tabs
	_clear_tabs()
	
	# Create tabs for each skill tree
	for skill_tree in all_skill_trees:
		_create_tab(skill_tree)
	
	# Show "no skill tree" message if no skill trees available
	if all_skill_trees.is_empty():
		no_skill_tree_label.visible = true
		skill_tree_viewer.visible = false
	else:
		no_skill_tree_label.visible = false
		skill_tree_viewer.visible = true
		# Select first tab by default
		if tab_buttons.size() > 0:
			_on_tab_clicked(tab_buttons[0])
	
	return true

func _delayed_load_skill_trees():
	"""Delayed fallback to load skill trees if they weren't loaded initially"""
	print("Delayed load attempt...")
	if all_skill_trees.is_empty() and tab_buttons.is_empty():
		print("No skill trees loaded initially, trying again...")
		load_all_skill_trees()

func _create_tab(skill_tree_data: Dictionary):
	"""Create a tab button for a skill tree"""
	print("Creating tab for skill tree: %s" % skill_tree_data.get("name", "Unknown"))
	
	var tab_button = Button.new()
	tab_button.text = skill_tree_data.get("name", "Unknown")
	tab_button.custom_minimum_size = Vector2(180, 50)
	tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Store skill tree data in the button
	tab_button.set_meta("skill_tree_data", skill_tree_data)
	var skill_tree_id = skill_tree_data.get("id", -1) if typeof(skill_tree_data) == TYPE_DICTIONARY else -1
	tab_button.set_meta("skill_tree_id", skill_tree_id)
	
	# Connect signal
	tab_button.pressed.connect(_on_tab_clicked.bind(tab_button))
	
	# Add to tabs container
	tabs_vbox.add_child(tab_button)
	tab_buttons.append(tab_button)
	
	print("Created tab for skill tree: %s (ID: %d)" % [skill_tree_data.get("name", "Unknown"), skill_tree_id])
	print("Total tabs created: %d" % tab_buttons.size())

func _on_tab_clicked(tab_button: Button):
	"""Handle tab button click"""
	print("Tab clicked: %s" % tab_button.text)
	
	# Update tab appearance
	_update_tab_appearance(tab_button)
	
	# Load the selected skill tree
	var skill_tree_data = tab_button.get_meta("skill_tree_data")
	var skill_tree_id = tab_button.get_meta("skill_tree_id")
	
	print("Loading skill tree ID: %d" % skill_tree_id)
	_load_skill_tree_by_id(skill_tree_id)

func _update_tab_appearance(selected_tab: Button):
	"""Update the appearance of all tabs to show which one is selected"""
	for tab_button in tab_buttons:
		if tab_button == selected_tab:
			# Selected tab - highlight with background color
			tab_button.modulate = Color.WHITE
			tab_button.add_theme_color_override("font_color", Color("#FAB85F"))
			tab_button.add_theme_color_override("background_color", Color("#FAB85F", 0.2))
		else:
			# Unselected tab - subtle appearance
			tab_button.modulate = Color(0.8, 0.8, 0.8, 1.0)
			tab_button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			tab_button.add_theme_color_override("background_color", Color(0.2, 0.2, 0.2, 0.3))

func _load_skill_tree_by_id(skill_tree_id: int):
	"""Load a specific skill tree by ID"""
	print("Loading skill tree with ID: ", skill_tree_id)
	print("DEBUG: Current all_skill_trees size: ", all_skill_trees.size())
	
	# Check if all_skill_trees is empty or corrupted, reload if needed
	if all_skill_trees.is_empty():
		print("DEBUG: No skill trees loaded, reloading...")
		load_all_skill_trees()
	
	# Find the skill tree data
	var skill_tree_data = null
	for i in range(all_skill_trees.size()):
		var skill_tree = all_skill_trees[i]
		print("Checking skill tree %d: ", i, skill_tree, " type: ", typeof(skill_tree))
		if typeof(skill_tree) == TYPE_DICTIONARY:
			print("  Keys: ", skill_tree.keys())
			print("  Has 'id' key: ", skill_tree.has("id"))
			if skill_tree.has("id"):
				print("  ID value: ", skill_tree.id, " (looking for: ", skill_tree_id, ")")
		else:
			print("  Not a dictionary")
		
		if typeof(skill_tree) == TYPE_DICTIONARY and skill_tree.has("id") and skill_tree.id == skill_tree_id:
			skill_tree_data = skill_tree
			print("DEBUG: Found matching skill tree!")
			break
	
	if not skill_tree_data:
		print("Error: Skill tree not found with ID: ", skill_tree_id)
		print("Available skill trees: ", all_skill_trees.size())
		for i in range(all_skill_trees.size()):
			var tree = all_skill_trees[i]
			print("  Tree %d: ", i, tree)
		
		# Try to reload and search again
		print("DEBUG: Attempting to reload skill trees...")
		skill_trees_loaded = false  # Force reload
		load_all_skill_trees()
		
		# Search again after reload
		for i in range(all_skill_trees.size()):
			var skill_tree = all_skill_trees[i]
			if typeof(skill_tree) == TYPE_DICTIONARY and skill_tree.has("id") and skill_tree.id == skill_tree_id:
				skill_tree_data = skill_tree
				print("DEBUG: Found skill tree after reload!")
				break
		
		if not skill_tree_data:
			print("Error: Still could not find skill tree after reload")
			return false
	
	print("Found skill tree data: ", skill_tree_data, " type: ", typeof(skill_tree_data))
	
	# Store current skill tree info
	current_skill_tree_id = skill_tree_id
	current_skill_tree_data = skill_tree_data
	
	# Update header
	_update_header(skill_tree_data)
	
	# Load the skill tree - pass the data_dict like skill_tree_creator does
	return _load_skill_tree_data(skill_tree_data.data_dict)

func _load_skill_tree_data(data_dict: Dictionary):
	"""Load skill tree data and create the visual representation"""
	print("Loading skill tree data_dict: ", data_dict)
	
	# Clear existing skill tree
	_clear_skill_tree()
	
	# Reset scroll container scroll position first
	scroll_container.scroll_horizontal = 0
	scroll_container.scroll_vertical = 0
	
	# Ensure skill tree container is properly sized
	skill_tree_container.custom_minimum_size = Vector2(1200, 800)
	
	print("DEBUG: Set skill tree container position to: ", skill_tree_container.position)
	print("DEBUG: Set skill tree container size to: ", skill_tree_container.size)
	print("DEBUG: Reset scroll position to: ", Vector2(scroll_container.scroll_horizontal, scroll_container.scroll_vertical))
	print("DEBUG: Container size flags: ", skill_tree_container.size_flags_horizontal, "x", skill_tree_container.size_flags_vertical)
	
	# Parse skill tree data using the same approach as skill_tree_creator
	print("About to parse skill tree data from data_dict...")
	var nodes_data = []
	var connections_data = []
	
	# Access nodes and connections directly from the data_dict
	print("Accessing data_dict directly...")
	nodes_data = data_dict.get("nodes", [])
	connections_data = data_dict.get("connections", [])
	print("Extracted nodes: ", nodes_data)
	print("Extracted connections: ", connections_data)
	
	# Load nodes
	for node_data in nodes_data:
		var node_id = node_data.get("node_id", -1)
		var position_str = node_data.get("position", "(0, 0)")
		var position = _parse_position_string(position_str)
		
		print("Processing node ID: %d, position: %s -> %s" % [node_id, position_str, position])
		
		if node_id > 0:
			# Get full node data from database
			var full_node_data = DatabaseManager.get_node_by_id(node_id)
			print("Full node data for ID %d: %s" % [node_id, full_node_data])
			if full_node_data.size() > 0:
				_create_skill_node(full_node_data, position)
			else:
				print("Warning: No node data found for ID: %d" % node_id)
	
	# Load connections
	for connection_data in connections_data:
		var from_id = connection_data.get("from_node_id", -1)
		var to_id = connection_data.get("to_node_id", -1)
		
		if from_id > 0 and to_id > 0:
			_create_connection(from_id, to_id)
	
	# Update display - force redraw to ensure connections are drawn with offset
	queue_redraw()
	
	# Force an immediate redraw to show connections with proper offset
	call_deferred("queue_redraw")
	
	print("Skill tree loaded successfully with ", skill_nodes.size(), " nodes and ", connections.size(), " connections")
	return true

func _create_skill_node(node_data: Dictionary, position: Vector2):
	"""Create a visual skill node"""
	print("Creating skill node with data: %s, position: %s" % [node_data, position])
	print("DEBUG: Skill tree container position: ", skill_tree_container.position)
	print("DEBUG: Skill tree container size: ", skill_tree_container.size)
	print("DEBUG: Skill tree container global position: ", skill_tree_container.global_position)
	print("DEBUG: Scroll container position: ", scroll_container.position)
	print("DEBUG: Scroll container size: ", scroll_container.size)
	print("DEBUG: Scroll container global position: ", scroll_container.global_position)
	
	# The skill tree container is positioned at (204, 10) globally due to the sidebar
	# The nodes should be positioned at their original positions within the container
	# The container itself handles the offset, so we don't need to adjust node positions
	var adjusted_position = position
	print("DEBUG: Original position: ", position)
	print("DEBUG: Using original position (no adjustment needed): ", adjusted_position)
	
	var node_scene = SkillTreeUtil.create_skill_node(node_data, adjusted_position, skill_tree_container, is_interactive)
	
	if node_scene:
		print("Successfully created skill node")
		# Connect signals if interactive
		if is_interactive:
			node_scene.node_selected.connect(_on_node_selected)
		
		# Add to nodes array
		skill_nodes.append(node_scene)
		print("Added node to skill_nodes array. Total nodes: %d" % skill_nodes.size())
	else:
		print("Error: Failed to create skill node")

func _create_connection(from_id: int, to_id: int):
	"""Create a connection between two nodes"""
	var from_node = SkillTreeUtil.get_node_by_database_id(skill_nodes, from_id)
	var to_node = SkillTreeUtil.get_node_by_database_id(skill_nodes, to_id)
	
	if from_node and to_node:
		var connection = SkillTreeUtil.create_connection(from_node, to_node, from_id, to_id)
		connections.append(connection)

func _update_header(skill_tree_data: Dictionary):
	"""Update the header with skill tree information"""
	if title_label:
		title_label.text = "SKILL TREES"
	
	if description_label:
		description_label.text = "Viewing: " + skill_tree_data.get("name", "Unknown")

func _clear_skill_tree():
	"""Clear the current skill tree"""
	# Clear nodes using utility
	SkillTreeUtil.clear_skill_tree_nodes(skill_nodes)
	
	# Clear connections
	connections.clear()
	
	# Reset data
	current_skill_tree_id = -1
	current_skill_tree_data.clear()

func _clear_tabs():
	"""Clear all tab buttons and spacers"""
	# Clear all children from the tabs container
	for child in tabs_vbox.get_children():
		child.queue_free()
	
	# Clear the tab buttons array
	tab_buttons.clear()

func _on_gui_input(event: InputEvent):
	"""Handle GUI input for the skill tree display"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Check if clicking on empty space
			var clicked_node = SkillTreeUtil.get_node_at_position(skill_nodes, event.position)
			if not clicked_node and is_interactive:
				# Deselect all nodes
				SkillTreeUtil.deselect_all_nodes(skill_nodes)

func _on_node_selected(node: Control):
	"""Handle node selection"""
	print("Node selected: ", node.get_node_name())
	
	# Deselect other nodes
	SkillTreeUtil.deselect_all_nodes(skill_nodes)
	
	# Select this node
	if node.has_method("set_selected"):
		node.set_selected(true)
	
	# Emit signal
	var node_data = node.get_meta("node_data", {})
	node_selected.emit(node_data)

func _on_close_button_pressed():
	"""Handle close button press"""
	print("Skill trees display closed")
	skill_trees_closed.emit()
	queue_free()

func _draw():
	"""Draw the skill tree connections"""
	print("DEBUG: _draw() called with ", connections.size(), " connections")
	
	if not show_connections:
		return
	
	# Draw all connections using utility with offset to account for container position
	# The container is offset by the sidebar width, so we need to adjust the drawing coordinates
	var container_offset = skill_tree_container.global_position - global_position
	print("DEBUG: Container offset for drawing: ", container_offset)
	SkillTreeUtil.draw_all_connections_with_offset(self, connections, connection_color, SkillTreeUtil.DEFAULT_LINE_WIDTH, SkillTreeUtil.DEFAULT_PARALLEL_OFFSET, true, container_offset)

# Public API methods
func set_interactive(interactive: bool):
	"""Set whether the skill tree is interactive"""
	is_interactive = interactive

func set_show_connections(show: bool):
	"""Set whether to show connections between nodes"""
	show_connections = show
	queue_redraw()

func set_connection_color(color: Color):
	"""Set the color for connections"""
	connection_color = color
	queue_redraw()

func get_current_skill_tree_id() -> int:
	"""Get the current skill tree ID"""
	return current_skill_tree_id

func get_current_skill_tree_data() -> Dictionary:
	"""Get the current skill tree data"""
	return current_skill_tree_data

func get_selected_nodes() -> Array[Dictionary]:
	"""Get all currently selected nodes"""
	var selected_nodes = []
	for node in skill_nodes:
		if node.has_method("is_selected") and node.is_selected():
			selected_nodes.append(node.get_meta("node_data", {}))
	return selected_nodes

func clear_selection():
	"""Clear all node selections"""
	SkillTreeUtil.deselect_all_nodes(skill_nodes)

func _parse_position_string(position_str: String) -> Vector2:
	"""Parse position string like '(155.5424, 175.8353)' into Vector2"""
	if position_str.begins_with("(") and position_str.ends_with(")"):
		# Remove parentheses
		var coords_str = position_str.substr(1, position_str.length() - 2)
		# Split by comma
		var coords = coords_str.split(",")
		if coords.size() == 2:
			var x = coords[0].strip_edges().to_float()
			var y = coords[1].strip_edges().to_float()
			return Vector2(x, y)
	
	print("Warning: Could not parse position string: ", position_str)
	return Vector2.ZERO

func refresh_skill_trees():
	"""Refresh the skill trees list and tabs"""
	load_all_skill_trees()
