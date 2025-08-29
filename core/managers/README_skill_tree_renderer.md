# SkillTreeRenderer Utility Class

The `SkillTreeRenderer` is a generic utility class that provides a unified way to display skill tree nodes with icons and frames throughout the game. It handles loading SVG icons and frames based on node types, with automatic fallbacks.

## Features

- **Automatic Frame Loading**: Loads appropriate frames based on node type
- **Icon Management**: Handles icon loading with fallback to default icons
- **Generic Design**: Can be used in any part of the game that needs to display skill tree nodes
- **Error Handling**: Graceful fallbacks when resources are missing
- **Performance**: Efficient resource loading and caching

## Node Types Supported

- `PASSIVE` - Passive abilities (150x150 px node, 120x120 px icon)
- `ACTIVE` - Active abilities (100x100 px node, 80x80 px icon)
- `IMPROVEMENT` - Skill improvements (100x100 px node, 80x80 px icon)
- `MASTER_ATTRIBUTE` - Major attribute bonuses (150x150 px node, 120x120 px icon)
- `ATTRIBUTE` - Standard attribute bonuses (100x100 px node, 80x80 px icon)
- `ABILITY` - General abilities (75x75 px node, 60x60 px icon)
- `EMPTY` - Placeholder nodes (40x40 px node, 30x30 px icon)

## Frame Mapping

Each node type automatically maps to a specific frame:

```gdscript
const NODE_FRAMES = {
	"PASSIVE": "res://assets/ui/frame_passive.svg",
	"ACTIVE": "res://assets/ui/ability_frame.svg",
	"IMPROVEMENT": "res://assets/ui/skill_improvement_frame.svg",
	"MASTER_ATTRIBUTE": "res://assets/ui/attribute_frame.svg",
	"ATTRIBUTE": "res://assets/ui/attribute_frame.svg",
	"ABILITY": "res://assets/ui/ability_frame.svg",
	"EMPTY": "res://assets/ui/frame_passive.svg"
}
```

## Icon System

Icons are loaded from `res://assets/icons/svgs/` and can be:
- **Custom icons**: Specified by `icon_name` field from database
- **Default icons**: Automatically assigned based on node type
- **Fallback icons**: Used when specified icons are missing

## Sizing System

Each node type has specific dimensions for optimal visual hierarchy:

### Node Sizes
- **PASSIVE**: 150x150 pixels (largest - important passive abilities)
- **MASTER_ATTRIBUTE**: 150x150 pixels (largest - major bonuses)
- **ACTIVE**: 100x100 pixels (medium - active abilities)
- **IMPROVEMENT**: 100x100 pixels (medium - skill enhancements)
- **ATTRIBUTE**: 100x100 pixels (medium - attribute bonuses)
- **ABILITY**: 75x75 pixels (small - general abilities)
- **EMPTY**: 40x40 pixels (smallest - placeholders)

### Icon Sizes
Icons are proportionally sized within their nodes:
- **150x150 nodes**: 120x120 pixel icons (80% of node size)
- **100x100 nodes**: 80x80 pixel icons (80% of node size)
- **75x75 nodes**: 60x60 pixel icons (80% of node size)
- **40x40 nodes**: 30x30 pixel icons (75% of node size)

### Automatic Sizing
The system automatically:
- Adjusts node dimensions based on type
- Centers icons within their frames
- Maintains proper proportions
- Updates sizes when node types change

## Usage Examples

### Basic Usage

```gdscript
# Load a frame texture
var frame_texture = SkillTreeRenderer.load_frame_texture("PASSIVE")

# Load an icon texture
var icon_texture = SkillTreeRenderer.load_icon_texture("stealth", "PASSIVE")

# Create complete visual data
var visual_data = SkillTreeRenderer.create_node_visual("ACTIVE", "sword")
```

### In UI Components

```gdscript
# Set frame texture
@onready var frame: TextureRect = $Frame
frame.texture = SkillTreeRenderer.load_frame_texture(node_type)

# Set icon texture
@onready var icon: TextureRect = $Icon
icon.texture = SkillTreeRenderer.load_icon_texture(icon_name, node_type)
```

### Creating Dynamic Node Displays

```gdscript
# Create a complete node display anywhere in the game
var node_display = SkillTreeRendererDemo.create_node_display("PASSIVE", "stealth")
add_child(node_display)
```

### Getting Node Information

```gdscript
# Check what resources are available
var info = SkillTreeRenderer.get_node_info("ACTIVE", "sword")
print("Has frame: ", info.has_frame)
print("Has icon: ", info.has_icon)
print("Frame path: ", info.frame_path)
print("Icon path: ", info.icon_path)
```

## Database Integration

The system automatically works with the database `icon_name` field:

```gdscript
# When loading from database
if node_data.has("icon_name") and node_data.icon_name:
    node.set_icon_name(node_data.icon_name)
```

## File Structure

```
assets/
├── icons/
│   └── svgs/           # SVG icons (1024x1024 with white backgrounds)
└── ui/
    ├── frame_passive.svg
    ├── ability_frame.svg
    ├── skill_improvement_frame.svg
    ├── attribute_frame.svg
    └── frame_trait.svg
```

## Adding New Node Types

1. **Add frame file** to `assets/ui/`
2. **Update frame mapping** in `SkillTreeRenderer.NODE_FRAMES`
3. **Add default icon** in `SkillTreeRenderer.DEFAULT_ICONS`
4. **Update node sizes** in `skill_node.gd.NODE_SIZES`

## Adding New Icons

1. **Convert PNG to SVG** using `tools/svg_convertor.py`
2. **Place SVG file** in `assets/icons/svgs/`
3. **Update database** with `icon_name` field
4. **Icons automatically load** when referenced

## Performance Considerations

- **Lazy Loading**: Icons and frames are only loaded when needed
- **Resource Caching**: Godot automatically caches loaded textures
- **Memory Management**: Unused textures are automatically freed
- **Efficient Paths**: Uses static constants for path construction

## Error Handling

The system provides graceful fallbacks:

- **Missing frames**: Falls back to default frame
- **Missing icons**: Falls back to default icon for node type
- **Invalid node types**: Uses PASSIVE as default
- **Resource loading errors**: Logs warnings and continues

## Integration with Existing Code

The system is designed to work alongside existing code:

- **Backward Compatible**: Existing nodes continue to work
- **Progressive Enhancement**: New features can be added gradually
- **Non-breaking**: Can be integrated without changing existing functionality

## Future Enhancements

Potential improvements:

- **Animation Support**: Animated frames and icons
- **Theme System**: Different visual themes for different game areas
- **Dynamic Sizing**: Automatic sizing based on content
- **LOD System**: Different quality levels for different zoom levels
- **Batch Loading**: Preload common resources for better performance
