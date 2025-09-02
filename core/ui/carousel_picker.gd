extends HBoxContainer
class_name CarouselPicker

## CarouselPicker - Manages a carousel selection UI component
##
## This scene contains the visual elements including:
## - Left navigation texture button (with arrow icon)
## - Center display label with tooltip support
## - Right navigation texture button (with arrow icon)
##
## Usage:
##   var carousel_picker = preload("res://core/ui/carousel_picker.tscn").instantiate()
##   parent_node.add_child(carousel_picker)
##   carousel_picker.set_items(items_array, "name", "description")
##   carousel_picker.selection_changed.connect(_on_carousel_selection_changed)

# Carousel configuration
var current_index: int = 0
var items: Array = []
var item_names: Array = []
var item_name_key: String = "name"
var description_key: String = "description"

# UI elements (referenced from the scene)
@onready var left_button: TextureButton = $LeftButtonContainer/LeftButton
@onready var right_button: TextureButton = $RightButtonContainer/RightButton
@onready var display_label: Label = $DisplayLabel

@export var click_sound_enabled: bool = true
@export var sound_volume: float = -10.0

# Signals
signal selection_changed(item_index: int, item_data: Dictionary)
signal left_button_pressed()
signal right_button_pressed()

func _ready():
	"""Initialize the carousel picker scene"""
	print("CarouselPicker scene initialized")
	
	# Connect button signals
	if left_button:
		left_button.pressed.connect(_on_left_button_pressed)
		left_button.mouse_entered.connect(_on_left_button_hover_entered)
		left_button.mouse_exited.connect(_on_left_button_hover_exited)
	
	if right_button:
		right_button.pressed.connect(_on_right_button_pressed)
		right_button.mouse_entered.connect(_on_right_button_hover_entered)
		right_button.mouse_exited.connect(_on_right_button_hover_exited)
	
	if display_label:
		# Style the label to match the UI theme
		display_label.add_theme_color_override("font_color", Color.WHITE)
		# Ensure tooltip is enabled and visible
		display_label.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Set separation between elements
	add_theme_constant_override("separation", 10)
	
	# Initialize audio volume for both buttons
	if left_button and left_button.has_node("AudioStreamPlayer"):
		left_button.get_node("AudioStreamPlayer").volume_db = sound_volume
	if right_button and right_button.has_node("AudioStreamPlayer"):
		right_button.get_node("AudioStreamPlayer").volume_db = sound_volume
	
	# Initialize with empty state
	update_display()
	update_button_states()
	CursorUtils.add_cursor_to_texture_button(left_button)
	CursorUtils.add_cursor_to_texture_button(right_button)

func set_items(items_data: Array, name_key: String = "name", desc_key: String = "description"):
	"""Set the items for the carousel"""
	print("Carousel: Setting items with %d items" % items_data.size())
	print("Carousel: Items data: ", items_data)
	
	# Store the items and extract names
	items = items_data
	item_name_key = name_key
	description_key = desc_key
	item_names = []
	
	for item in items:
		if item.has(item_name_key):
			item_names.append(item[item_name_key])
		else:
			item_names.append(str(item))
	
	print("Carousel: Extracted names: ", item_names)
	
	# Reset to first item
	current_index = 0
	
	# Update display
	update_display()
	update_button_states()

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
		# Emit signals
		left_button_pressed.emit()
		selection_changed.emit(current_index, get_current_item())

		# Play click sound from left button's audio player
		if click_sound_enabled and left_button and left_button.has_node("AudioStreamPlayer"):
			left_button.get_node("AudioStreamPlayer").volume_db = sound_volume
			left_button.get_node("AudioStreamPlayer").play()

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
		# Emit signals
		right_button_pressed.emit()
		selection_changed.emit(current_index, get_current_item())

		# Play click sound from right button's audio player
		if click_sound_enabled and right_button and right_button.has_node("AudioStreamPlayer"):
			right_button.get_node("AudioStreamPlayer").volume_db = sound_volume
			right_button.get_node("AudioStreamPlayer").play()

func update_display():
	"""Update the display label with current item"""
	if display_label and items.size() > 0:
		# Ensure index is valid before updating
		ensure_valid_index()
		display_label.text = get_current_item_name()
		# Update tooltip with current item description
		var current_description = get_current_item_description(description_key)
		display_label.tooltip_text = current_description
		print("Carousel display updated - Index: %d, Item: %s, Tooltip: %s" % [current_index, get_current_item_name(), current_description])
		
		# Debug: Print current item data
		var current_item = get_current_item()
		print("Carousel: Current item data: ", current_item)
		print("Carousel: Has description key (%s): %s" % [description_key, current_item.has(description_key)])
		if current_item.has(description_key):
			print("Carousel: Description value: ", current_item[description_key])
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

# Audio control methods
func set_sound_enabled(enabled: bool):
	"""Enable or disable click sounds"""
	click_sound_enabled = enabled

func set_sound_volume(volume: float):
	"""Set the click sound volume"""
	sound_volume = volume
	# Update existing audio players
	if left_button and left_button.has_node("AudioStreamPlayer"):
		left_button.get_node("AudioStreamPlayer").volume_db = sound_volume
	if right_button and right_button.has_node("AudioStreamPlayer"):
		right_button.get_node("AudioStreamPlayer").volume_db = sound_volume
