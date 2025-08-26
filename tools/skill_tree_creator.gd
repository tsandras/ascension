extends Control

enum Mode { PLACE, CONNECT, EDIT }

var current_mode: Mode = Mode.PLACE

@onready var skill_tree_editor: Control = $VBoxContainer/SkillTreeEditor
@onready var skill_tree_selector: OptionButton = $VBoxContainer/TopPanel/SkillTreeNameContainer/SkillTreeSelector
@onready var load_skill_tree_btn: Button = $VBoxContainer/TopPanel/SkillTreeNameContainer/LoadSkillTreeBtn
@onready var skill_tree_name_edit: LineEdit = $VBoxContainer/TopPanel/SkillTreeNameContainer/SkillTreeNameEdit
@onready var node_name_value: Label = $VBoxContainer/NodeInfoPanel/VBoxContainer/NodeNameContainer/NodeNameValue
@onready var node_desc_edit: TextEdit = $VBoxContainer/NodeInfoPanel/VBoxContainer/NodeDescContainer/NodeDescEdit

# Node management panel references
@onready var database_node_select: OptionButton = $VBoxContainer/NodeManagementPanel/VBoxContainer/DatabaseNodeContainer/DatabaseNodeSelect
@onready var add_database_node_btn: Button = $VBoxContainer/NodeManagementPanel/VBoxContainer/DatabaseNodeContainer/AddDatabaseNodeBtn
@onready var refresh_database_btn: Button = $VBoxContainer/NodeManagementPanel/VBoxContainer/DatabaseNodeContainer/RefreshDatabaseBtn
@onready var new_node_name_value: Label = $VBoxContainer/NodeManagementPanel/VBoxContainer/NodeFormContainer/NewNodeNameContainer/NewNodeNameValue
@onready var new_node_desc_edit: TextEdit = $VBoxContainer/NodeManagementPanel/VBoxContainer/NodeFormContainer/NewNodeDescContainer/NewNodeDescEdit
@onready var new_node_trait_select: OptionButton = $VBoxContainer/NodeManagementPanel/VBoxContainer/NodeFormContainer/NewNodeTraitContainer/NewNodeTraitSelect
@onready var new_node_skill_select: OptionButton = $VBoxContainer/NodeManagementPanel/VBoxContainer/NodeFormContainer/NewNodeSkillContainer/NewNodeSkillSelect
@onready var save_skill_tree_btn: Button = $VBoxContainer/TopPanel/SkillTreeNameContainer/SaveNewNodeBtn

func _ready():
	# Connect mode buttons
	$VBoxContainer/ControlPanel/ModeContainer/PlaceModeBtn.toggled.connect(_on_place_mode_toggled)
	$VBoxContainer/ControlPanel/ModeContainer/ConnectModeBtn.toggled.connect(_on_connect_mode_toggled)
	$VBoxContainer/ControlPanel/ModeContainer/EditModeBtn.toggled.connect(_on_edit_mode_toggled)
	
	# Connect file buttons
	$VBoxContainer/FilePanel/SaveBtn.pressed.connect(_on_save_pressed)
	$VBoxContainer/FilePanel/LoadBtn.pressed.connect(_on_load_pressed)
	$VBoxContainer/FilePanel/ClearBtn.pressed.connect(_on_clear_pressed)
	
	# Initialize skill tree editor
	print("Setting up skill tree editor...")
	skill_tree_editor.setup(self)
	print("Skill tree editor setup complete")
	
	# Connect node info updates after ensuring they exist
	call_deferred("_connect_node_info_signals")
	
	# Connect node management buttons
	add_database_node_btn.pressed.connect(_on_add_database_node_pressed)
	save_skill_tree_btn.pressed.connect(_on_save_pressed)  # Save skill tree
	refresh_database_btn.pressed.connect(_on_refresh_database_pressed)
	
	# Connect skill tree selector
	skill_tree_selector.item_selected.connect(_on_skill_tree_selected)
	
	# Connect load button
	if load_skill_tree_btn:
		print("Load button found, connecting signal...")
		load_skill_tree_btn.pressed.connect(_on_load_skill_tree_pressed)
	else:
		print("Warning: Load button not found!")
	
	# Initialize node management panel
	print("Initializing node management...")
	call_deferred("_initialize_node_management")
	print("Node management initialization queued")
	
	# Debug: Check if all UI elements are found
	print("UI Elements check:")
	print("  - skill_tree_selector: ", skill_tree_selector != null)
	print("  - load_skill_tree_btn: ", load_skill_tree_btn != null)
	print("  - skill_tree_name_edit: ", skill_tree_name_edit != null)

func _on_place_mode_toggled(button_pressed: bool):
	if button_pressed:
		current_mode = Mode.PLACE
		_update_mode_buttons()
		skill_tree_editor.set_mode(current_mode)

func _on_connect_mode_toggled(button_pressed: bool):
	if button_pressed:
		current_mode = Mode.CONNECT
		_update_mode_buttons()
		skill_tree_editor.set_mode(current_mode)

func _on_edit_mode_toggled(button_pressed: bool):
	if button_pressed:
		current_mode = Mode.EDIT
		_update_mode_buttons()
		skill_tree_editor.set_mode(current_mode)

func _update_mode_buttons():
	$VBoxContainer/ControlPanel/ModeContainer/PlaceModeBtn.button_pressed = (current_mode == Mode.PLACE)
	$VBoxContainer/ControlPanel/ModeContainer/ConnectModeBtn.button_pressed = (current_mode == Mode.CONNECT)
	$VBoxContainer/ControlPanel/ModeContainer/EditModeBtn.button_pressed = (current_mode == Mode.EDIT)

func _on_save_pressed():
	var skill_tree_name = skill_tree_name_edit.text.strip_edges()
	if skill_tree_name.is_empty():
		print("Please enter a skill tree name")
		return
	
	print("Saving skill tree: ", skill_tree_name)
	
	# Get nodes and connections data - only store essential skill tree info
	var nodes_data = skill_tree_editor.get_nodes_data()
	var connections_data = skill_tree_editor.get_connections_data()
	
	print("Raw nodes data: ", nodes_data)
	print("Raw connections data: ", connections_data)
	
	# Filter nodes data to only include position and node_id (from database)
	var filtered_nodes = []
	for node_data in nodes_data:
		var database_id = node_data.get("database_id", -1)
		if database_id > 0:  # Only include nodes with valid database IDs
			var filtered_node = {
				"node_id": database_id,
				"position": node_data.get("position", Vector2.ZERO)
			}
			filtered_nodes.append(filtered_node)
		else:
			print("Warning: Node without database ID found: ", node_data)
	
	if filtered_nodes.is_empty():
		print("Error: No valid nodes with database IDs found")
		return
	
	# Filter connections data to use database node IDs
	var filtered_connections = []
	for connection in connections_data:
		var from_id = connection.get("from_node_id", -1)
		var to_id = connection.get("to_node_id", -1)
		if from_id > 0 and to_id > 0:  # Only include connections with valid IDs
			var filtered_connection = {
				"from_node_id": from_id,
				"to_node_id": to_id
			}
			filtered_connections.append(filtered_connection)
		else:
			print("Warning: Connection with invalid IDs found: ", connection)
	
	var skill_tree_data = {
		"nodes": filtered_nodes,
		"connections": filtered_connections
	}
	
	print("Filtered skill tree data: ", skill_tree_data)
	print("Saving skill tree with:")
	print("  - Name: ", skill_tree_name)
	print("  - Nodes count: ", filtered_nodes.size())
	print("  - Connections count: ", filtered_connections.size())
	
	# Save to database
	if DatabaseManager:
		print("DatabaseManager is available, saving...")
		var tree_id = DatabaseManager.save_skill_tree(
			skill_tree_name,
			"Skill tree created with the tool",  # Default description
			skill_tree_data,  # Only contains nodes and connections, no name
			""  # No parents for now
		)
		
		if tree_id > 0:
			print("Skill tree saved to database with ID: ", tree_id)
		else:
			print("Failed to save skill tree to database")
	else:
		print("DatabaseManager not available")

func _on_save_file_selected(path: String):
	var skill_tree_data = {
		"name": skill_tree_name_edit.text if skill_tree_name_edit else "",
		"nodes": skill_tree_editor.get_nodes_data(),
		"connections": skill_tree_editor.get_connections_data()
	}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(skill_tree_data, "\t"))
		file.close()
		print("Skill tree saved to: ", path)

func _on_load_pressed():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.json", "JSON Files")
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.current_dir = "res://"
	
	add_child(file_dialog)
	file_dialog.file_selected.connect(_on_load_file_selected)
	file_dialog.popup_centered()

func _on_load_file_selected(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(content)
		
		if parse_result == OK:
			var skill_tree_data = json.data
			_load_skill_tree_data(skill_tree_data)
		else:
			print("Error parsing JSON file")

func _load_skill_tree_data(skill_tree_data: Dictionary):
	# Load skill tree name
	if skill_tree_name_edit:
		skill_tree_name_edit.text = skill_tree_data.get("name", "")
	
	# Load nodes and connections
	skill_tree_editor.load_skill_tree_data(skill_tree_data)

func _on_clear_pressed():
	skill_tree_editor.clear_all()
	if skill_tree_name_edit:
		skill_tree_name_edit.text = ""

func _on_node_name_changed():
	# Note: Node names are now read-only from the database
	# This function is kept for compatibility but no longer needed
	pass

func _on_node_desc_changed():
	if node_desc_edit:
		skill_tree_editor.update_selected_node_description(node_desc_edit.text)

func _connect_node_info_signals():
	# Only connect description changes since names are now read-only
	if node_desc_edit:
		node_desc_edit.text_changed.connect(_on_node_desc_changed)

func update_node_info(name: String, description: String):
	if node_name_value:
		node_name_value.text = name
	if node_desc_edit:
		node_desc_edit.text = description

# Node Management Methods
func _initialize_node_management():
	_populate_database_nodes()
	_populate_traits()
	_populate_skills()
	_populate_skill_trees()

func _populate_database_nodes():
	database_node_select.clear()
	database_node_select.add_item("Select a node...", -1)
	
	# Get all nodes from database
	var nodes = []
	if DatabaseManager:
		nodes = DatabaseManager.get_all_nodes()
	else:
		print("Warning: DatabaseManager not available")
		return
	
	for node in nodes:
		var display_text = node.name
		if node.trait_name:
			display_text += " (Trait: " + node.trait_name + ")"
		if node.skill_name:
			display_text += " (Skill: " + node.skill_name + ")"
		
		database_node_select.add_item(display_text, node.id)
	
	print("Populated database nodes: ", nodes.size())

func _populate_traits():
	new_node_trait_select.clear()
	new_node_trait_select.add_item("None", -1)
	
	# Get all traits from database
	var traits = []
	if DatabaseManager:
		traits = DatabaseManager.get_all_traits()
	else:
		print("Warning: DatabaseManager not available")
		return
	
	for vtrait in traits:
		new_node_trait_select.add_item(vtrait.name, vtrait.id)
	print("Populated traits: ", traits.size())

func _populate_skills():
	new_node_skill_select.clear()
	new_node_skill_select.add_item("None", -1)
	
	# Get all abilities from database
	var abilities = []
	if DatabaseManager:
		abilities = DatabaseManager.get_all_abilities()
	else:
		print("Warning: DatabaseManager not available")
		return
	
	for ability in abilities:
		new_node_skill_select.add_item(ability.name, ability.id)
	
	print("Populated skills: ", abilities.size())

func _populate_skill_trees():
	"""Populate the skill tree selector with existing skill trees from database"""
	skill_tree_selector.clear()
	skill_tree_selector.add_item("Select a skill tree to load...", -1)
	
	# Get all skill trees from database
	var skill_trees = []
	if DatabaseManager:
		skill_trees = DatabaseManager.get_all_skill_trees()
	else:
		print("Warning: DatabaseManager not available")
		return
	
	for skill_tree in skill_trees:
		var display_text = skill_tree.name
		if skill_tree.description:
			display_text += " - " + skill_tree.description
		
		skill_tree_selector.add_item(display_text, skill_tree.id)
	
	print("Populated skill trees: ", skill_trees.size())

func _on_add_database_node_pressed():
	var selected_node_id = database_node_select.get_selected_id()
	if selected_node_id == -1:
		print("Please select a node from the database")
		return
	
	if not DatabaseManager:
		print("Error: DatabaseManager not available")
		return
	
	# Get the selected node data
	var node_data = DatabaseManager.get_node_by_id(selected_node_id)
	if node_data.size() == 0:
		print("Failed to get node data")
		return
	
	# Add the node to the skill tree editor
	skill_tree_editor.add_database_node(node_data)
	
	# Update the form to show the selected node's info
	new_node_name_value.text = node_data.name
	new_node_desc_edit.text = node_data.description if node_data.description else ""
	
	# Clear the selection
	database_node_select.select(0)
	
	print("Added database node: ", node_data.name)

func _on_save_new_node_pressed():
	var description = new_node_desc_edit.text.strip_edges()
	
	# Note: Node name is now determined by the database selection
	# We'll use the selected database node's name
	
	if not DatabaseManager:
		print("Error: DatabaseManager not available")
		return
	
	# Get selected trait and skill IDs
	var trait_id = new_node_trait_select.get_selected_id()
	var skill_id = new_node_skill_select.get_selected_id()
	
	# Convert -1 to actual NULL for database
	if trait_id == -1:
		trait_id = -1  # Keep as -1, will be converted to NULL in database
	if skill_id == -1:
		skill_id = -1  # Keep as -1, will be converted to NULL in database
	
	# Save the node to database (default to PASSIVE type)
	# Note: We need to get the name from the selected database node
	var selected_node_id = database_node_select.get_selected_id()
	if selected_node_id == -1:
		print("Please select a node from the database first")
		return
	
	var selected_node = DatabaseManager.get_node_by_id(selected_node_id)
	if selected_node.size() == 0:
		print("Error: Could not retrieve selected node data")
		return
	
	var node_id = DatabaseManager.save_node(selected_node.name, description, "PASSIVE", trait_id, skill_id)
	
	if node_id > 0:
		print("Node saved successfully with ID: ", node_id)
		
		# Clear the form
		new_node_name_value.text = "Auto-generated from database"
		new_node_desc_edit.text = ""
		new_node_trait_select.select(0)
		new_node_skill_select.select(0)
		
		# Refresh the database nodes list
		_populate_database_nodes()
		
		# Add the new node to the skill tree editor
		var node_data = DatabaseManager.get_node_by_id(node_id)
		skill_tree_editor.add_database_node(node_data)
	else:
		print("Failed to save node")

func refresh_node_management():
	_populate_database_nodes()
	_populate_traits()
	_populate_skills()
	_populate_skill_trees()

func _on_refresh_database_pressed():
	print("Refreshing node management data...")
	refresh_node_management()

func _on_skill_tree_selected(index: int):
	"""Handle skill tree selection from the dropdown"""
	print("Skill tree selection changed - index: ", index)
	
	var selected_id = skill_tree_selector.get_selected_id()
	print("Selected skill tree ID: ", selected_id)
	
	if selected_id == -1:
		print("No skill tree selected")
		return
	
	print("Loading skill tree with ID: ", selected_id)
	
	# Get the skill tree data from database
	var skill_tree_data = DatabaseManager.get_skill_tree_by_id(selected_id)
	if skill_tree_data.size() == 0:
		print("Error: Could not retrieve skill tree data")
		return
	
	# Update the skill tree name input
	skill_tree_name_edit.text = skill_tree_data.name
	
	# Load the skill tree data into the editor
	_load_skill_tree_data(skill_tree_data.data_dict)
	
	print("Skill tree loaded successfully: ", skill_tree_data.name)

func _on_load_skill_tree_pressed():
	"""Handle load button press - same as selection but more explicit"""
	print("Load Selected button pressed!")
	
	var selected_id = skill_tree_selector.get_selected_id()
	print("Selected skill tree ID: ", selected_id)
	
	if selected_id == -1:
		print("Please select a skill tree to load first")
		return
	
	print("Triggering skill tree loading...")
	# Trigger the same logic as selection
	_on_skill_tree_selected(0)  # Pass 0 as index since we're not using it
