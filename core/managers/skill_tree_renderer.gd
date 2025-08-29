extends RefCounted
class_name SkillTreeRenderer

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

# Default icons for each node type
const DEFAULT_ICONS = {
	"PASSIVE": "stealth",
	"ACTIVE": "sword",
	"IMPROVEMENT": "magic_book",
	"MASTER_ATTRIBUTE": "lion",
	"ATTRIBUTE": "strenght",
	"ABILITY": "anchor",
	"EMPTY": "stealth"
}

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

static func get_frame_path(node_type: String) -> String:
	"""Get the frame path for a given node type"""
	return NODE_FRAMES.get(node_type, NODE_FRAMES["PASSIVE"])

static func get_icon_path(icon_name: String, node_type: String = "PASSIVE") -> String:
	"""Get the icon path for a given icon name, with fallback to default"""
	if icon_name.is_empty():
		var default_icon = DEFAULT_ICONS.get(node_type, "stealth")
		return ICON_BASE_PATH + default_icon + ".svg"
	return ICON_BASE_PATH + icon_name + ".svg"

static func load_frame_texture(node_type: String) -> Texture2D:
	"""Load and return the frame texture for a given node type"""
	var frame_path = get_frame_path(node_type)
	if ResourceLoader.exists(frame_path):
		return load(frame_path)
	else:
		print("Frame not found: ", frame_path)
		return null

static func load_icon_texture(icon_name: String, node_type: String = "PASSIVE") -> Texture2D:
	"""Load and return the icon texture, with fallback to default"""
	var icon_path = get_icon_path(icon_name, node_type)
	if ResourceLoader.exists(icon_path):
		return load(icon_path)
	else:
		print("Icon not found: ", icon_path)
		# Try default icon as fallback
		var default_path = get_icon_path("", node_type)
		if ResourceLoader.exists(default_path):
			return load(default_path)
		return null

static func create_node_visual(node_type: String, icon_name: String = "") -> Dictionary:
	"""Create a complete visual representation of a node"""
	var result = {
		"frame_texture": load_frame_texture(node_type),
		"icon_texture": load_icon_texture(icon_name, node_type),
		"frame_path": get_frame_path(node_type),
		"icon_path": get_icon_path(icon_name, node_type)
	}
	return result

static func is_frame_available(node_type: String) -> bool:
	"""Check if a frame is available for the given node type"""
	return ResourceLoader.exists(get_frame_path(node_type))

static func is_icon_available(icon_name: String) -> bool:
	"""Check if an icon is available"""
	if icon_name.is_empty():
		return false
	return ResourceLoader.exists(get_icon_path(icon_name))

static func get_available_node_types() -> Array[String]:
	"""Get all available node types that have frames"""
	var available_types: Array[String] = []
	for node_type in NODE_FRAMES.keys():
		if is_frame_available(node_type):
			available_types.append(node_type)
	return available_types

static func get_available_icons() -> Array[String]:
	"""Get all available icons from the svgs directory"""
	var icons: Array[String] = []
	var dir = DirAccess.open(ICON_BASE_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".svg") and not file_name.begins_with("."):
				icons.append(file_name.get_basename())
			file_name = dir.get_next()
		dir.list_dir_end()
	return icons

static func get_icon_size(node_type: String) -> Vector2:
	"""Get the icon size for a given node type"""
	return ICON_SIZES.get(node_type, ICON_SIZES["PASSIVE"])

static func get_node_size(node_type: String) -> Vector2:
	"""Get the node size for a given node type"""
	# This would need to be imported from skill_node.gd or defined here
	# For now, return a reasonable default
	match node_type:
		"PASSIVE":
			return Vector2(150, 150)
		"ACTIVE":
			return Vector2(100, 100)
		"IMPROVEMENT":
			return Vector2(100, 100)
		"MASTER_ATTRIBUTE":
			return Vector2(150, 150)
		"ATTRIBUTE":
			return Vector2(100, 100)
		"ABILITY":
			return Vector2(75, 75)
		"EMPTY":
			return Vector2(40, 40)
		_:
			return Vector2(100, 100)
