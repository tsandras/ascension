extends RefCounted
class_name CarouselPicker

# Carousel configuration
var current_index: int = 0
var items: Array = []
var item_names: Array = []

# UI elements (will be set when create_carousel is called)
var left_button: Button
var right_button: Button
var display_label: Label
var container: Control

func create_carousel(items_data: Array, item_name_key: String = "name", description_key: String = "description", container_parent: Control = null) -> Control:
	"""Create a carousel UI for selecting from a list of items"""
	
	print("Carousel: Creating carousel with %d items" % items_data.size())
	print("Carousel: Items data: ", items_data)
	
	# Store the items and extract names
	items = items_data
	item_names = []
	for item in items:
		if item.has(item_name_key):
			item_names.append(item[item_name_key])
		else:
			item_names.append(str(item))
	
	print("Carousel: Extracted names: ", item_names)
	
	# Create the carousel container
	var carousel_container = HBoxContainer.new()
	carousel_container.name = "CarouselContainer"
	carousel_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	carousel_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	carousel_container.add_theme_constant_override("separation", 10)
	carousel_container.custom_minimum_size = Vector2(300, 60)  # Ensure minimum size
	
	# No background panel needed - let it blend with the UI
	# The carousel will inherit the parent's styling
	
	# Create left navigation button
	left_button = Button.new()
	left_button.text = "◀"
	left_button.custom_minimum_size = Vector2(50, 50)
	left_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left_button.pressed.connect(_on_left_button_pressed)
	left_button.add_theme_font_size_override("font_size", 20)
	
	# Style the button to match the UI theme
	left_button.add_theme_color_override("font_color", Color.WHITE)
	left_button.add_theme_color_override("font_focus_color", Color.WHITE)
	left_button.add_theme_color_override("font_hover_color", Color.WHITE)
	
	# Add hover effect
	left_button.mouse_entered.connect(_on_left_button_hover_entered)
	left_button.mouse_exited.connect(_on_left_button_hover_exited)
	
	# Create center display label with tooltip support
	display_label = Label.new()
	display_label.text = get_current_item_name()
	display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	display_label.custom_minimum_size = Vector2(200, 50)
	display_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	display_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	display_label.add_theme_font_size_override("font_size", 18)
	
	# Style the label to match the UI theme
	display_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Ensure tooltip is enabled and visible
	display_label.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Add tooltip to display label
	var initial_description = get_current_item_description(description_key)
	display_label.tooltip_text = initial_description
	print("Carousel: Initial tooltip set to: %s" % initial_description)
	print("Carousel: Description key used: %s" % description_key)
	
	# Debug: Print first item data
	if items.size() > 0:
		var first_item = items[0]
		print("Carousel: First item data: ", first_item)
		print("Carousel: First item has description key: ", first_item.has(description_key))
		if first_item.has(description_key):
			print("Carousel: First item description: ", first_item[description_key])
	
	# Debug: Set a fallback text if no items
	if items.size() == 0:
		display_label.text = "No races available"
		print("Carousel: No items, setting fallback text")
	
	# Create right navigation button
	right_button = Button.new()
	right_button.text = "▶"
	right_button.custom_minimum_size = Vector2(50, 50)
	right_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_button.pressed.connect(_on_right_button_pressed)
	right_button.add_theme_font_size_override("font_size", 20)
	
	# Style the button to match the UI theme
	right_button.add_theme_color_override("font_color", Color.WHITE)
	right_button.add_theme_color_override("font_focus_color", Color.WHITE)
	right_button.add_theme_color_override("font_hover_color", Color.WHITE)
	
	# Add hover effect
	right_button.mouse_entered.connect(_on_right_button_hover_entered)
	right_button.mouse_exited.connect(_on_right_button_hover_exited)
	
	# Add elements to container
	carousel_container.add_child(left_button)
	carousel_container.add_child(display_label)
	carousel_container.add_child(right_button)
	
	# Store container reference
	container = carousel_container
	
	# Update button states
	update_button_states()
	
	# Add to parent if provided
	if container_parent:
		print("Carousel: Adding to parent: ", container_parent)
		container_parent.add_child(carousel_container)
		print("Carousel: Added to parent, parent now has %d children" % container_parent.get_child_count())
	else:
		print("Carousel: No parent provided")
	
	print("Carousel: Final carousel container: ", carousel_container)
	return carousel_container

func _on_left_button_pressed():
	"""Handle left button press - go to previous item"""
	if items.size() > 0:
		print("Carousel: Left button pressed - Current index: %d" % current_index)
		current_index -= 1
		if current_index < 0:
			current_index = items.size() - 1
			print("Carousel: Wrapped to end - New index: %d" % current_index)
		update_display()
		update_button_states()

func _on_right_button_pressed():
	"""Handle right button press - go to next item"""
	if items.size() > 0:
		print("Carousel: Right button pressed - Current index: %d" % current_index)
		current_index += 1
		if current_index >= items.size():
			current_index = 0
			print("Carousel: Wrapped to beginning - New index: %d" % current_index)
		update_display()
		update_button_states()

func update_display():
	"""Update the display label with current item"""
	if display_label and items.size() > 0:
		# Ensure index is valid before updating
		ensure_valid_index()
		display_label.text = get_current_item_name()
		# Update tooltip with current item description
		var current_description = get_current_item_description()
		display_label.tooltip_text = current_description
		print("Carousel display updated - Index: %d, Item: %s, Tooltip: %s" % [current_index, get_current_item_name(), current_description])
		
		# Debug: Print current item data
		var current_item = get_current_item()
		print("Carousel: Current item data: ", current_item)
		print("Carousel: Has description key: ", current_item.has("description"))
		if current_item.has("description"):
			print("Carousel: Description value: ", current_item["description"])
	else:
		# No items or no display label
		if display_label:
			display_label.text = "No items"
			display_label.tooltip_text = ""

func ensure_valid_index():
	"""Ensure the current index is within valid bounds"""
	if items.size() > 0:
		if current_index < 0:
			current_index = 0
			print("Carousel: Index was negative, reset to 0")
		elif current_index >= items.size():
			current_index = items.size() - 1
			print("Carousel: Index was out of bounds, reset to %d" % current_index)
	else:
		current_index = 0

func update_button_states():
	"""Update button states based on current position"""
	if items.size() <= 1:
		# Only one or no items, disable both buttons
		if left_button:
			left_button.disabled = true
		if right_button:
			right_button.disabled = true
		return
	
	# Multiple items, enable both buttons
	if left_button:
		left_button.disabled = false
	if right_button:
		right_button.disabled = false

func get_current_item() -> Dictionary:
	"""Get the currently selected item"""
	if items.size() > 0:
		# Ensure current_index is within bounds
		if current_index < 0:
			current_index = 0
		elif current_index >= items.size():
			current_index = items.size() - 1
		
		return items[current_index]
	return {}

func get_current_item_by_name(name_key: String = "name") -> String:
	"""Get the name of the currently selected item"""
	var current_item = get_current_item()
	if current_item.has(name_key):
		return current_item[name_key]
	return ""

func get_current_item_description(description_key: String = "description") -> String:
	"""Get the description of the currently selected item"""
	var current_item = get_current_item()
	if current_item.has(description_key):
		return current_item[description_key]
	return ""

func find_item_index_by_name(item_name: String, name_key: String = "name") -> int:
	"""Find the index of an item by its name"""
	for i in range(items.size()):
		if items[i].has(name_key) and items[i][name_key] == item_name:
			return i
	return -1

func get_current_item_name() -> String:
	"""Get the name of the currently selected item"""
	if items.size() > 0:
		# Ensure current_index is within bounds
		if current_index < 0:
			current_index = 0
		elif current_index >= items.size():
			current_index = items.size() - 1
		
		return item_names[current_index]
	return "No items"

func get_current_index() -> int:
	"""Get the current index"""
	return current_index

func set_current_index(index: int):
	"""Set the current index and update display"""
	if items.size() > 0:
		current_index = index
		ensure_valid_index()
		update_display()
		update_button_states()
		print("Carousel: Set index to %d" % current_index)

func set_items(new_items: Array, item_name_key: String = "name"):
	"""Update the items in the carousel"""
	items = new_items
	item_names = []
	for item in items:
		if item.has(item_name_key):
			item_names.append(item[item_name_key])
		else:
			item_names.append(str(item))
	
	# Reset to first item if current index is out of bounds
	if current_index >= items.size():
		current_index = 0
	
	update_display()
	update_button_states()

func get_items() -> Array:
	"""Get all items in the carousel"""
	return items

func get_item_names() -> Array:
	"""Get all item names in the carousel"""
	return item_names

func has_items() -> bool:
	"""Check if the carousel has any items"""
	return items.size() > 0

func get_item_count() -> int:
	"""Get the total number of items"""
	return items.size()

# Hover effect functions
func _on_left_button_hover_entered():
	"""Handle left button hover enter"""
	if left_button:
		left_button.modulate = Color(1.2, 1.2, 1.2)  # Brighten on hover

func _on_left_button_hover_exited():
	"""Handle left button hover exit"""
	if left_button:
		left_button.modulate = Color.WHITE  # Return to normal

func _on_right_button_hover_entered():
	"""Handle right button hover enter"""
	if right_button:
		right_button.modulate = Color(1.2, 1.2, 1.2)  # Brighten on hover

func _on_right_button_hover_exited():
	"""Handle right button hover exit"""
	if right_button:
		right_button.modulate = Color.WHITE  # Return to normal
