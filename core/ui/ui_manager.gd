extends RefCounted
class_name UIManager

# Apply consistent styling to common UI elements based on UIConstants

static func setup_main_menu(scene: Control):
	"""Apply main menu styling using UIConstants"""
	var container = scene.get_node("CenterContainer/VBoxContainer")
	var new_game_btn = scene.get_node("CenterContainer/VBoxContainer/NewGameButton")
	var quit_btn = scene.get_node("CenterContainer/VBoxContainer/QuitButton")
	var spacer1 = scene.get_node("CenterContainer/VBoxContainer/Spacer1")
	var spacer2 = scene.get_node("CenterContainer/VBoxContainer/Spacer2")
	
	# Apply container size
	container.custom_minimum_size = UIConstants.CONTAINER_MAIN_MENU
	
	# Apply button sizes
	new_game_btn.custom_minimum_size = UIConstants.BUTTON_MAIN_MENU
	quit_btn.custom_minimum_size = UIConstants.BUTTON_MAIN_MENU
	
	# Apply spacing
	spacer1.custom_minimum_size = Vector2(0, UIConstants.MainMenu.TITLE_SPACER)
	spacer2.custom_minimum_size = Vector2(0, UIConstants.MainMenu.BUTTON_SPACER)

static func setup_character_creation_step1(scene: Control):
	"""Apply character creation step 1 styling using UIConstants"""
	var container = scene.get_node("CenterContainer/VBoxContainer")
	var spacer1 = scene.get_node("CenterContainer/VBoxContainer/Spacer1")
	var spacer2 = scene.get_node("CenterContainer/VBoxContainer/Spacer2") 
	var spacer3 = scene.get_node("CenterContainer/VBoxContainer/Spacer3")
	var back_btn = scene.get_node("CenterContainer/VBoxContainer/ButtonsContainer/BackButton")
	var continue_btn = scene.get_node("CenterContainer/VBoxContainer/ButtonsContainer/ContinueButton")
	var button_spacer = scene.get_node("CenterContainer/VBoxContainer/ButtonsContainer/Spacer4")
	
	# Apply container size
	container.custom_minimum_size = UIConstants.CONTAINER_CHARACTER_CREATION_STEP1
	
	# Apply spacing (adjusted for horizontal layout)
	spacer1.custom_minimum_size = Vector2(0, 40)  # After title
	spacer2.custom_minimum_size = Vector2(0, 30)  # After points label
	spacer3.custom_minimum_size = Vector2(0, 60)  # Before buttons
	button_spacer.custom_minimum_size = Vector2(40, 0)  # Between buttons
	
	# Apply button sizes
	back_btn.custom_minimum_size = UIConstants.BUTTON_BACK_CONTINUE
	continue_btn.custom_minimum_size = UIConstants.BUTTON_BACK_CONTINUE

static func setup_character_creation_step2(scene: Control):
	"""Apply character creation step 2 styling using UIConstants"""
	var container = scene.get_node("CenterContainer/VBoxContainer")
	var spacer1 = scene.get_node("CenterContainer/VBoxContainer/Spacer1")
	var spacer3 = scene.get_node("CenterContainer/VBoxContainer/Spacer3")
	var back_btn = scene.get_node("CenterContainer/VBoxContainer/ButtonsContainer/BackButton")
	var continue_btn = scene.get_node("CenterContainer/VBoxContainer/ButtonsContainer/ContinueButton")
	var button_spacer = scene.get_node("CenterContainer/VBoxContainer/ButtonsContainer/Spacer4")
	
	# Apply container size
	container.custom_minimum_size = UIConstants.CONTAINER_CHARACTER_CREATION_STEP2
	
	# Apply spacing (adjusted for horizontal layout)
	spacer1.custom_minimum_size = Vector2(0, 40)  # After title
	spacer3.custom_minimum_size = Vector2(0, 60)  # Before buttons
	button_spacer.custom_minimum_size = Vector2(40, 0)  # Between buttons
	
	# Apply button sizes
	back_btn.custom_minimum_size = UIConstants.BUTTON_BACK_CONTINUE
	continue_btn.custom_minimum_size = UIConstants.BUTTON_BACK_CONTINUE

static func create_attribute_row_elements() -> Dictionary:
	"""Create a set of UI elements for an attribute row using constants"""
	var elements = {}
	
	# Create label
	var label = Label.new()
	label.custom_minimum_size = Vector2(UIConstants.LABEL_ATTRIBUTE_WIDTH, 0)
	elements["label"] = label
	
	# Create minus button
	var minus_button = Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = UIConstants.BUTTON_PLUS_MINUS
	elements["minus_button"] = minus_button
	
	# Create value label
	var value_label = Label.new()
	value_label.custom_minimum_size = Vector2(UIConstants.LABEL_VALUE_WIDTH, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elements["value_label"] = value_label
	
	# Create plus button
	var plus_button = Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = UIConstants.BUTTON_PLUS_MINUS
	elements["plus_button"] = plus_button
	
	return elements

static func apply_color_feedback(label: Label, remaining_points: int):
	"""Apply color feedback to points label based on remaining points"""
	if remaining_points > 0:
		label.modulate = UIConstants.Colors.POINTS_REMAINING
	else:
		label.modulate = UIConstants.Colors.POINTS_COMPLETE

static func apply_button_state(button: Button, enabled: bool):
	"""Apply visual state to button based on enabled status"""
	button.disabled = not enabled
	if enabled:
		button.modulate = UIConstants.Colors.BUTTON_NORMAL
	else:
		button.modulate = UIConstants.Colors.BUTTON_DISABLED

static func flash_error_feedback(label: Label):
	"""Create error flash effect for labels"""
	label.modulate = UIConstants.Colors.POINTS_ERROR
	var tween = label.create_tween()
	tween.tween_property(label, "modulate", UIConstants.Colors.POINTS_REMAINING, 0.5) 
