extends RefCounted
class_name ThemeManager

# Generate a theme using UIConstants
static func create_default_theme() -> Theme:
	var theme = Theme.new()
	
	# Create button styles
	var button_normal = StyleBoxFlat.new()
	button_normal.bg_color = Color(0.2, 0.2, 0.3, 1)
	button_normal.border_width_left = 2
	button_normal.border_width_top = 2
	button_normal.border_width_right = 2
	button_normal.border_width_bottom = 2
	button_normal.border_color = Color(0.5, 0.5, 0.7, 1)
	button_normal.corner_radius_top_left = 5
	button_normal.corner_radius_top_right = 5
	button_normal.corner_radius_bottom_right = 5
	button_normal.corner_radius_bottom_left = 5
	
	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = Color(0.3, 0.3, 0.4, 1)
	button_hover.border_width_left = 2
	button_hover.border_width_top = 2
	button_hover.border_width_right = 2
	button_hover.border_width_bottom = 2
	button_hover.border_color = Color(0.6, 0.6, 0.8, 1)
	button_hover.corner_radius_top_left = 5
	button_hover.corner_radius_top_right = 5
	button_hover.corner_radius_bottom_right = 5
	button_hover.corner_radius_bottom_left = 5
	
	var button_pressed = StyleBoxFlat.new()
	button_pressed.bg_color = Color(0.15, 0.15, 0.25, 1)
	button_pressed.border_width_left = 2
	button_pressed.border_width_top = 2
	button_pressed.border_width_right = 2
	button_pressed.border_width_bottom = 2
	button_pressed.border_color = Color(0.4, 0.4, 0.6, 1)
	button_pressed.corner_radius_top_left = 5
	button_pressed.corner_radius_top_right = 5
	button_pressed.corner_radius_bottom_right = 5
	button_pressed.corner_radius_bottom_left = 5
	
	# Apply styles and font sizes using constants
	theme.set_stylebox("normal", "Button", button_normal)
	theme.set_stylebox("hover", "Button", button_hover)
	theme.set_stylebox("pressed", "Button", button_pressed)
	theme.set_font_size("font_size", "Button", UIConstants.FONT_SIZE_BUTTON)
	theme.set_font_size("font_size", "Label", UIConstants.FONT_SIZE_LABEL)
	
	return theme

# Apply theme to a scene
static func apply_theme_to_scene(scene: Control):
	var theme = create_default_theme()
	scene.theme = theme 