extends Control

enum NodeType { PASSIVE, ACTIVE, IMPROVEMENT, MASTER_ATTRIBUTE, ATTRIBUTE, EMPTY }
enum Mode { PLACE, CONNECT, EDIT }

var current_node_type: NodeType = NodeType.PASSIVE
var current_mode: Mode = Mode.PLACE

@onready var skill_tree_editor: Control = $VBoxContainer/SkillTreeEditor
@onready var skill_tree_name_edit: LineEdit = $VBoxContainer/TopPanel/SkillTreeNameContainer/SkillTreeNameEdit
@onready var node_name_edit: LineEdit = $VBoxContainer/NodeInfoPanel/VBoxContainer/NodeNameContainer/NodeNameEdit
@onready var node_desc_edit: TextEdit = $VBoxContainer/NodeInfoPanel/VBoxContainer/NodeDescContainer/NodeDescEdit

func _ready():
	# Connect node type buttons
	$VBoxContainer/ControlPanel/NodeTypeContainer/PassiveNodeBtn.pressed.connect(_on_passive_node_pressed)
	$VBoxContainer/ControlPanel/NodeTypeContainer/ActiveNodeBtn.pressed.connect(_on_active_node_pressed)
	$VBoxContainer/ControlPanel/NodeTypeContainer/ImprovementNodeBtn.pressed.connect(_on_improvement_node_pressed)
	$VBoxContainer/ControlPanel/NodeTypeContainer/MasterAttributeNodeBtn.pressed.connect(_on_master_attribute_node_pressed)
	$VBoxContainer/ControlPanel/NodeTypeContainer/AttributeNodeBtn.pressed.connect(_on_attribute_node_pressed)
	$VBoxContainer/ControlPanel/NodeTypeContainer/EmptyNodeBtn.pressed.connect(_on_empty_node_pressed)
	
	# Connect mode buttons
	$VBoxContainer/ControlPanel/ModeContainer/PlaceModeBtn.toggled.connect(_on_place_mode_toggled)
	$VBoxContainer/ControlPanel/ModeContainer/ConnectModeBtn.toggled.connect(_on_connect_mode_toggled)
	$VBoxContainer/ControlPanel/ModeContainer/EditModeBtn.toggled.connect(_on_edit_mode_toggled)
	
	# Connect file buttons
	$VBoxContainer/FilePanel/SaveBtn.pressed.connect(_on_save_pressed)
	$VBoxContainer/FilePanel/LoadBtn.pressed.connect(_on_load_pressed)
	$VBoxContainer/FilePanel/ClearBtn.pressed.connect(_on_clear_pressed)
	
	# Initialize skill tree editor
	skill_tree_editor.setup(self)
	
	# Connect node info updates after ensuring they exist
	call_deferred("_connect_node_info_signals")



func _on_passive_node_pressed():
	current_node_type = NodeType.PASSIVE
	_update_node_type_buttons()
	skill_tree_editor.set_node_type(current_node_type)

func _on_active_node_pressed():
	current_node_type = NodeType.ACTIVE
	_update_node_type_buttons()
	skill_tree_editor.set_node_type(current_node_type)

func _on_improvement_node_pressed():
	current_node_type = NodeType.IMPROVEMENT
	_update_node_type_buttons()
	skill_tree_editor.set_node_type(current_node_type)

func _on_master_attribute_node_pressed():
	current_node_type = NodeType.MASTER_ATTRIBUTE
	_update_node_type_buttons()
	skill_tree_editor.set_node_type(current_node_type)

func _on_attribute_node_pressed():
	current_node_type = NodeType.ATTRIBUTE
	_update_node_type_buttons()
	skill_tree_editor.set_node_type(current_node_type)

func _on_empty_node_pressed():
	current_node_type = NodeType.EMPTY
	_update_node_type_buttons()
	skill_tree_editor.set_node_type(current_node_type)

func _update_node_type_buttons():
	$VBoxContainer/ControlPanel/NodeTypeContainer/PassiveNodeBtn.button_pressed = (current_node_type == NodeType.PASSIVE)
	$VBoxContainer/ControlPanel/NodeTypeContainer/ActiveNodeBtn.button_pressed = (current_node_type == NodeType.ACTIVE)
	$VBoxContainer/ControlPanel/NodeTypeContainer/ImprovementNodeBtn.button_pressed = (current_node_type == NodeType.IMPROVEMENT)
	$VBoxContainer/ControlPanel/NodeTypeContainer/MasterAttributeNodeBtn.button_pressed = (current_node_type == NodeType.MASTER_ATTRIBUTE)
	$VBoxContainer/ControlPanel/NodeTypeContainer/AttributeNodeBtn.button_pressed = (current_node_type == NodeType.ATTRIBUTE)
	$VBoxContainer/ControlPanel/NodeTypeContainer/EmptyNodeBtn.button_pressed = (current_node_type == NodeType.EMPTY)

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
	var skill_tree_data = {
		"name": skill_tree_name_edit.text,
		"nodes": skill_tree_editor.get_nodes_data(),
		"connections": skill_tree_editor.get_connections_data()
	}
	
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.add_filter("*.json", "JSON Files")
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.current_dir = "res://"
	file_dialog.current_file = "skill_tree.json"
	
	add_child(file_dialog)
	file_dialog.file_selected.connect(_on_save_file_selected)
	file_dialog.popup_centered()

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
	if node_name_edit:
		skill_tree_editor.update_selected_node_name(node_name_edit.text)

func _on_node_desc_changed():
	if node_desc_edit:
		skill_tree_editor.update_selected_node_description(node_desc_edit.text)

func _connect_node_info_signals():
	if node_name_edit and node_desc_edit:
		node_name_edit.text_changed.connect(_on_node_name_changed)
		node_desc_edit.text_changed.connect(_on_node_desc_changed)

func update_node_info(name: String, description: String):
	if node_name_edit:
		node_name_edit.text = name
	if node_desc_edit:
		node_desc_edit.text = description
