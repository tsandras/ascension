extends RefCounted
class_name SkillTreeConstants

# Node sizes for each node type
const NODE_SIZES = {
	"PASSIVE": Vector2(150, 150),
	"ACTIVE": Vector2(100, 100),
	"IMPROVEMENT": Vector2(100, 100),
	"MASTER_ATTRIBUTE": Vector2(150, 150),
	"ATTRIBUTE": Vector2(120, 120),
	"ABILITY": Vector2(75, 75),
	"EMPTY": Vector2(40, 40)
}

# Icon sizes for each node type (should be smaller than node size)
const ICON_SIZES = {
	"PASSIVE": Vector2(100, 100),      # 150x150 node, 120x120 icon
	"ACTIVE": Vector2(70, 70),         # 100x100 node, 80x80 icon
	"IMPROVEMENT": Vector2(80, 80),    # 100x100 node, 80x80 icon
	"MASTER_ATTRIBUTE": Vector2(75, 75), # 150x150 node, 120x120 icon
	"ATTRIBUTE": Vector2(65, 65),      # 100x100 node, 80x80 icon
	"ABILITY": Vector2(40, 40),        # 75x75 node, 40x40 icon
	"EMPTY": Vector2(30, 30)           # 40x40 node, 30x30 icon
}

# Frame mapping for different node types
const NODE_FRAMES = {
	"PASSIVE": "res://assets/ui/frame_passive_with_bg.svg",
	"ACTIVE": "res://assets/ui/ability_frame_with_bg.svg",
	"IMPROVEMENT": "res://assets/ui/skill_improvement_frame_with_bg.svg",
	"MASTER_ATTRIBUTE": "res://assets/ui/master_attribute_frame_with_bg.svg",
	"ATTRIBUTE": "res://assets/ui/attribute_frame_with_bg.svg",
	"ABILITY": "res://assets/ui/ability_frame_with_bg.svg",
	"EMPTY": "res://assets/ui/frame_passive_with_bg.svg"
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

# Node colors (if needed for any visual indicators)
const NODE_COLORS = {
	"PASSIVE": Color(0.5, 0.5, 0.5, 0.8),
	"ACTIVE": Color(0.7, 0.7, 0.7, 0.8),
	"IMPROVEMENT": Color(0.6, 0.6, 0.6, 0.8),
	"MASTER_ATTRIBUTE": Color(0.9, 0.9, 0.9, 0.8),
	"ATTRIBUTE": Color(0.8, 0.8, 0.8, 0.8),
	"ABILITY": Color(0.8, 0.8, 0.8, 0.8),
	"EMPTY": Color(0.4, 0.4, 0.4, 0.8)
}

# Frame offset for extending beyond node boundaries
const FRAME_OFFSET = 5.0

# Z-index values for proper layering
const Z_INDEX = {
	"FRAME": 1,
	"ICON": 2
}

const CONNECTION_COLOR = Color("#FAB85F")

const CONNECTION_DOTTED_COLOR = Color("#FAB85F")

const CONNECTION_DOTTED_WIDTH = 3.0

const CONNECTION_DOTTED_GAP = 6.0

const CONNECTION_DOTTED_LENGTH = 6.0

# Node type validation
static func is_valid_node_type(node_type: String) -> bool:
	return NODE_SIZES.has(node_type)

# Get node size with fallback
static func get_node_size(node_type: String) -> Vector2:
	return NODE_SIZES.get(node_type, NODE_SIZES["PASSIVE"])

# Get icon size with fallback
static func get_icon_size(node_type: String) -> Vector2:
	return ICON_SIZES.get(node_type, ICON_SIZES["PASSIVE"])

# Get frame path with fallback
static func get_frame_path(node_type: String) -> String:
	return NODE_FRAMES.get(node_type, NODE_FRAMES["PASSIVE"])

# Get default icon with fallback
static func get_default_icon(node_type: String) -> String:
	return DEFAULT_ICONS.get(node_type, DEFAULT_ICONS["PASSIVE"])

# Get icon path with fallback
static func get_icon_path(icon_name: String, node_type: String = "PASSIVE") -> String:
	if icon_name.is_empty():
		var default_icon = get_default_icon(node_type)
		return ICON_BASE_PATH + default_icon + ".svg"
	return ICON_BASE_PATH + icon_name + ".svg"
