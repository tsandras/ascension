extends RefCounted
class_name CursorUtils

static func add_cursor_to_button(button: Button):
	"""Add cursor functionality to a button"""
	if not button:
		return
	
	# Connect mouse enter/exit signals using lambda functions
	button.mouse_entered.connect(func(): _handle_mouse_entered())
	button.mouse_exited.connect(func(): _handle_mouse_exited())

static func add_cursor_to_control(control: Control):
	"""Add cursor functionality to a control"""
	if not control:
		return
	
	# Connect mouse enter/exit signals using lambda functions
	control.mouse_entered.connect(func(): _handle_mouse_entered())
	control.mouse_exited.connect(func(): _handle_mouse_exited())

static func _handle_mouse_entered():
	"""Handle mouse entering a UI element"""
	if CursorManager:
		CursorManager.set_clickable_cursor()

static func _handle_mouse_exited():
	"""Handle mouse leaving a UI element"""
	if CursorManager:
		CursorManager.reset_cursor() 