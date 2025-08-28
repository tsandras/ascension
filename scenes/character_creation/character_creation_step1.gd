extends Control

# Manager instances
var attribute_manager: AllocationManager
var race_manager: AllocationManager
var background_manager: AllocationManager
var features_manager: AllocationManager
var attributes_display: AttributesDisplay
var abilities_display: AbilitiesDisplay
var race_carousel: CarouselPicker
var background_carousel: CarouselPicker
var features_carousel: CarouselPicker

# UI node references
@onready var points_label = $CenterContainer/VBoxContainer/PointsLabel
@onready var character_name_input = $CenterContainer/VBoxContainer/CharacterNameInput
@onready var male_button = $CenterContainer/VBoxContainer/ContentContainer/Column2/SexContainer/SexButtonsContainer/MaleButton
@onready var female_button = $CenterContainer/VBoxContainer/ContentContainer/Column2/SexContainer/SexButtonsContainer/FemaleButton
@onready var avatar_sprite = $CenterContainer/VBoxContainer/ContentContainer/Column2/PortraitAvatarContainer/AvatarSubColumn/AvatarContainer/AvatarSprite

@onready var race_container = $CenterContainer/VBoxContainer/ContentContainer/Column1/RaceContainer
@onready var background_container = $CenterContainer/VBoxContainer/ContentContainer/Column1/BackgroundContainer
@onready var features_container = $CenterContainer/VBoxContainer/ContentContainer/Column1/FeaturesContainer

@onready var back_button = $CenterContainer/VBoxContainer/ButtonsContainer/BackButton
@onready var continue_button = $CenterContainer/VBoxContainer/ButtonsContainer/ContinueButton

# Store the attributes area for reuse
var attributes_area_node: Control
# Store the abilities area for reuse
var abilities_area_node: Control

# Store race data with trait information
var race_data = {}
# Store selected sex
var selected_sex = ""
# Store selected portrait and avatar
var selected_portrait = ""
var selected_avatar = ""
# Store avatar textures
var avatar_textures = {}
# Store portrait textures
var portrait_textures = {}
# Store trait icons
var trait_icons = {}

func _ready():
	# Apply UI constants to this scene
	UIManager.setup_character_creation_step1(self)
	
	# Wait a bit to ensure DatabaseManager is fully initialized
	# Note: In Godot 4, DatabaseManager should be ready immediately
	
	# Initialize the managers
	print("DEBUG: Initializing managers...")
	attribute_manager = AllocationManager.new("attributes", "attributes", 5)
	race_manager = AllocationManager.new("races", "races", 0)  # Races don't use points
	background_manager = AllocationManager.new("backgrounds", "backgrounds", 0)  # Backgrounds don't use points
	features_manager = AllocationManager.new("features", "features", 0)  # Features don't use points
	attributes_display = AttributesDisplay.new()
	abilities_display = AbilitiesDisplay.new()
	race_carousel = CarouselPicker.new()
	background_carousel = CarouselPicker.new()
	features_carousel = CarouselPicker.new()
	print("DEBUG: Managers initialized")
	
	# Generate the UI dynamically
	generate_portrait_avatar_ui()
	
	# Connect character name input signal (with null check)
	if character_name_input:
		character_name_input.text_changed.connect(_on_character_name_changed)
	else:
		print("Warning: Character name input not found")
	
	# Connect sex selection buttons (with null checks)
	if male_button:
		male_button.pressed.connect(_on_male_button_pressed)
	else:
		print("Warning: Male button not found")
	if female_button:
		female_button.pressed.connect(_on_female_button_pressed)
	else:
		print("Warning: Female button not found")
	
	# Add cursor functionality to buttons
	add_cursor_to_buttons()
	
	# Load avatar and portrait textures
	load_avatar_textures()
	load_portrait_textures()
	# Load trait icons
	load_trait_icons()
	

	
	# Wait for UI elements to be added to scene tree
	# Note: In Godot 4, UI elements are added immediately
	
	# Load existing character data if returning from step 2
	load_existing_character_data()
	
	# Update the UI
	print("DEBUG: Calling update_ui...")
	update_ui()
	print("DEBUG: _ready function completed")

func add_cursor_to_buttons():
	"""Add cursor functionality to all buttons"""
	# Add cursor to sex selection buttons
	if male_button:
		CursorUtils.add_cursor_to_button(male_button)
	if female_button:
		CursorUtils.add_cursor_to_button(female_button)
	
	# Add cursor to navigation buttons
	if back_button:
		CursorUtils.add_cursor_to_button(back_button)
	if continue_button:
		CursorUtils.add_cursor_to_button(continue_button)

func load_existing_character_data():
	"""Load existing character data if user is returning from step 2"""
	print("DEBUG: load_existing_character_data called")
	if not CharacterCreation.has_complete_data():
		print("No existing character data to load")
		return
	
	print("Loading existing character data...")
	
	# Load character name
	if CharacterCreation.character_name != "":
		character_name_input.text = CharacterCreation.character_name
		print("Loaded character name: " + CharacterCreation.character_name)
	
	# Load selected race
	if CharacterCreation.selected_race != "":
		print("DEBUG: Loading existing race selection: ", CharacterCreation.selected_race)
		race_manager.select_race(CharacterCreation.selected_race)
		# Note: Race carousel will be created later in generate_portrait_avatar_ui()
		# Race selection will be applied after carousel creation
		print("Loaded selected race: " + CharacterCreation.selected_race)
	else:
		print("DEBUG: No existing race selection found")
	
	# Load selected background
	if CharacterCreation.selected_background != "":
		background_manager.select_background(CharacterCreation.selected_background)
		# Note: Background carousel will be created later in generate_portrait_avatar_ui()
		# Background selection will be applied after carousel creation
		print("Loaded selected background: " + CharacterCreation.selected_background)
	else:
		print("DEBUG: No existing background selection found")
	
	# Load selected feature
	if CharacterCreation.selected_feature != "":
		features_manager.select_feature(CharacterCreation.selected_feature)
		# Note: Features carousel will be created later in generate_portrait_avatar_ui()
		# Features selection will be applied after carousel creation
		print("Loaded selected feature: " + CharacterCreation.selected_feature)
	else:
		print("DEBUG: No existing feature selection found")
	
	# Load selected sex
	if CharacterCreation.selected_sex != "":
		selected_sex = CharacterCreation.selected_sex
		update_sex_buttons()
		print("Loaded selected sex: " + selected_sex)
	
	# Load selected portrait
	if CharacterCreation.selected_portrait != "":
		selected_portrait = CharacterCreation.selected_portrait
		update_portrait_display()
		print("Loaded selected portrait: " + selected_portrait)
	
	# Load selected avatar
	if CharacterCreation.selected_avatar != "":
		selected_avatar = CharacterCreation.selected_avatar
		update_avatar_display()
		print("Loaded selected avatar: " + selected_avatar)
	
	# Load attribute allocations
	if CharacterCreation.attributes.size() > 0:
		print("Loading attribute allocations...")
		for attribute_name in CharacterCreation.attributes:
			var value = CharacterCreation.attributes[attribute_name]
			var base_value = attribute_manager.get_item_base_value(attribute_name)
			var points_to_add = value - base_value
			
			# Add points one by one to respect the allocation system
			for i in range(points_to_add):
				if not attribute_manager.increase_item(attribute_name):
					print("Warning: Could not fully restore attribute " + attribute_name)
					break
			
			print("Loaded %s: %d (added %d points)" % [attribute_name, value, points_to_add])
	
	print("Character data loading complete")

func generate_race_ui():
	print("DEBUG: generate_race_ui called")
	# Clear existing children
	for child in race_container.get_children():
		child.queue_free()
	
	# Wait for children to be freed
	# Note: Children are freed immediately in Godot 4
	
	# Debug race container
	print("Race container: ", race_container)
	print("Race container visible: ", race_container.visible)
	print("Race container size: ", race_container.size)
	print("Race container position: ", race_container.position)
	
	# Get all race data (including trait information)
	var races = DatabaseManager.get_all_races()
	print("Races data: ", races)
	
	# Store race data for trait display
	for race in races:
		race_data[race.name] = race
		print("DEBUG: Stored race data for: ", race.name)
	
	# Create race label
	var race_label = Label.new()
	race_label.text = "SELECT RACE"
	race_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	race_label.add_theme_font_size_override("font_size", 16)
	race_container.add_child(race_label)
	
	# Add some spacing
	var race_spacer = Control.new()
	race_spacer.custom_minimum_size = Vector2(0, 20)
	race_container.add_child(race_spacer)
	
	# Create race carousel
	print("Creating race carousel with %d races" % races.size())
	var carousel_container = race_carousel.create_carousel(races, "name", "description", race_container)
	print("Carousel container created: ", carousel_container)
	print("Race container children count: ", race_container.get_child_count())
	
	# Use call_deferred to ensure the carousel is fully created before connecting signals
	print("DEBUG: Scheduling race carousel signal connection...")
	call_deferred("_connect_race_carousel_signals")
	
	# Initial race selection will be set after signals are connected
	
	# Add some spacing after the race carousel
	var race_bottom_spacer = Control.new()
	race_bottom_spacer.custom_minimum_size = Vector2(0, 20)
	race_container.add_child(race_bottom_spacer)

func _connect_race_carousel_signals():
	"""Connect race carousel signals after it's fully created"""
	print("DEBUG: _connect_race_carousel_signals called")
	# Connect carousel selection change (with null checks)
	if race_carousel and race_carousel.left_button and race_carousel.right_button:
		print("DEBUG: Connecting race carousel button signals...")
		race_carousel.left_button.pressed.connect(_on_race_carousel_changed)
		race_carousel.right_button.pressed.connect(_on_race_carousel_changed)
		
		# Add cursor functionality to carousel buttons
		CursorUtils.add_cursor_to_button(race_carousel.left_button)
		CursorUtils.add_cursor_to_button(race_carousel.right_button)
		print("Race carousel buttons connected successfully")
		
		# Now that signals are connected, we can set initial race selection
		print("DEBUG: Setting initial race selection...")
		_set_initial_race_selection()
	else:
		print("ERROR: Race carousel buttons not found!")
		print("Race carousel: ", race_carousel)
		if race_carousel:
			print("Left button: ", race_carousel.left_button)
			print("Right button: ", race_carousel.right_button)

func _set_initial_race_selection():
	"""Set initial race selection after carousel is ready"""
	print("DEBUG: _set_initial_race_selection called")
	if not race_carousel:
		print("Warning: Race carousel not available for initial selection")
		return
		
	var races = DatabaseManager.get_all_races()
	print("DEBUG: Found %d races in database" % races.size())
	if races.size() > 0:
		# If we have a previously selected race, set it in the carousel
		if CharacterCreation.selected_race != "":
			var race_index = race_carousel.find_item_index_by_name(CharacterCreation.selected_race, "name")
			if race_index >= 0:
				race_carousel.set_current_index(race_index)
				print("Set carousel to previously selected race: " + CharacterCreation.selected_race)
		
		# Trigger the race selection change to update traits
		print("DEBUG: Triggering race carousel change...")
		_on_race_carousel_changed()
	else:
		print("Warning: No races available for initial selection")



func generate_portrait_avatar_ui():
	"""Generate UI for portrait and avatar selection"""
	print("DEBUG: generate_portrait_avatar_ui called")
	# Find the portrait and avatar containers in the new subcolumn structure
	var portrait_container = $CenterContainer/VBoxContainer/ContentContainer/Column2/PortraitAvatarContainer/PortraitSubColumn/PortraitContainer
	var avatar_container = $CenterContainer/VBoxContainer/ContentContainer/Column2/PortraitAvatarContainer/AvatarSubColumn/AvatarContainer
	
	# Create clickable portrait area
	var portrait_area = Button.new()
	portrait_area.name = "PortraitArea"
	portrait_area.custom_minimum_size = Vector2(200, 200)
	portrait_area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_area.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_area.pressed.connect(_on_portrait_area_clicked)
	
	# Set button text to indicate it's clickable
	portrait_area.text = "Click to select\nPortrait"
	
	# Add a border/background to make it clear it's clickable
	var portrait_panel = Panel.new()
	portrait_panel.name = "PortraitPanel"
	portrait_panel.add_child(portrait_area)
	portrait_panel.custom_minimum_size = Vector2(200, 200)
	
	portrait_container.add_child(portrait_panel)
	
	# Create clickable avatar area
	var avatar_area = Button.new()
	avatar_area.name = "AvatarArea"
	avatar_area.custom_minimum_size = Vector2(200, 200)
	avatar_area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	avatar_area.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar_area.pressed.connect(_on_avatar_area_clicked)
	
	# Set button text to indicate it's clickable
	avatar_area.text = "Click to select\nAvatar"
	
	# Add a border/background to make it clear it's clickable
	var avatar_panel = Panel.new()
	avatar_panel.name = "AvatarPanel"
	avatar_panel.add_child(avatar_area)
	avatar_panel.custom_minimum_size = Vector2(200, 200)
	
	avatar_container.add_child(avatar_panel)
	
	# Create attributes area with SVG symbols and add to Column1 (left side)
	# Create a character object to pass to the attributes display
	var character = Character.new()
	character.name = character_name_input.text if character_name_input else ""
	var selected_race = race_manager.get_selected_race() if race_manager else ""
	var selected_background = background_manager.get_selected_background() if background_manager else ""
	var selected_feature = features_manager.get_selected_feature() if features_manager else ""
	character.race_name = selected_race
	character.background_name = selected_background
	character.feature_name = selected_feature
	character.sex = selected_sex
	character.portrait = selected_portrait
	character.avatar = selected_avatar
	character.attributes = attribute_manager.get_character_items() if attribute_manager else {}
	print("DEBUG: race_manager.get_selected_race() returned: '%s'" % selected_race)
	
	# Debug: Print character data
	print("Creating character for attributes display:")
	print("  Name: ", character.name)
	print("  Race: ", character.race_name)
	print("  Background: ", character.background_name)
	print("  Feature: ", character.feature_name)
	print("  Sex: ", character.sex)
	print("  Attributes: ", character.attributes)
	print("DEBUG: race_manager.get_selected_race() returned: '%s'" % selected_race)
	
	attributes_area_node = attributes_display.create_attributes_area(character)
	var column1 = $CenterContainer/VBoxContainer/ContentContainer/Column1
	column1.add_child(attributes_area_node)
	print("Attributes area created and added to Column1 (left side)")
	
	# Create abilities area with the abilities display
	abilities_area_node = abilities_display.create_abilities_area(character)
	column1.add_child(abilities_area_node)
	print("Abilities area created and added to Column1 (left side)")
	print("DEBUG: race_manager.get_selected_race() returned: '%s'" % selected_race)
	
	# Create race carousel after attributes and abilities
	print("DEBUG: Calling generate_race_ui...")
	generate_race_ui()
	print("Race carousel created and added to Column1 (left side)")
	
	# Create background carousel after race carousel
	print("DEBUG: Calling generate_background_ui...")
	generate_background_ui()
	print("Background carousel created and added to Column1 (left side)")
	
	# Create features carousel after background carousel
	print("DEBUG: Calling generate_features_ui...")
	generate_features_ui()
	print("Features carousel created and added to Column1 (left side)")

func get_attributes_area() -> Control:
	"""Get the attributes area node - useful for other parts of the game"""
	return attributes_area_node

func get_abilities_area() -> Control:
	"""Get the abilities area node - useful for other parts of the game"""
	return abilities_area_node

func update_attributes_display():
	"""Update the attributes display with current character data"""
	if attributes_area_node and attribute_manager:
		# Remove the old attributes area
		var column1 = $CenterContainer/VBoxContainer/ContentContainer/Column1
		column1.remove_child(attributes_area_node)
		attributes_area_node.queue_free()
		
		# Create a new character object with current data
		var character = Character.new()
		character.name = character_name_input.text if character_name_input else ""
		var selected_race = race_manager.get_selected_race() if race_manager else ""
		var selected_background = background_manager.get_selected_background() if background_manager else ""
		var selected_feature = features_manager.get_selected_feature() if features_manager else ""
		character.race_name = selected_race
		character.background_name = selected_background
		character.feature_name = selected_feature
		character.sex = selected_sex
		character.portrait = selected_portrait
		character.avatar = selected_avatar
		character.attributes = attribute_manager.get_character_items()
		
		# Create new attributes area with updated character data
		attributes_area_node = attributes_display.create_attributes_area(character)
		column1.add_child(attributes_area_node)
		print("Attributes display updated with current character data")
		print("DEBUG: race_manager.get_selected_race() returned: '%s'" % selected_race)
		
		# Also update abilities area
		update_abilities_display()
		
		# Also update race carousel display (only if it exists)
		if race_carousel:
			update_race_carousel_display()
		
		# Also update background carousel display (only if it exists)
		if background_carousel:
			update_background_carousel_display()

func _on_race_carousel_changed():
	"""Handle race selection change in the carousel"""
	print("DEBUG: _on_race_carousel_changed called")
	if not race_carousel:
		print("Warning: Race carousel is null in _on_race_carousel_changed")
		return
		
	var selected_race_data = race_carousel.get_current_item()
	print("DEBUG: Selected race data: ", selected_race_data)
	if selected_race_data and selected_race_data.has("name"):
		var race_name = selected_race_data.name
		print("DEBUG: Calling _on_race_selected with: ", race_name)
		_on_race_selected(race_name)
	else:
		print("Warning: No valid race data in carousel")
	
	print("DEBUG: _on_race_carousel_changed completed")



func update_race_carousel_display():
	"""Update the race carousel display to show current selection"""
	if race_carousel and race_carousel.has_items():
		var current_race = race_carousel.get_current_item()
		if current_race.has("name"):
			# Update the carousel display
			race_carousel.update_display()
			print("Race carousel display updated")
	else:
		print("Race carousel not available for update")

func refresh_race_carousel():
	"""Refresh the entire race carousel (useful when returning from step 2)"""
	var column1 = $CenterContainer/VBoxContainer/ContentContainer/Column1
	
	# Remove existing race carousel if it exists
	var existing_race_container = column1.get_node_or_null("RaceContainer")
	if existing_race_container:
		column1.remove_child(existing_race_container)
		existing_race_container.queue_free()
	
	# Create new race carousel
	generate_race_ui()
	print("Race carousel refreshed")

func generate_background_ui():
	"""Generate UI for background selection"""
	# Clear existing children
	for child in background_container.get_children():
		child.queue_free()
	
	# Note: Children are freed immediately in Godot 4
	
	# Debug background container
	print("Background container: ", background_container)
	print("Background container visible: ", background_container.visible)
	print("Background container size: ", background_container.size)
	print("Background container position: ", background_container.position)
	
	# Get all background data
	var backgrounds = DatabaseManager.get_all_backgrounds()
	print("Backgrounds data: ", backgrounds)
	
	# Create background label
	var background_label = Label.new()
	background_label.text = "SELECT BACKGROUND"
	background_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	background_label.add_theme_font_size_override("font_size", 16)
	background_container.add_child(background_label)
	
	# Add some spacing
	var background_spacer = Control.new()
	background_spacer.custom_minimum_size = Vector2(0, 20)
	background_container.add_child(background_spacer)
	
	# Create background carousel
	print("Creating background carousel with %d backgrounds" % backgrounds.size())
	var carousel_container = background_carousel.create_carousel(backgrounds, "name", "description", background_container)
	print("Background carousel container created: ", carousel_container)
	print("Background container children count: ", background_container.get_child_count())
	
	# Use call_deferred to ensure the carousel is fully created before connecting signals
	call_deferred("_connect_background_carousel_signals")
	
	# Initial background selection will be set after signals are connected
	
	# Add some spacing after the background carousel
	var background_bottom_spacer = Control.new()
	background_bottom_spacer.custom_minimum_size = Vector2(0, 20)
	background_container.add_child(background_bottom_spacer)

func _connect_background_carousel_signals():
	"""Connect background carousel signals after it's fully created"""
	# Connect carousel selection change (with null checks)
	if background_carousel and background_carousel.left_button and background_carousel.right_button:
		background_carousel.left_button.pressed.connect(_on_background_carousel_changed)
		background_carousel.right_button.pressed.connect(_on_background_carousel_changed)
		
		# Add cursor functionality to carousel buttons
		CursorUtils.add_cursor_to_button(background_carousel.left_button)
		CursorUtils.add_cursor_to_button(background_carousel.right_button)
		print("Background carousel buttons connected successfully")
		
		# Now that signals are connected, we can set initial background selection
		_set_initial_background_selection()
	else:
		print("ERROR: Background carousel buttons not found!")
		print("Background carousel: ", background_carousel)
		if background_carousel:
			print("Left button: ", background_carousel.left_button)
			print("Right button: ", background_carousel.right_button)

func _set_initial_background_selection():
	"""Set initial background selection after carousel is ready"""
	if not background_carousel:
		print("Warning: Background carousel not available for initial selection")
		return
		
	var backgrounds = DatabaseManager.get_all_backgrounds()
	if backgrounds.size() > 0:
		# If we have a previously selected background, set it in the carousel
		if CharacterCreation.selected_background != "":
			var background_index = background_carousel.find_item_index_by_name(CharacterCreation.selected_background, "name")
			if background_index >= 0:
				background_carousel.set_current_index(background_index)
				print("Set carousel to previously selected background: " + CharacterCreation.selected_background)
		
		# Trigger the background selection change to update abilities
		_on_background_carousel_changed()
	else:
		print("Warning: No backgrounds available for initial selection")

func _connect_features_carousel_signals():
	"""Connect features carousel signals after it's fully created"""
	print("DEBUG: _connect_features_carousel_signals called")
	# Connect carousel selection change (with null checks)
	if features_carousel and features_carousel.left_button and features_carousel.right_button:
		print("DEBUG: Connecting features carousel button signals...")
		features_carousel.left_button.pressed.connect(_on_features_carousel_changed)
		features_carousel.right_button.pressed.connect(_on_features_carousel_changed)
		
		# Add cursor functionality to carousel buttons
		CursorUtils.add_cursor_to_button(features_carousel.left_button)
		CursorUtils.add_cursor_to_button(features_carousel.right_button)
		print("Features carousel buttons connected successfully")
		
		# Now that signals are connected, we can set initial features selection
		print("DEBUG: Setting initial features selection...")
		_set_initial_features_selection()
	else:
		print("ERROR: Features carousel buttons not found!")
		print("Features carousel: ", features_carousel)
		if features_carousel:
			print("Left button: ", features_carousel.left_button)
			print("Right button: ", features_carousel.right_button)

func _set_initial_features_selection():
	"""Set initial features selection after carousel is ready"""
	print("DEBUG: _set_initial_features_selection called")
	if not features_carousel:
		print("Warning: Features carousel not available for initial selection")
		return
		
	var features = DatabaseManager.get_all_features()
	print("DEBUG: Found %d features in database" % features.size())
	if features.size() > 0:
		# If we have a previously selected feature, set it in the carousel
		if CharacterCreation.selected_feature != "":
			var feature_index = features_carousel.find_item_index_by_name(CharacterCreation.selected_feature, "name")
			if feature_index >= 0:
				features_carousel.set_current_index(feature_index)
				print("Set carousel to previously selected feature: " + CharacterCreation.selected_feature)
		
		# Trigger the features selection change to update abilities
		print("DEBUG: Triggering features carousel change...")
		_on_features_carousel_changed()
	else:
		print("Warning: No features available for initial selection")

func _on_background_carousel_changed():
	"""Handle background selection change in the carousel"""
	if not background_carousel:
		print("Warning: Background carousel is null in _on_background_carousel_changed")
		return
		
	var selected_background_data = background_carousel.get_current_item()
	if selected_background_data and selected_background_data.has("name"):
		var background_name = selected_background_data.name
		_on_background_selected(background_name)
	else:
		print("Warning: No valid background data in carousel")

func _on_features_carousel_changed():
	"""Handle features selection change in the carousel"""
	print("DEBUG: _on_features_carousel_changed called")
	if not features_carousel:
		print("Warning: Features carousel is null in _on_features_carousel_changed")
		return
		
	var selected_feature_data = features_carousel.get_current_item()
	print("DEBUG: Selected feature data: ", selected_feature_data)
	if selected_feature_data and selected_feature_data.has("name"):
		var feature_name = selected_feature_data.name
		print("DEBUG: Calling _on_feature_selected with: ", feature_name)
		_on_feature_selected(feature_name)
	else:
		print("Warning: No valid feature data in carousel")
	
	print("DEBUG: _on_features_carousel_changed completed")

func generate_features_ui():
	"""Generate UI for feature selection"""
	print("DEBUG: generate_features_ui called")
	# Clear existing children
	for child in features_container.get_children():
		child.queue_free()
	
	# Note: Children are freed immediately in Godot 4
	
	# Debug features container
	print("Features container: ", features_container)
	print("Features container visible: ", features_container.visible)
	print("Features container size: ", features_container.size)
	print("Features container position: ", features_container.position)
	
	# Get all features data
	var features = DatabaseManager.get_all_features()
	print("Features data: ", features)
	
	# Create features label
	var features_label = Label.new()
	features_label.text = "SELECT FEATURE"
	features_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	features_label.add_theme_font_size_override("font_size", 16)
	features_container.add_child(features_label)
	
	# Add some spacing
	var features_spacer = Control.new()
	features_spacer.custom_minimum_size = Vector2(0, 20)
	features_container.add_child(features_spacer)
	
	# Create features carousel
	print("Creating features carousel with %d features" % features.size())
	var carousel_container = features_carousel.create_carousel(features, "name", "description", features_container)
	print("Features carousel container created: ", carousel_container)
	print("Features container children count: ", features_container.get_child_count())
	
	# Use call_deferred to ensure the carousel is fully created before connecting signals
	print("DEBUG: Scheduling features carousel signal connection...")
	call_deferred("_connect_features_carousel_signals")
	
	# Initial features selection will be set after signals are connected
	
	# Add some spacing after the features carousel
	var features_bottom_spacer = Control.new()
	features_bottom_spacer.custom_minimum_size = Vector2(0, 20)
	features_container.add_child(features_bottom_spacer)

func _on_background_selected(background_name: String):
	"""Handle background selection"""
	if background_manager.select_background(background_name):
		# Get background data for the selected background
		var background_data = DatabaseManager.get_all_backgrounds()
		var selected_background = null
		for bg in background_data:
			if bg.name == background_name:
				selected_background = bg
				break
		
		if selected_background:
			# Store background data for abilities display
			CharacterCreation.current_background_data = selected_background
			
			# Update abilities display to show background bonuses
			print("Updating abilities display for background: " + background_name)
			update_abilities_display()
			
			# Update background carousel display
			update_background_carousel_display()
			
			# Update the UI to reflect changes
			update_ui()
			
			print("Background selected: " + background_name)
			print("Background bonuses applied: ", selected_background.ability_bonuses_dict)
			print("Background data structure: ", selected_background.keys())
		else:
			print("Warning: Could not find background data for: " + background_name)
	else:
		print("Warning: Could not select background: " + background_name)

func update_background_carousel_display():
	"""Update the background carousel display to show current selection"""
	if background_carousel and background_carousel.has_items():
		var current_background = background_carousel.get_current_item()
		if current_background.has("name"):
			# Update the carousel display
			background_carousel.update_display()
			print("Background carousel display updated")
	else:
		print("Background carousel not available for update")

func _on_feature_selected(feature_name: String):
	"""Handle feature selection"""
	print("DEBUG: _on_feature_selected called with feature: ", feature_name)
	
	# Check if this is a different feature than the currently selected one
	var currently_selected = features_manager.get_selected_feature() if features_manager else ""
	if currently_selected != "" and currently_selected != feature_name:
		print("DEBUG: Changing from feature '%s' to '%s', clearing previous bonuses" % [currently_selected, feature_name])
		# Clear previous feature bonuses before selecting new one
		attribute_manager.clear_feature_bonuses()
	
	if features_manager.select_feature(feature_name):
		print("DEBUG: Feature selection successful")
		# Get feature data for the selected feature
		var features = DatabaseManager.get_all_features()
		var selected_feature = null
		for feature in features:
			if feature.name == feature_name:
				selected_feature = feature
				break
		
		if selected_feature:
			# Store feature data for abilities display
			CharacterCreation.current_feature_data = selected_feature
			
			# Apply new feature attribute bonuses
			if selected_feature.has("attribute_bonuses_dict"):
				var attr_bonuses = selected_feature.attribute_bonuses_dict
				print("DEBUG: Applying feature attribute bonuses: ", attr_bonuses)
				for attr_name in attr_bonuses:
					var bonus_value = attr_bonuses[attr_name]
					# Find the attribute (case-insensitive)
					for attr in attribute_manager.get_all_item_values():
						if attr.to_lower() == attr_name.to_lower():
							# Apply the bonus (features don't consume allocation points)
							var current_value = attribute_manager.get_item_value(attr)
							attribute_manager.character_items[attr] = current_value + bonus_value
							print("DEBUG: Applied %s bonus to %s: %d + %d = %d" % [feature_name, attr, current_value, bonus_value, attribute_manager.character_items[attr]])
							break
			
			# Update abilities display to show feature bonuses
			print("Updating abilities display for feature: " + feature_name)
			update_abilities_display()
			
			# Update features carousel display
			update_features_carousel_display()
			
			# Update trait display to show feature traits
			var selected_race = race_manager.get_selected_race() if race_manager else ""
			if selected_race != "":
				print("Updating trait display for feature: " + feature_name)
				update_trait_display(selected_race)
			
			# Update the UI to reflect changes
			update_ui()
			
			print("Feature selected: " + feature_name)
			print("Feature bonuses applied: ", selected_feature.attribute_bonuses_dict)
			print("Feature data structure: ", selected_feature.keys())
		else:
			print("Warning: Could not find feature data for: " + feature_name)
	else:
		print("Warning: Could not select feature: " + feature_name)
	
	print("DEBUG: _on_feature_selected completed")



func update_features_carousel_display():
	"""Update the features carousel display to show current selection"""
	if features_carousel and features_carousel.has_items():
		var current_feature = features_carousel.get_current_item()
		if current_feature.has("name"):
			# Update the carousel display
			features_carousel.update_display()
			print("Features carousel display updated")
	else:
		print("Features carousel not available for update")

func _on_race_selected(race_name: String):
	print("DEBUG: _on_race_selected called with race: ", race_name)
	print("DEBUG: Calling race_manager.select_race('%s')" % race_name)
	if race_manager.select_race(race_name):
		print("DEBUG: Race selection successful")
		# Get trait data for the selected race
		var trait_data = TraitManager.get_race_trait(race_name)
		print("DEBUG: Got trait data: ", trait_data)
		
		# Get race data for attribute bonuses
		var races = DatabaseManager.get_all_races()
		var selected_race = null
		for race in races:
			if race.name == race_name:
				selected_race = race
				break
		
		# Reset attributes to base values first (to clear previous race bonuses)
		attribute_manager.reset_items()
		attribute_manager.clear_race_bonuses()
		
		# Apply trait bonuses to fresh attribute allocations
		var current_attributes = attribute_manager.get_all_item_values()
		var current_abilities = {}  # Will be handled by AbilitiesDisplay
		
		var modified_data = TraitManager.apply_trait_bonuses(trait_data, current_attributes, current_abilities, {})
		
		# Extract race attribute bonuses (from race data)
		var race_bonuses = {}
		if selected_race and selected_race.has("race_attribute_bonuses_dict"):
			for attr_name in selected_race.race_attribute_bonuses_dict:
				var bonus_value = selected_race.race_attribute_bonuses_dict[attr_name]
				# Ensure bonus value is an integer
				bonus_value = int(bonus_value)
				# Find the attribute (case-insensitive)
				for attr in current_attributes:
					if attr.to_lower() == attr_name.to_lower():
						race_bonuses[attr] = bonus_value
						break
		
		# Set race bonuses in the allocation manager
		attribute_manager.set_race_bonuses(race_bonuses)
		
		# Apply attribute bonuses to the allocation manager
		for attr_name in modified_data.attributes:
			var base_value = attribute_manager.get_item_base_value(attr_name)
			var target_value = modified_data.attributes[attr_name]
			var current_value = attribute_manager.get_item_value(attr_name)
			
			# Set the value directly (race bonuses don't consume allocation points)
			# Ensure the value is stored as an integer
			attribute_manager.character_items[attr_name] = int(target_value)
		
		# Update the remaining points calculation
		attribute_manager.update_remaining_points()
		
		# Store trait data for step 2
		CharacterCreation.current_trait_data = trait_data
		
		# Reapply feature bonuses if a feature is selected (since race changed)
		var selected_feature = features_manager.get_selected_feature() if features_manager else ""
		if selected_feature != "":
			print("DEBUG: Reapplying feature bonuses after race change: ", selected_feature)
			# Get feature data and reapply bonuses
			var features = DatabaseManager.get_all_features()
			for feature in features:
				if feature.name == selected_feature and feature.has("attribute_bonuses_dict"):
					var attr_bonuses = feature.attribute_bonuses_dict
					print("DEBUG: Reapplying feature attribute bonuses: ", attr_bonuses)
					for attr_name in attr_bonuses:
						var bonus_value = attr_bonuses[attr_name]
						# Find the attribute (case-insensitive)
						for attr in attribute_manager.get_all_item_values():
							if attr.to_lower() == attr_name.to_lower():
								# Apply the bonus (features don't consume allocation points)
								var current_value = attribute_manager.get_item_value(attr)
								attribute_manager.character_items[attr] = current_value + bonus_value
								print("DEBUG: Reapplied %s bonus to %s: %d + %d = %d" % [selected_feature, attr, current_value, bonus_value, attribute_manager.character_items[attr]])
								break
		
		print("DEBUG: Calling update_trait_display for race: ", race_name)
		update_trait_display(race_name)
		update_avatar_display()  # Update avatar when race changes
		update_race_carousel_display()
		update_ui()
		print("DEBUG: _on_race_selected completed")

func _on_character_name_changed(_new_text: String):
	# Update the continue button state when the character name changes
	update_ui()



func get_character_name() -> String:
	return character_name_input.text.strip_edges()

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

func load_trait_icons():
	"""Load all available trait icons"""
	print("Loading trait icons...")
	
	# Load all icon files from the traits directory
	var dir = DirAccess.open("res://assets/icons/traits/")
	if dir:
		trait_icons = {}
		
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".png") and not file_name.ends_with(".import"):
				var icon_path = "res://assets/icons/traits/" + file_name
				var texture = load(icon_path)
				if texture:
					# Store using the filename without extension as the key
					var key = file_name.replace(".png", "")
					trait_icons[key] = texture
					print("Loaded trait icon: ", key, " - Size: ", texture.get_size(), " - Valid: ", texture != null)
				else:
					print("Warning: Failed to load trait icon: ", icon_path)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("Error: Could not open traits directory")
	
	print("Trait icon loading complete. Loaded %d icons" % trait_icons.size())
	print("DEBUG: Available trait icon keys: ", trait_icons.keys())

func _on_male_button_pressed():
	"""Handle male button selection"""
	selected_sex = "male"
	update_sex_buttons()
	update_ui()

func _on_female_button_pressed():
	"""Handle female button selection"""
	selected_sex = "female"
	update_sex_buttons()
	update_ui()

func update_sex_buttons():
	"""Update sex button visual states"""
	if selected_sex == "male":
		male_button.modulate = Color(1.2, 1.2, 0.8)  # Highlight selected
		female_button.modulate = Color.WHITE
	elif selected_sex == "female":
		female_button.modulate = Color(1.2, 1.2, 0.8)  # Highlight selected
		male_button.modulate = Color.WHITE
	else:
		male_button.modulate = Color.WHITE
		female_button.modulate = Color.WHITE

func update_avatar_display():
	"""Update the avatar display based on selected avatar"""
	print("update_avatar_display() called with selected_avatar: ", selected_avatar)
	var avatar_area = get_node_or_null("CenterContainer/VBoxContainer/ContentContainer/Column2/PortraitAvatarContainer/AvatarSubColumn/AvatarContainer/AvatarPanel/AvatarArea")
	print("Avatar area found: ", avatar_area != null)
	if avatar_area:
		print("Avatar area text before: ", avatar_area.text)
		if selected_avatar != "" and avatar_textures.has(selected_avatar):
			# Create a texture button to display the avatar
			var avatar_texture = avatar_textures[selected_avatar]
			print("Setting avatar texture: ", avatar_texture)
			avatar_area.icon = avatar_texture
			avatar_area.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			avatar_area.expand_icon = true
			avatar_area.text = ""
			print("Avatar updated: ", selected_avatar)
		else:
			avatar_area.icon = null
			avatar_area.text = "Click to select\nAvatar"
			print("Avatar not found for: ", selected_avatar)
	else:
		print("ERROR: Avatar area not found!")
		print("Available nodes in AvatarContainer:")
		var avatar_container = get_node_or_null("CenterContainer/VBoxContainer/ContentContainer/Column2/PortraitAvatarContainer/AvatarSubColumn/AvatarContainer")
		if avatar_container:
			for i in range(avatar_container.get_child_count()):
				var child = avatar_container.get_child(i)
				print("  Child ", i, ": ", child.name, " (", child.get_class(), ")")
		else:
			print("  AvatarContainer not found either!")

func update_portrait_display():
	"""Update the portrait display based on selected portrait"""
	print("update_portrait_display() called with selected_portrait: ", selected_portrait)
	var portrait_area = get_node_or_null("CenterContainer/VBoxContainer/ContentContainer/Column2/PortraitAvatarContainer/PortraitSubColumn/PortraitContainer/PortraitPanel/PortraitArea")
	print("Portrait area found: ", portrait_area != null)
	if portrait_area:
		print("Portrait area text before: ", portrait_area.text)
		if selected_portrait != "" and portrait_textures.has(selected_portrait):
			# Create a texture button to display the portrait
			var portrait_texture = portrait_textures[selected_portrait]
			print("Setting portrait texture: ", portrait_texture)
			portrait_area.icon = portrait_texture
			portrait_area.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			portrait_area.expand_icon = true
			portrait_area.text = ""
			print("Portrait updated: ", selected_portrait)
		else:
			portrait_area.icon = null
			portrait_area.text = "Click to select\nPortrait"
			print("Portrait not found for: ", selected_portrait)
	else:
		print("ERROR: Portrait area not found!")
		print("Available nodes in PortraitContainer:")
		var portrait_container = get_node_or_null("CenterContainer/VBoxContainer/ContentContainer/Column2/PortraitAvatarContainer/PortraitSubColumn/PortraitContainer")
		if portrait_container:
			for i in range(portrait_container.get_child_count()):
				var child = portrait_container.get_child(i)
				print("  Child ", i, ": ", child.name, " (", child.get_class(), ")")
		else:
			print("  PortraitContainer not found either!")

func get_selected_sex() -> String:
	return selected_sex

func get_selected_portrait() -> String:
	return selected_portrait

func get_selected_avatar() -> String:
	return selected_avatar

func set_selected_portrait(portrait: String):
	"""Set the selected portrait"""
	selected_portrait = portrait
	update_ui()

func set_selected_avatar(avatar: String):
	"""Set the selected avatar"""
	selected_avatar = avatar
	update_avatar_display()
	update_ui()

func _on_portrait_area_clicked():
	"""Handle portrait area click - open portrait selection modal"""
	print("Portrait area clicked!")
	show_portrait_selection_modal()

func _on_avatar_area_clicked():
	"""Handle avatar area click - open avatar selection modal"""
	print("Avatar area clicked!")
	show_avatar_selection_modal()

func show_portrait_selection_modal():
	"""Show portrait selection modal dialog"""
	print("Creating portrait selection modal...")
	var modal = create_selection_modal("Select Portrait", portrait_textures, selected_portrait, _on_portrait_selected_from_modal)
	add_child(modal)
	print("Portrait modal added to scene")

func show_avatar_selection_modal():
	"""Show avatar selection modal dialog"""
	print("Creating avatar selection modal...")
	var modal = create_selection_modal("Select Avatar", avatar_textures, selected_avatar, _on_avatar_selected_from_modal)
	add_child(modal)
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
	
	# Add "None" option for portraits
	if title == "Select Portrait":
		var none_container = VBoxContainer.new()
		
		var none_button = TextureButton.new()
		none_button.custom_minimum_size = Vector2(50, 50)
		none_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		none_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		none_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
		
		# Highlight current selection
		# if current_selection == "":
		# 	none_button.modulate = Color(1.2, 1.2, 0.8)
		# else:
		# 	none_button.modulate = Color.WHITE
		
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
		
		# Ensure default modulate is white for proper texture display
		# texture_rect.modulate = Color.WHITE
		
		# Highlight current selection
		# if texture_key == current_selection:
		# 	texture_rect.modulate = Color(1.2, 1.2, 0.8)
		
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
	selected_portrait = portrait_key
	print("Selected portrait from modal: ", selected_portrait)
	update_portrait_display()
	update_ui()
	
	# Close modal
	var modal = get_node_or_null("SelectionModal")
	if modal:
		modal.queue_free()

func _on_avatar_selected_from_modal(avatar_key: String):
	"""Handle avatar selection from modal"""
	selected_avatar = avatar_key
	print("Selected avatar from modal: ", selected_avatar)
	update_avatar_display()
	update_ui()
	
	# Close modal
	var modal = get_node_or_null("SelectionModal")
	if modal:
		modal.queue_free()

func update_trait_display(race_name: String):
	print("DEBUG: update_trait_display called for race: ", race_name)
	var all_traits = []
	
	if race_data.has(race_name):
		var race = race_data[race_name]
		print("DEBUG: Race data found: ", race)
		
		# Get trait data using TraitManager
		var trait_data = TraitManager.get_race_trait(race_name)
		print("DEBUG: Trait data from TraitManager: ", trait_data)
		
		# Get traits for this race
		var race_traits = DatabaseManager.get_race_traits(race_name)
		print("DEBUG: Race traits from database: ", race_traits.size(), " traits found")
		for i in range(race_traits.size()):
			var t = race_traits[i]
			print("DEBUG: Race trait %d: name='%s', icon_name='%s', description='%s'" % [i, t.get("name", "Unknown"), t.get("icon_name", "None"), t.get("description", "None")])
			all_traits.append(t)
	else:
		print("DEBUG: No race data found for: ", race_name)
	
	# Check if selected feature has a trait
	var selected_feature = features_manager.get_selected_feature() if features_manager else ""
	if selected_feature != "":
		var features = DatabaseManager.get_all_features()
		for feature in features:
			if feature.name == selected_feature and feature.has_trait:
				print("DEBUG: Feature '%s' has trait: %s" % [selected_feature, feature.trait_data.name])
				# Add feature trait to the list
				all_traits.append(feature.trait_data)
	
	print("DEBUG: Total traits to display: ", all_traits.size())
	
	# Clear existing trait icons and create new ones
	print("DEBUG: Clearing existing trait icons...")
	_clear_trait_icons()
	
	# Display trait icons instead of descriptions
	if all_traits.size() > 0:
		print("DEBUG: Creating trait icons...")
		_create_trait_icons(all_traits)
	else:
		print("DEBUG: No traits to create icons for")
		pass

func _clear_trait_icons():
	"""Clear existing trait icons from the description label area"""
	# Find and remove any existing trait icon containers
	var trait_info = get_node_or_null("CenterContainer/VBoxContainer/ContentContainer/Column2/TraitsSection/TraitsContainer/TraitPanel/TraitContent/TraitMargin/TraitInfo")
	if trait_info:
		print("DEBUG: Clearing trait icons from container with %d children" % trait_info.get_child_count())
		# Remove any existing icon containers and spacers
		var children_to_remove = []
		for i in range(trait_info.get_child_count()):
			var child = trait_info.get_child(i)
			if child.name.begins_with("TraitIcon") or child.name == "TraitIconContainer" or child.name.begins_with("Spacer") or child.name == "SpacerBeforeIcons":
				children_to_remove.append(child)
				print("DEBUG: Marking child for removal: %s" % child.name)
		
		print("DEBUG: Removing %d children" % children_to_remove.size())
		for child in children_to_remove:
			trait_info.remove_child(child)
			child.queue_free()
		
		print("DEBUG: After clearing, container has %d children" % trait_info.get_child_count())
	else:
		print("DEBUG: Trait info container not found for clearing")

func _create_trait_icons(traits: Array):
	"""Create and display trait icons with tooltips and frames"""
	print("DEBUG: _create_trait_icons called with %d traits" % traits.size())
	var trait_info = get_node_or_null("CenterContainer/VBoxContainer/ContentContainer/Column2/TraitsSection/TraitsContainer/TraitPanel/TraitContent/TraitMargin/TraitInfo")
	if not trait_info:
		print("Warning: Trait info container not found")
		print("DEBUG: Full path attempted: CenterContainer/VBoxContainer/ContentContainer/Column2/TraitsSection/TraitsContainer/TraitPanel/TraitContent/TraitMargin/TraitInfo")
		return
	else:
		print("DEBUG: Trait info container found successfully")
	
	# Load the trait frame texture
	var frame_texture = load("res://assets/ui/frame_trait.svg")
	if not frame_texture:
		print("Warning: Could not load trait frame texture")
		return
	
	# Create a horizontal container for the icons
	var icon_container = HBoxContainer.new()
	icon_container.name = "TraitIconContainer"
	icon_container.custom_minimum_size = Vector2(0, 140)  # Increased height for 130x130 framed icons
	icon_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Add some spacing before the icons
	var spacer = Control.new()
	spacer.name = "SpacerBeforeIcons"
	spacer.custom_minimum_size = Vector2(0, 10)
	trait_info.add_child(spacer)
	
	# Add the icon container
	trait_info.add_child(icon_container)
	
	# Create an icon for each trait
	for i in range(traits.size()):
		var trait_item = traits[i]
		var icon_name = trait_item.get("icon_name", "")
		print("DEBUG: Processing trait %d: '%s' with icon_name: '%s'" % [i, trait_item.get("name", "Unknown"), icon_name])
		
		if icon_name != "" and trait_icons.has(icon_name):
			print("DEBUG: Creating icon for trait '%s' with icon '%s'" % [trait_item.get("name", "Unknown"), icon_name])
			
			# Create a framed trait icon using the utility function
			var framed_icon_container = create_framed_trait_icon(trait_icons[icon_name], frame_texture)
			if framed_icon_container:
				# Set the name for this specific trait icon
				framed_icon_container.name = "TraitIcon" + str(i)
				
				# Create tooltip with trait description
				var tooltip_text = trait_item.get("description", "No description available")
				# Find the icon texture child to add tooltip
				var icon_texture = framed_icon_container.get_node_or_null("TraitIconTexture")
				if icon_texture:
					icon_texture.tooltip_text = tooltip_text
				
				# Add the framed icon container to the icon container
				icon_container.add_child(framed_icon_container)
				print("DEBUG: Successfully added framed icon for trait '%s'" % trait_item.get("name", "Unknown"))
			else:
				print("Warning: Failed to create framed icon for trait: ", trait_item.get("name", "Unknown"))
			
			# Add some spacing between icons
			if i < traits.size() - 1:
				var icon_spacer = Control.new()
				icon_spacer.custom_minimum_size = Vector2(15, 0)  # Increased spacing for larger icons
				icon_container.add_child(icon_spacer)
		else:
			print("Warning: No icon found for trait: ", trait_item.get("name", "Unknown"), " (icon_name: ", icon_name, ")")
			print("DEBUG: Available trait icon keys: ", trait_icons.keys())
			print("DEBUG: trait_icons.has('%s'): %s" % [icon_name, trait_icons.has(icon_name)])

func format_other_bonuses(json_string: String) -> String:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing other_bonuses JSON: " + json_string)
		return ""
	
	var bonuses_array = json.data
	if not bonuses_array is Array:
		print("other_bonuses is not an array: " + json_string)
		return ""
	
	var formatted_bonuses = []
	
	for bonus in bonuses_array:
		if not bonus is Dictionary:
			continue
		
		var bonus_type = bonus.get("type", "")
		var bonus_value = bonus.get("value", 0)
		var bonus_subtype = bonus.get("subtype", "")
		
		var formatted_bonus = format_single_bonus(bonus_type, bonus_value, bonus_subtype)
		if formatted_bonus != "":
			formatted_bonuses.append(formatted_bonus)
	
	return ", ".join(formatted_bonuses)

func format_json_bonuses(json_string: String, category_name: String) -> String:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing " + category_name.to_lower() + "_bonuses JSON: " + json_string)
		return ""
	
	var bonuses_array = json.data
	if not bonuses_array is Array:
		print(category_name.to_lower() + "_bonuses is not an array: " + json_string)
		return ""
	
	if bonuses_array.size() == 0:
		return ""
	
	var formatted_bonuses = []
	
	for bonus in bonuses_array:
		if not bonus is Dictionary:
			continue
		
		var bonus_name = bonus.get("name", "")
		var bonus_value = bonus.get("value", 0)
		
		if bonus_name != "" and bonus_value != 0:
			var formatted_bonus = str(int(bonus_value))
			formatted_bonus += " " + bonus_name.replace("_", " ").capitalize()
			formatted_bonuses.append(formatted_bonus)
	
	if formatted_bonuses.size() > 0:
		return category_name + ": " + ", ".join(formatted_bonuses)
	else:
		return ""

func format_single_bonus(bonus_type: String, value: int, subtype: String = "") -> String:
	var formatted_type = get_bonus_display_name(bonus_type)
	var is_percentage = is_percentage_bonus(bonus_type)
	
	var result = "+"
	result += str(value)
	if is_percentage:
		result += "%"
	result += " " + formatted_type
	
	if subtype != "":
		result += " (" + subtype.capitalize() + ")"
	
	return result

func get_bonus_display_name(bonus_type: String) -> String:
	match bonus_type:
		"damage":
			return "Damage"
		"critical_chance":
			return "Critical Chance"
		"critical_multiplier":
			return "Critical Multiplier"
		"accuracy":
			return "Accuracy"
		"dodge":
			return "Dodge"
		"endurance":
			return "Endurance"
		"block":
			return "Block"
		"willpower":
			return "Willpower"
		"pv":
			return "PV"
		"mana":
			return "Mana"
		"resistance":
			return "Resistance"
		_:
			return bonus_type.capitalize()

func is_percentage_bonus(bonus_type: String) -> bool:
	# Percentage bonuses based on the combat stats specification
	match bonus_type:
		"damage", "critical_chance", "critical_multiplier", "resistance":
			return true
		"accuracy", "dodge", "endurance", "block", "willpower", "pv", "mana":
			return false
		_:
			return false

func update_ui():
	print("DEBUG: update_ui called")
	# Update points label with color feedback
	var remaining_points = attribute_manager.get_remaining_points()
	points_label.text = "Points Remaining: " + str(remaining_points)
	
	# Apply color feedback using UIManager
	UIManager.apply_color_feedback(points_label, remaining_points)
	
	# Update the attributes display area if it exists
	update_attributes_display()
	
	# Update race carousel display (only if it exists)
	if race_carousel:
		update_race_carousel_display()
	
	# Update background carousel display (only if it exists)
	if background_carousel:
		update_background_carousel_display()
	
	# Update features carousel display (only if it exists)
	if features_carousel:
		update_features_carousel_display()
	
	# Update trait display based on selected race
	print("DEBUG: Calling race_manager.get_selected_race()...")
	var selected_race = race_manager.get_selected_race()
	print("DEBUG: Selected race in update_ui: '%s'" % selected_race)
	if selected_race != "":
		print("DEBUG: Calling update_trait_display from update_ui...")
		update_trait_display(selected_race)
	else:
		print("DEBUG: No race selected, resetting trait display")
		# Reset trait display if no race selected
		_clear_trait_icons()
	
	# Update continue button state using UIManager
	var character_name = character_name_input.text.strip_edges()
	
	# Abilities are now automatically set by traits, no need to check if points are spent
	print("DEBUG: Checking if can continue...")
	var attributes_spent = attribute_manager.all_points_spent()
	var race_selected = race_manager.all_points_spent()
	var background_selected = background_manager.all_points_spent()
	var features_selected = features_manager.all_points_spent()
	var has_name = character_name.length() > 0
	var has_sex = selected_sex != ""
	var has_portrait = selected_portrait != ""
	var has_avatar = selected_avatar != ""
	
	print("DEBUG: Continue conditions: attributes_spent=%s, race_selected=%s, background_selected=%s, features_selected=%s, has_name=%s, has_sex=%s, has_portrait=%s, has_avatar=%s" % [attributes_spent, race_selected, background_selected, features_selected, has_name, has_sex, has_portrait, has_avatar])
	
	var can_continue = attributes_spent and race_selected and background_selected and features_selected and has_name and has_sex and has_portrait and has_avatar
	UIManager.apply_button_state(continue_button, can_continue)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_continue_button_pressed():
	print("DEBUG: Continue button pressed")
	# Check if all points have been spent and race selected
	var attributes_spent = attribute_manager.all_points_spent()
	print("DEBUG: Attributes spent: %s" % attributes_spent)
	if not attributes_spent:
		print("Cannot continue: You must spend all %d attribute points before proceeding!" % attribute_manager.get_remaining_points())
		UIManager.flash_error_feedback(points_label)
		return
	
	# Abilities are automatically set by traits, no need to validate ability points
	
	var race_selected = race_manager.all_points_spent()
	print("DEBUG: Race selected: %s" % race_selected)
	if not race_selected:
		print("Cannot continue: You must select a race before proceeding!")
		return
	
	var background_selected = background_manager.all_points_spent()
	print("DEBUG: Background selected: %s" % background_selected)
	if not background_selected:
		print("Cannot continue: You must select a background before proceeding!")
		return
	
	var features_selected = features_manager.all_points_spent()
	print("DEBUG: Features selected: %s" % features_selected)
	if not features_selected:
		print("Cannot continue: You must select a feature before proceeding!")
		return
	
	# Check if character name is provided
	var character_name = get_character_name()
	if character_name.length() == 0:
		print("Cannot continue: You must enter a character name!")
		character_name_input.modulate = Color.RED
		var tween = character_name_input.create_tween()
		tween.tween_property(character_name_input, "modulate", Color.WHITE, 0.5)
		return
	
	# Store step 1 data in global CharacterCreation
	var selected_race = race_manager.get_selected_race()
	var selected_background = background_manager.get_selected_background() if background_manager else ""
	var selected_feature = features_manager.get_selected_feature() if features_manager else ""
	print("DEBUG: Storing step 1 data - race: '%s', background: '%s', feature: '%s'" % [selected_race, selected_background, selected_feature])
	
	CharacterCreation.set_step1_data(
		character_name,
		selected_race,
		selected_background,
		selected_feature,
		selected_sex,
		selected_portrait,
		selected_avatar,
		attribute_manager.get_character_items()
	)
	
	# Store abilities data from the abilities display (abilities are automatically set by traits)
	if abilities_area_node and abilities_area_node.has_meta("abilities_manager"):
		var abilities_manager = abilities_area_node.get_meta("abilities_manager")
		CharacterCreation.set_step2_data(abilities_manager.get_character_items())
	else:
		print("Warning: Could not find abilities manager")
		CharacterCreation.set_step2_data({})
	
	# Print character stats
	attribute_manager.print_character_stats()
	print("Selected Race: %s" % selected_race)
	print("Selected Background: %s" % selected_background)
	print("Selected Feature: %s" % selected_feature)
	print("Character Name: %s" % character_name)
	
	# Navigate to step 2 (abilities & competences allocation)
	get_tree().change_scene_to_file("res://scenes/character_creation/character_creation_step2.tscn")

func update_abilities_display():
	"""Update the abilities display with current character data"""
	if abilities_area_node and abilities_display:
		# Remove the old abilities area
		var column1 = $CenterContainer/VBoxContainer/ContentContainer/Column1
		column1.remove_child(abilities_area_node)
		abilities_area_node.queue_free()
		
		# Create a new character object with current data
		var character = Character.new()
		character.name = character_name_input.text if character_name_input else ""
		var selected_race = race_manager.get_selected_race() if race_manager else ""
		var selected_background = background_manager.get_selected_background() if background_manager else ""
		var selected_feature = features_manager.get_selected_feature() if features_manager else ""
		character.race_name = selected_race
		character.background_name = selected_background
		character.feature_name = selected_feature
		character.sex = selected_sex
		character.portrait = selected_portrait
		character.avatar = selected_avatar
		character.attributes = attribute_manager.get_character_items()
		
		# Create new abilities area with updated character data
		abilities_area_node = abilities_display.create_abilities_area(character)
		column1.add_child(abilities_area_node)
		print("Abilities display updated with current character data")
		print("Character background: ", character.background_name)
		print("Character feature: ", character.feature_name)
		print("Character race: ", character.race_name)
		print("DEBUG: race_manager.get_selected_race() returned: '%s'" % selected_race)

# Utility function for creating framed trait icons that can be used elsewhere
static func create_framed_trait_icon(trait_icon_texture: Texture2D, frame_texture: Texture2D = null, icon_size: Vector2 = Vector2(100, 100), frame_size: Vector2 = Vector2(150, 150)) -> Control:
	"""
	Create a framed trait icon that can be used anywhere in the UI
	
	Parameters:
	- trait_icon_texture: The trait icon texture to display
	- frame_texture: The frame texture (if null, will load from assets/ui/frame_trait.svg)
	- icon_size: Size of the trait icon (default: 100x100)
	- frame_size: Size of the frame (default: 140x140)
	
	Returns:
	- A Control node containing the framed icon
	"""
	# Load frame texture if not provided
	if not frame_texture:
		frame_texture = load("res://assets/ui/frame_trait.svg")
		if not frame_texture:
			print("Warning: Could not load trait frame texture")
			return null
	
	# Create a container for the framed icon
	var framed_icon_container = Control.new()
	framed_icon_container.custom_minimum_size = frame_size
	framed_icon_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	framed_icon_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Create the frame background (larger, behind the icon)
	var frame_background = TextureRect.new()
	frame_background.name = "FrameBackground"
	frame_background.texture = frame_texture
	frame_background.custom_minimum_size = frame_size
	frame_background.size_flags_horizontal = Control.SIZE_FILL
	frame_background.size_flags_vertical = Control.SIZE_FILL
	frame_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame_background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	
	# Create the trait icon (smaller, centered on top of frame)
	var icon_texture = TextureRect.new()
	icon_texture.name = "TraitIconTexture"
	icon_texture.texture = trait_icon_texture
	icon_texture.custom_minimum_size = icon_size
	icon_texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_texture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	
	# Calculate position to center the icon within the frame
	var icon_offset = (frame_size - icon_size) / 2
	icon_texture.position = icon_offset
	
	# Add frame first (background), then icon on top
	framed_icon_container.add_child(frame_background)
	framed_icon_container.add_child(icon_texture)
	
	return framed_icon_container
