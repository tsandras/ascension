extends RefCounted
class_name HexTileConstants

# ===================================================================
# HEX TILE CONSTANTS - SINGLE SOURCE OF TRUTH FOR HEX MAP SYSTEM
# ===================================================================
# 
# This file contains all constants related to the hex tile system.
# To change tile sizes or spacing, modify the values here.
#
# USAGE:
# - MapManager uses these for tile positioning calculations
# - HexMap uses these for texture resizing and display
# - Database seeding uses these for default values
#
# MAINTENANCE NOTES:
# - TILE_WIDTH and TILE_HEIGHT should match actual display size
# - Spacing multipliers control hexagonal layout gaps
# - Source texture size should match actual asset dimensions
# ===================================================================

# ===================
# TILE DIMENSIONS
# ===================
const TILE_WIDTH = 1024  # Use original texture size
const TILE_HEIGHT = 1024  # Use original texture size

# Source texture dimensions (assets are this size)
const SOURCE_TEXTURE_WIDTH = 1024
const SOURCE_TEXTURE_HEIGHT = 1024

# ===================
# HEXAGONAL SPACING
# ===================
const HORIZONTAL_SPACING_MULTIPLIER = 0.85  # 85% of tile width
const VERTICAL_SPACING_MULTIPLIER = 0.73    # 73% of tile height

# Calculated spacing values (used by MapManager)
const HORIZONTAL_SPACING = TILE_WIDTH * HORIZONTAL_SPACING_MULTIPLIER   # 870px
const VERTICAL_SPACING = TILE_HEIGHT * VERTICAL_SPACING_MULTIPLIER      # 748px

# ===================
# DEBUG & INTERACTION
# ===================
const DEBUG_SPACING_STEP = 5.0  # Pixels to adjust spacing per key press
const ZOOM_IN_FACTOR = 1.1
const ZOOM_OUT_FACTOR = 0.9
const MIN_ZOOM_SCALE = 0.3
const MAX_ZOOM_SCALE = 3.0

# ===================
# TILE HIGHLIGHTING
# ===================
const HOVER_BRIGHTNESS = 1.3    # Tile brightness on mouse hover
const SELECTION_BRIGHTNESS = 1.5 # Tile brightness when selected
const SELECTION_YELLOW_TINT = 1.0 # Yellow tint for selected tiles

# ===================
# UI LAYOUT
# ===================
const INFO_PANEL_WIDTH = 300    # Right panel width in HexMap scene
const MAP_CANVAS_PADDING = 100  # Extra padding around map canvas

# ===================
# DEFAULT VALUES
# ===================
const DEFAULT_FALLBACK_COLOR = "#2D5016"  # Forest green for missing textures
const DEFAULT_GAME_ID = 1        # Default game instance ID
const DEFAULT_TILE_SIZE_DB = 50  # Default tile_size value in database
const DEFAULT_MOVEMENT_COST = 1  # Default movement cost for walkable tiles
const IMPASSABLE_MOVEMENT_COST = 999  # Movement cost for non-walkable tiles

# ===================
# TEXTURE PATHS
# ===================
const TILE_TEXTURE_BASE_PATH = "res://assets/tiles/"
const TILE_TEXTURE_PREFIX = "tilev3_"
const TILE_TEXTURE_EXTENSION = ".png"

# Helper function to get full texture path for a tile type
static func get_texture_path(tile_type: String) -> String:
	return TILE_TEXTURE_BASE_PATH + TILE_TEXTURE_PREFIX + tile_type + TILE_TEXTURE_EXTENSION

# ===================
# HEXAGONAL GRID MATH
# ===================
# Neighbor offsets for even/odd rows in hexagonal grid
const HEX_NEIGHBORS_EVEN_ROW = [
	Vector2i(-1, -1), Vector2i(0, -1),   # Top-left, Top-right
	Vector2i(-1, 0), Vector2i(1, 0),     # Left, Right  
	Vector2i(-1, 1), Vector2i(0, 1)      # Bottom-left, Bottom-right
]

const HEX_NEIGHBORS_ODD_ROW = [
	Vector2i(0, -1), Vector2i(1, -1),    # Top-left, Top-right
	Vector2i(-1, 0), Vector2i(1, 0),     # Left, Right
	Vector2i(0, 1), Vector2i(1, 1)       # Bottom-left, Bottom-right
] 