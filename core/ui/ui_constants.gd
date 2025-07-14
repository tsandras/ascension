extends RefCounted
class_name UIConstants

# ===================================================================
# UI CONSTANTS - SINGLE SOURCE OF TRUTH FOR ALL UI SIZING
# ===================================================================
# 
# This file contains all UI sizing constants for the Ascension game.
# To change the entire UI scale, modify the values here.
#
# USAGE:
# - UIManager.setup_*() functions apply these constants to scenes
# - Dynamic UI generation uses these constants automatically
# - ThemeManager uses font size constants
#
# TO SCALE THE ENTIRE UI:
# 1. Multiply all button/container sizes by your scale factor
# 2. Adjust font sizes proportionally  
# 3. Update spacing values to maintain visual balance
#
# MAINTENANCE NOTES:
# - Keep VIEWPORT_* values in sync with project.godot [display] settings
# - Font sizes in default_theme.tres should match FONT_SIZE_* constants
# - All hardcoded sizes in .tscn files are overridden by UIManager
# ===================================================================

# ===================
# SCREEN & WINDOW
# ===================
# NOTE: These values should match project.godot [display] settings
const VIEWPORT_WIDTH = 1280
const VIEWPORT_HEIGHT = 720

# ===================
# FONT SIZES
# ===================
const FONT_SIZE_BUTTON = 18
const FONT_SIZE_LABEL = 16
const FONT_SIZE_TITLE = 24
const FONT_SIZE_POINTS = 18

# ===================
# BUTTON SIZES
# ===================
const BUTTON_MAIN_MENU = Vector2(300, 80)
const BUTTON_BACK_CONTINUE = Vector2(150, 60)
const BUTTON_PLUS_MINUS = Vector2(50, 50)

# ===================
# LABEL SIZES
# ===================
const LABEL_ATTRIBUTE_WIDTH = 200
const LABEL_VALUE_WIDTH = 80

# ===================
# CONTAINER SIZES
# ===================
const CONTAINER_MAIN_MENU = Vector2(500, 600)
const CONTAINER_ATTRIBUTES_ALLOCATION = Vector2(800, 900)
const CONTAINER_ABILITIES_ALLOCATION = Vector2(800, 900)

# ===================
# SPACING
# ===================
const SPACING_LARGE = 60      # Between major sections
const SPACING_MEDIUM = 40     # Between button groups
const SPACING_SMALL = 30      # Between related elements
const SPACING_TINY = 20       # Between buttons in same group

# ===================
# MARGINS & PADDING
# ===================
const MARGIN_CONTAINER = 40
const PADDING_BUTTON_GROUP = 20

# ===================
# SPECIFIC LAYOUT SPACINGS
# ===================
class MainMenu:
	const TITLE_SPACER = 150
	const BUTTON_SPACER = SPACING_MEDIUM

class CharacterCreation:
	const TITLE_SPACER = SPACING_LARGE
	const POINTS_SPACER = SPACING_SMALL
	const ATTRIBUTES_SPACER = SPACING_LARGE
	const BUTTONS_SPACER = SPACING_MEDIUM

class AbilitiesAllocation:
	const TITLE_SPACER = SPACING_LARGE
	const POINTS_SPACER = SPACING_SMALL
	const ABILITIES_SPACER = SPACING_LARGE
	const BUTTONS_SPACER = SPACING_MEDIUM

# ===================
# COLORS
# ===================
class Colors:
	const BACKGROUND = Color(0.1, 0.1, 0.15, 1)
	const POINTS_REMAINING = Color.YELLOW
	const POINTS_COMPLETE = Color.GREEN
	const POINTS_ERROR = Color.RED
	const BUTTON_NORMAL = Color.WHITE
	const BUTTON_DISABLED = Color.GRAY

# ===================
# UTILITY FUNCTIONS
# ===================
static func get_button_size(button_type: String) -> Vector2:
	match button_type:
		"main_menu":
			return BUTTON_MAIN_MENU
		"back_continue":
			return BUTTON_BACK_CONTINUE
		"plus_minus":
			return BUTTON_PLUS_MINUS
		_:
			return Vector2(100, 40)  # Default

static func get_container_size(screen_type: String) -> Vector2:
	match screen_type:
		"main_menu":
			return CONTAINER_MAIN_MENU
		"attributes_allocation":
			return CONTAINER_ATTRIBUTES_ALLOCATION
		"abilities_allocation":
			return CONTAINER_ABILITIES_ALLOCATION
		_:
			return Vector2(500, 600)  # Default

static func get_font_size(element_type: String) -> int:
	match element_type:
		"button":
			return FONT_SIZE_BUTTON
		"label":
			return FONT_SIZE_LABEL
		"title":
			return FONT_SIZE_TITLE
		"points":
			return FONT_SIZE_POINTS
		_:
			return FONT_SIZE_LABEL  # Default 