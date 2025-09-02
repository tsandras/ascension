extends VBoxContainer
class_name AvatarDisplay

## AvatarDisplay - Manages the avatar display scene
##
## This scene contains the visual elements including:
## - Title label
## - Avatar selection button with panel background
## - Avatar texture display
##
## Usage:
##   var avatar_display = preload("res://core/ui/avatar_display.tscn").instantiate()
##   parent_node.add_child(avatar_display)
##   avatar_display.load_avatar_textures()
##   avatar_display.set_selected_avatar("female_elf_blond_earmor")

# Store avatar textures
var avatar_textures = {}
# Store selected avatar
var selected_avatar = ""

# Signals
signal avatar_selected(avatar_key: String)

func _ready():
	"""Initialize the avatar display"""
	print("AvatarDisplay scene initialized")
	
	# Connect the avatar area texture button
	var avatar_area = get_node("AvatarAreaTexture")
	if avatar_area:
		avatar_area.pressed.connect(_on_avatar_area_clicked)

	CursorUtils.add_cursor_to_texture_button($AvatarAreaTexture)
	
	# Load avatar textures
	load_avatar_textures()

func load_avatar_textures():
	"""Load all available avatar textures"""
	print("Loading avatar textures...")
	
	# Load all avatar files from the avatars directory
	var dir = DirAccess.open("res://assets/avatars/")
	if dir:
		avatar_textures = {}
		
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".png") and not file_name.ends_with(".import"):
				var avatar_path = "res://assets/avatars/" + file_name
				var texture = load(avatar_path)
				if texture:
					# Store using the filename without extension as the key
					var key = file_name.replace(".png", "")
					avatar_textures[key] = texture
					print("Loaded avatar: ", key, " - Size: ", texture.get_size(), " - Valid: ", texture != null)
				else:
					print("Warning: Failed to load avatar: ", avatar_path)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("Error: Could not open avatars directory")
	
	print("Avatar loading complete. Loaded %d avatars" % avatar_textures.size())

func set_selected_avatar(avatar_key: String):
	"""Set the selected avatar and update display"""
	selected_avatar = avatar_key
	update_avatar_display()
	avatar_selected.emit(avatar_key)

func get_selected_avatar() -> String:
	"""Get the currently selected avatar"""
	return selected_avatar

func update_avatar_display():
	"""Update the avatar display based on selected avatar"""
	print("update_avatar_display() called with selected_avatar: ", selected_avatar)
	var avatar_area = get_node("AvatarAreaTexture")
	var avatar_image = get_node("AvatarAreaTexture/AvatarImage")
	
	if avatar_area and avatar_image:
		if selected_avatar != "" and avatar_textures.has(selected_avatar):
			# Display the selected avatar on top of the frame
			var avatar_texture = avatar_textures[selected_avatar]
			print("Setting avatar image: ", avatar_texture)
			avatar_image.texture = avatar_texture
			avatar_image.visible = true
			print("Avatar updated: ", selected_avatar)
		else:
			# Hide the avatar image, show only the frame
			avatar_image.visible = false
			print("Avatar hidden, showing frame only")
	else:
		print("ERROR: Avatar area or image not found!")

func _on_avatar_area_clicked():
	"""Handle avatar area click - open avatar selection modal"""
	print("Avatar area clicked!")
	show_avatar_selection_modal()

func show_avatar_selection_modal():
	"""Show avatar selection modal dialog"""
	print("Creating avatar selection modal...")
	var modal = create_selection_modal("Select Avatar", avatar_textures, selected_avatar, _on_avatar_selected_from_modal)
	get_tree().current_scene.add_child(modal)
	print("Avatar modal added to scene")

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
	
	# Add texture options (no "None" option for avatars)
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

func _on_avatar_selected_from_modal(avatar_key: String):
	"""Handle avatar selection from modal"""
	set_selected_avatar(avatar_key)
	print("Selected avatar from modal: ", selected_avatar)
	
	# Close modal
	var modal = get_tree().current_scene.get_node_or_null("SelectionModal")
	if modal:
		modal.queue_free()

func reset_to_default():
	"""Reset avatar to default (none selected)"""
	set_selected_avatar("")
