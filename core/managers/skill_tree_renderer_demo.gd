extends Control
class_name SkillTreeRendererDemo

# This is a demo script showing how to use the SkillTreeRenderer utility class
# in other parts of the game for displaying skill tree nodes with icons and frames

@onready var icon_display: TextureRect = $IconDisplay
@onready var frame_display: TextureRect = $FrameDisplay
@onready var node_type_selector: OptionButton = $NodeTypeSelector
@onready var icon_selector: OptionButton = $IconSelector

func _ready():
	_setup_ui()
	_populate_selectors()
	_connect_signals()

func _setup_ui():
	# This would be set up in your actual scene file
	pass

func _populate_selectors():
	# Populate node type selector
	node_type_selector.clear()
	var available_types = SkillTreeRenderer.get_available_node_types()
	for node_type in available_types:
		node_type_selector.add_item(node_type)
	
	# Populate icon selector
	icon_selector.clear()
	icon_selector.add_item("Default", -1)
	var available_icons = SkillTreeRenderer.get_available_icons()
	for icon_name in available_icons:
		icon_selector.add_item(icon_name, icon_name)

func _connect_signals():
	node_type_selector.item_selected.connect(_on_node_type_selected)
	icon_selector.item_selected.connect(_on_icon_selected)

func _on_node_type_selected(index: int):
	var selected_type = node_type_selector.get_item_text(index)
	_update_display(selected_type, "")

func _on_icon_selected(index: int):
	var selected_icon = icon_selector.get_item_metadata(index)
	var selected_type = node_type_selector.get_item_text(node_type_selector.selected)
	_update_display(selected_type, selected_icon)

func _update_display(node_type: String, icon_name: String):
	# Use the utility class to get textures
	var visual_data = SkillTreeRenderer.create_node_visual(node_type, icon_name)
	
	# Update the displays
	if visual_data.frame_texture:
		frame_display.texture = visual_data.frame_texture
		print("Updated frame: ", visual_data.frame_path)
	
	if visual_data.icon_texture:
		icon_display.texture = visual_data.icon_texture
		print("Updated icon: ", visual_data.icon_path)

# Example function for creating a node display in other parts of the game
static func create_node_display(node_type: String, icon_name: String = "") -> Control:
	"""Create a complete node display control that can be used anywhere in the game"""
	var node_size = SkillTreeRenderer.get_node_size(node_type)
	var icon_size = SkillTreeRenderer.get_icon_size(node_type)
	
	var container = Control.new()
	container.custom_minimum_size = node_size
	container.size = node_size
	
	# Create frame
	var frame = TextureRect.new()
	frame.expand_mode = TextureRect.EXPAND_FILL
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.texture = SkillTreeRenderer.load_frame_texture(node_type)
	container.add_child(frame)
	
	# Create icon
	var icon = TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_FILL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = SkillTreeRenderer.load_icon_texture(icon_name, node_type)
	icon.custom_minimum_size = icon_size
	icon.size = icon_size
	
	# Center the icon within the node
	var icon_position = (node_size - icon_size) / 2
	icon.position = icon_position
	container.add_child(icon)
	
	return container

# Example function for getting node information
static func get_node_info(node_type: String, icon_name: String = "") -> Dictionary:
	"""Get information about a node type and its available resources"""
	var info = {
		"node_type": node_type,
		"icon_name": icon_name,
		"has_frame": SkillTreeRenderer.is_frame_available(node_type),
		"has_icon": SkillTreeRenderer.is_icon_available(icon_name),
		"frame_path": SkillTreeRenderer.get_frame_path(node_type),
		"icon_path": SkillTreeRenderer.get_icon_path(icon_name, node_type)
	}
	return info
