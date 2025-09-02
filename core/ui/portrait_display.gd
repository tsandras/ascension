extends VBoxContainer
class_name PortraitDisplay

## PortraitDisplay - Manages the portrait display scene
##
## This scene contains the visual elements including:
## - Title label
## - Portrait selection button with panel background
## - Portrait texture display
##
## Usage:
##   var portrait_display = preload("res://core/ui/portrait_display.tscn").instantiate()
##   parent_node.add_child(portrait_display)
##   portrait_display.load_portrait_textures()
##   portrait_display.set_selected_portrait("female_elf")

# Store portrait textures
var portrait_textures = {}
# Store selected portrait
var selected_portrait = ""

# Signals
signal portrait_selected(portrait_key: String)

func _ready():
	"""Initialize the portrait display"""
	print("PortraitDisplay scene initialized")
	
	# Connect the portrait area texture button
	var portrait_area = get_node("PortraitAreaTexture")
	if portrait_area:
		portrait_area.pressed.connect(_on_portrait_area_clicked)

	CursorUtils.add_cursor_to_texture_button($PortraitAreaTexture)
	
	# Load portrait textures
	load_portrait_textures()

func load_portrait_textures():
	"""Load all available portrait textures"""
	print("Loading portrait textures...")
	
	# Load all portrait files from the ink_portraits directory
	var dir = DirAccess.open("res://assets/ink_portraits/")
	if dir:
		portrait_textures = {}
		
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".png") and not file_name.ends_with(".import"):
				var portrait_path = "res://assets/ink_portraits/" + file_name
				var texture = load(portrait_path)
				if texture:
					# Store using the filename without extension as the key
					var key = file_name.replace(".png", "")
					portrait_textures[key] = texture
					print("Loaded portrait: ", key, " - Size: ", texture.get_size(), " - Valid: ", texture != null)
				else:
					print("Warning: Failed to load portrait: ", portrait_path)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("Error: Could not open ink_portraits directory")
	
	print("Portrait loading complete. Loaded %d portraits" % portrait_textures.size())

func set_selected_portrait(portrait_key: String):
	"""Set the selected portrait and update display"""
	selected_portrait = portrait_key
	update_portrait_display()
	portrait_selected.emit(portrait_key)

func get_selected_portrait() -> String:
	"""Get the currently selected portrait"""
	return selected_portrait

func update_portrait_display():
	"""Update the portrait display based on selected portrait"""
	print("update_portrait_display() called with selected_portrait: ", selected_portrait)
	var portrait_area = get_node("PortraitAreaTexture")
	var portrait_image = get_node("PortraitAreaTexture/PortraitImage")
	
	if portrait_area and portrait_image:
		if selected_portrait != "" and portrait_textures.has(selected_portrait):
			# Display the selected portrait on top of the frame
			var portrait_texture = portrait_textures[selected_portrait]
			print("Setting portrait image: ", portrait_texture)
			portrait_image.texture = portrait_texture
			portrait_image.visible = true
			print("Portrait updated: ", selected_portrait)
		else:
			# Hide the portrait image, show only the frame
			portrait_image.visible = false
			print("Portrait hidden, showing frame only")
	else:
		print("ERROR: Portrait area or image not found!")

func _on_portrait_area_clicked():
	"""Handle portrait area click - open portrait selection modal"""
	print("Portrait area clicked!")
	show_portrait_selection_modal()

func show_portrait_selection_modal():
	"""Show portrait selection modal dialog"""
	print("Creating portrait selection modal...")
	var modal = create_selection_modal("Select Portrait", portrait_textures, selected_portrait, _on_portrait_selected_from_modal)
	get_tree().current_scene.add_child(modal)
	print("Portrait modal added to scene")

func create_selection_modal(title: String, textures: Dictionary, current_selection: String, selection_callback: Callable) -> Control:
	"""Create a modal dialog for selecting textures"""
	print("Creating selection modal for: ", title)
	print("Available textures: ", textures.keys())
	# Create modal background
	var modal = Control.new()
	modal.name = "SelectionModal"
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create modal content
	var modal_content = VBoxContainer.new()
	modal_content.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	modal_content.custom_minimum_size = Vector2(800, 600)
	modal_content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	modal_content.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Add a background panel to modal_content to make it easier to detect clicks
	var content_panel = Panel.new()
	content_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_content.add_child(content_panel)
	# Move the panel to the back so it's behind all other content
	modal_content.move_child(content_panel, 0)
	
	# Add title
	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	modal_content.add_child(title_label)
	
	# Create scrollable grid for textures
	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(780, 500)
	modal_content.add_child(scroll_container)
	
	var grid_container = GridContainer.new()
	grid_container.columns = 5
	scroll_container.add_child(grid_container)
	
	# Add "None" option for portraits
	var none_container = VBoxContainer.new()
	
	var none_button = TextureButton.new()
	none_button.custom_minimum_size = Vector2(50, 50)
	none_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	none_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	none_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
	
	# Connect selection
	none_button.pressed.connect(selection_callback.bind(""))
	
	none_container.add_child(none_button)
	
	var none_label = Label.new()
	none_label.text = "None"
	none_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	none_label.add_theme_font_size_override("font_size", 12)
	none_container.add_child(none_label)
	
	grid_container.add_child(none_container)
	
	# Add texture options
	var texture_keys = textures.keys()
	texture_keys.sort()
	
	for texture_key in texture_keys:
		# Create a container for the texture and make it clickable
		var texture_container = VBoxContainer.new()
		texture_container.custom_minimum_size = Vector2(60, 60)
		
		# Use TextureRect for more reliable texture display
		var texture_rect = TextureRect.new()
		texture_rect.custom_minimum_size = Vector2(50, 50)
		texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		texture_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		
		# Debug: Print texture info
		print("Setting texture for key: ", texture_key)
		print("Texture object: ", textures[texture_key])
		print("Texture size: ", textures[texture_key].get_size() if textures[texture_key] else "null")
		
		texture_rect.texture = textures[texture_key]
		
		# Make the entire container clickable
		texture_container.gui_input.connect(_on_texture_container_input.bind(texture_key, selection_callback))
		
		texture_container.add_child(texture_rect)
		
		# Add label below texture
		var name_label = Label.new()
		name_label.text = texture_key.replace("_", " ").capitalize()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 12)
		texture_container.add_child(name_label)
		
		grid_container.add_child(texture_container)
	
	# Add close button
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(100, 40)
	close_button.pressed.connect(modal.queue_free)
	modal_content.add_child(close_button)
	
	modal.add_child(modal_content)
	
	# Make modal clickable
	modal.gui_input.connect(_on_modal_input.bind(modal))
	
	return modal

func _on_modal_input(event: InputEvent, modal: Control):
	"""Handle modal input - close on background click"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Get the modal content (the VBoxContainer with the actual content)
		var modal_content = modal.get_child(0)  # First child should be the VBoxContainer
		if modal_content:
			# Convert global mouse position to local position relative to modal content
			var content_rect = Rect2(modal_content.global_position, modal_content.size)
			if not content_rect.has_point(event.global_position):
				# Click is outside the modal content, close the modal
				modal.queue_free()

func _on_texture_container_input(event: InputEvent, texture_key: String, selection_callback: Callable):
	"""Handle clicks on texture containers"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Call the selection callback
		selection_callback.call(texture_key)

func _on_portrait_selected_from_modal(portrait_key: String):
	"""Handle portrait selection from modal"""
	set_selected_portrait(portrait_key)
	print("Selected portrait from modal: ", selected_portrait)
	
	# Close modal
	var modal = get_tree().current_scene.get_node_or_null("SelectionModal")
	if modal:
		modal.queue_free()

func reset_to_default():
	"""Reset portrait to default (none selected)"""
	set_selected_portrait("")
