extends Control

# Manager instances
var attribute_manager: AllocationManager
var race_manager: AllocationManager
var background_manager: AllocationManager
var features_manager: AllocationManager
var personality_manager: AllocationManager
var attributes_display: AttributesDisplay
var abilities_display: AbilitiesDisplay

# UI node references
@onready var character_name_input = $VBoxContainer/CharacterNameInput
# Avatar display is now handled by the AvatarDisplay scene

@onready var race_container = $Carousels/RaceContainer
@onready var background_container = $Carousels/BackgroundContainer
@onready var features_container = $Carousels/FeaturesContainer
@onready var personality_container = $Carousels/PersonalityContainer

# Carousel references (from scene)
@onready var race_carousel = $Carousels/RaceContainer/RaceCarousel
@onready var background_carousel = $Carousels/BackgroundContainer/BackgroundCarousel
@onready var features_carousel = $Carousels/FeaturesContainer/FeaturesCarousel
@onready var personality_carousel = $Carousels/PersonalityContainer/PersonalityCarousel

@onready var attributes_display_node = $AttributesDisplay
@onready var abilities_display_node = $AbilitiesDisplay
@onready var portrait_display_node = $PortraitDisplay
@onready var avatar_display_node = $AvatarDisplay

# Store the attributes area for reuse
var attributes_area_node: Control
# Store the abilities area for reuse
var abilities_area_node: Control

# Store race data with trait information
var race_data = {}
# Store selected sex
var selected_sex = ""
# Portrait and avatar displays will handle their own state
# Store trait icons
var trait_icons = {}

func _ready():
	
	# Wait a bit to ensure DatabaseManager is fully initialized
	# Note: In Godot 4, DatabaseManager should be ready immediately
	
	# Initialize the managers
	print("DEBUG: Initializing managers...")
	attribute_manager = AllocationManager.new("attributes", "attributes", 5)
	race_manager = AllocationManager.new("races", "races", 0)  # Races don't use points
	background_manager = AllocationManager.new("backgrounds", "backgrounds", 0)  # Backgrounds don't use points
	features_manager = AllocationManager.new("features", "features", 0)  # Features don't use points
	personality_manager = AllocationManager.new("personalities", "personalities", 0)  # Personalities don't use points
	attributes_display = AttributesDisplay.new()
	# AbilitiesDisplay will be loaded from scene file
	print("DEBUG: Managers initialized")
	
	# Setup carousels (they're already in the scene via @onready)
	setup_carousels()
	
	# Setup the portrait and avatar displays
	setup_portrait_avatar_displays()
	
	# Connect character name input signal (with null check)
	if character_name_input:
		character_name_input.text_changed.connect(_on_character_name_changed)
	else:
		print("Warning: Character name input not found")
	
	
	# Connect portrait and avatar display signals
	if portrait_display_node:
		portrait_display_node.portrait_selected.connect(_on_portrait_selected)
	if avatar_display_node:
		avatar_display_node.avatar_selected.connect(_on_avatar_selected)
	
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
	
	# Load selected personality
	if CharacterCreation.selected_personality != "":
		personality_manager.select_personality(CharacterCreation.selected_personality)
		# Note: Personality carousel will be created later in generate_portrait_avatar_ui()
		# Personality selection will be applied after carousel creation
		print("Loaded selected personality: " + CharacterCreation.selected_personality)
	else:
		print("DEBUG: No existing personality selection found")
	
	# Load selected portrait
	if CharacterCreation.selected_portrait != "":
		set_selected_portrait(CharacterCreation.selected_portrait)
		print("Loaded selected portrait: " + CharacterCreation.selected_portrait)
	
	# Load selected avatar
	if CharacterCreation.selected_avatar != "":
		set_selected_avatar(CharacterCreation.selected_avatar)
		print("Loaded selected avatar: " + CharacterCreation.selected_avatar)
	
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

func setup_carousels():
	"""Setup the carousels that are already in the scene"""
	print("DEBUG: Setting up carousels...")
	
	# Setup race carousel
	var races = DatabaseManager.get_all_races()
	print("Setting up race carousel with %d races" % races.size())
	
	# Store race data for trait display
	for race in races:
		race_data[race.name] = race
		print("DEBUG: Stored race data for: ", race.name)
	
	race_carousel.set_items(races, "name", "description")
	race_carousel.selection_changed.connect(_on_race_carousel_changed)
	
	# Setup background carousel
	var backgrounds = DatabaseManager.get_all_backgrounds()
	print("Setting up background carousel with %d backgrounds" % backgrounds.size())
	background_carousel.set_items(backgrounds, "name", "description")
	background_carousel.selection_changed.connect(_on_background_carousel_changed)
	
	# Setup features carousel
	var features = DatabaseManager.get_all_features()
	print("Setting up features carousel with %d features" % features.size())
	features_carousel.set_items(features, "name", "description")
	features_carousel.selection_changed.connect(_on_features_carousel_changed)
	
	# Setup personality carousel
	var personalities = DatabaseManager.get_all_personalities()
	print("Setting up personality carousel with %d personalities" % personalities.size())
	personality_carousel.set_items(personalities, "name", "description")
	personality_carousel.selection_changed.connect(_on_personality_carousel_changed)
	
	print("DEBUG: Carousels setup complete")





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
		var current_race_data = race_carousel.get_current_item()
		_on_race_carousel_changed(race_carousel.get_current_index(), current_race_data)
	else:
		print("Warning: No races available for initial selection")



func setup_portrait_avatar_displays():
	"""Setup the portrait and avatar displays from existing scene nodes"""
	print("DEBUG: setup_portrait_avatar_displays called")
	
	# Portrait and avatar displays are already in the scene, just need to load existing selections
	if portrait_display_node and CharacterCreation.selected_portrait != "":
		portrait_display_node.set_selected_portrait(CharacterCreation.selected_portrait)
	
	if avatar_display_node and CharacterCreation.selected_avatar != "":
		avatar_display_node.set_selected_avatar(CharacterCreation.selected_avatar)
	
	# Use the existing AttributesDisplay node from the scene  
	attributes_area_node = attributes_display_node
	
	# Create a character object to pass to the displays
	var character = Character.new()
	character.name = character_name_input.text if character_name_input else ""
	var selected_race = race_manager.get_selected_race() if race_manager else ""
	var selected_background = background_manager.get_selected_background() if background_manager else ""
	var selected_feature = features_manager.get_selected_feature() if features_manager else ""
	var selected_personality = personality_manager.get_selected_personality() if personality_manager else ""
	character.race_name = selected_race
	character.background_name = selected_background
	character.feature_name = selected_feature
	character.personality_name = selected_personality
	character.sex = selected_sex
	character.portrait = get_selected_portrait()
	character.avatar = get_selected_avatar()
	character.attributes = attribute_manager.get_character_items() if attribute_manager else {}
	
	# Update the existing attributes display with character data (call on the node with the script)
	attributes_display_node.update_attributes_from_character(character)
	print("Connected to existing AttributesDisplay node and updated with character data")
	
	# Use the existing AbilitiesDisplay node from the scene
	abilities_area_node = abilities_display_node
	
	# Initialize the abilities display with character data
	abilities_area_node.update_abilities_from_character(character)
	print("Connected to existing AbilitiesDisplay node and updated with character data")
	print("DEBUG: race_manager.get_selected_race() returned: '%s'" % selected_race)
	
	# Set initial carousel selections (carousels are already set up)
	print("DEBUG: Setting initial carousel selections...")
	call_deferred("_set_initial_race_selection")
	call_deferred("_set_initial_background_selection") 
	call_deferred("_set_initial_features_selection")
	call_deferred("_set_initial_personality_selection")

func get_attributes_area() -> Control:
	"""Get the attributes area node - useful for other parts of the game"""
	return attributes_area_node

func get_abilities_area() -> Control:
	"""Get the abilities area node - useful for other parts of the game"""
	return abilities_area_node

func update_attributes_display():
	"""Update the attributes display with current character data"""
	if attributes_area_node and attribute_manager:
		# Create a character object with current data
		var character = Character.new()
		character.name = character_name_input.text if character_name_input else ""
		var selected_race = race_manager.get_selected_race() if race_manager else ""
		var selected_background = background_manager.get_selected_background() if background_manager else ""
		var selected_feature = features_manager.get_selected_feature() if features_manager else ""
		var selected_personality = personality_manager.get_selected_personality() if personality_manager else ""
		character.race_name = selected_race
		character.background_name = selected_background
		character.feature_name = selected_feature
		character.personality_name = selected_personality
		character.sex = selected_sex
		character.portrait = get_selected_portrait()
		character.avatar = get_selected_avatar()
		character.attributes = attribute_manager.get_character_items()
		
		# Update the existing attributes area with new character data
		attributes_display_node.update_attributes_from_character(character)
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

func _on_race_carousel_changed(item_index: int, item_data: Dictionary):
	"""Handle race selection change in the carousel (new signal pattern)"""
	print("DEBUG: _on_race_carousel_changed called with index: %d" % item_index)
	print("DEBUG: Selected race data: ", item_data)
	
	if item_data and item_data.has("name"):
		var race_name = item_data.name
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
		var current_background_data = background_carousel.get_current_item()
		_on_background_carousel_changed(background_carousel.get_current_index(), current_background_data)
	else:
		print("Warning: No backgrounds available for initial selection")



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
		var current_feature_data = features_carousel.get_current_item()
		_on_features_carousel_changed(features_carousel.get_current_index(), current_feature_data)
	else:
		print("Warning: No features available for initial selection")

func _set_initial_personality_selection():
	"""Set initial personality selection after carousel is ready"""
	print("DEBUG: _set_initial_personality_selection called")
	if not personality_carousel:
		print("Warning: Personality carousel not available for initial selection")
		return
		
	var personalities = DatabaseManager.get_all_personalities()
	print("DEBUG: Found %d personalities in database" % personalities.size())
	if personalities.size() > 0:
		# If we have a previously selected personality, set it in the carousel
		if CharacterCreation.selected_personality != "":
			var personality_index = personality_carousel.find_item_index_by_name(CharacterCreation.selected_personality, "name")
			if personality_index >= 0:
				personality_carousel.set_current_index(personality_index)
				print("Set carousel to previously selected personality: " + CharacterCreation.selected_personality)
		
		# Trigger the personality selection change to update UI
		print("DEBUG: Triggering personality carousel change...")
		var current_personality_data = personality_carousel.get_current_item()
		_on_personality_carousel_changed(personality_carousel.get_current_index(), current_personality_data)
	else:
		print("Warning: No personalities available for initial selection")

func _on_background_carousel_changed(item_index: int, item_data: Dictionary):
	"""Handle background selection change in the carousel (new signal pattern)"""
	print("DEBUG: _on_background_carousel_changed called with index: %d" % item_index)
	print("DEBUG: Selected background data: ", item_data)
	
	if item_data and item_data.has("name"):
		var background_name = item_data.name
		_on_background_selected(background_name)
	else:
		print("Warning: No valid background data in carousel")

func _on_features_carousel_changed(item_index: int, item_data: Dictionary):
	"""Handle features selection change in the carousel (new signal pattern)"""
	print("DEBUG: _on_features_carousel_changed called with index: %d" % item_index)
	print("DEBUG: Selected feature data: ", item_data)
	
	if item_data and item_data.has("name"):
		var feature_name = item_data.name
		print("DEBUG: Calling _on_feature_selected with: ", feature_name)
		_on_feature_selected(feature_name)
	else:
		print("Warning: No valid feature data in carousel")
	
	print("DEBUG: _on_features_carousel_changed completed")

func _on_personality_carousel_changed(item_index: int, item_data: Dictionary):
	"""Handle personality selection change in the carousel (new signal pattern)"""
	print("DEBUG: _on_personality_carousel_changed called with index: %d" % item_index)
	print("DEBUG: Selected personality data: ", item_data)
	
	if item_data and item_data.has("name"):
		var personality_name = item_data.name
		print("DEBUG: Calling _on_personality_selected with: ", personality_name)
		_on_personality_selected(personality_name)
	else:
		print("Warning: No valid personality data in carousel")
	
	print("DEBUG: _on_personality_carousel_changed completed")

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
			
			# Update trait display to show background trait icon
			var selected_race = race_manager.get_selected_race() if race_manager else ""
			if selected_race != "":
				print("Updating trait display for background: " + background_name)
				update_trait_display(selected_race)
			
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

func _on_personality_selected(personality_name: String):
	"""Handle personality selection"""
	print("DEBUG: _on_personality_selected called with personality: ", personality_name)
	
	if personality_manager.select_personality(personality_name):
		print("DEBUG: Personality selection successful")
		# Get personality data for the selected personality
		var personalities = DatabaseManager.get_all_personalities()
		var selected_personality = null
		for personality in personalities:
			if personality.name == personality_name:
				selected_personality = personality
				break
		
		if selected_personality:
			# Store personality data for character creation
			CharacterCreation.current_personality_data = selected_personality
			
			# Update personality carousel display
			update_personality_carousel_display()
			
			# Update the UI to reflect changes
			update_ui()
			
			print("Personality selected: " + personality_name)
			print("Personality data structure: ", selected_personality.keys())
		else:
			print("Warning: Could not find personality data for: " + personality_name)
	else:
		print("Warning: Could not select personality: " + personality_name)
	
	print("DEBUG: _on_personality_selected completed")

func update_personality_carousel_display():
	"""Update the personality carousel display to show current selection"""
	if personality_carousel and personality_carousel.has_items():
		var current_personality = personality_carousel.get_current_item()
		if current_personality.has("name"):
			# Update the carousel display
			personality_carousel.update_display()
			print("Personality carousel display updated")
	else:
		print("Personality carousel not available for update")

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
		# Avatar display will be updated through signals if needed
		update_race_carousel_display()
		update_ui()
		print("DEBUG: _on_race_selected completed")

func _on_character_name_changed(_new_text: String):
	# Update the continue button state when the character name changes
	update_ui()

func _on_portrait_selected(portrait_key: String):
	"""Handle portrait selection from portrait display"""
	print("Portrait selected: ", portrait_key)
	CharacterCreation.selected_portrait = portrait_key
	update_ui()

func _on_avatar_selected(avatar_key: String):
	"""Handle avatar selection from avatar display"""
	print("Avatar selected: ", avatar_key)
	CharacterCreation.selected_avatar = avatar_key
	update_ui()



func get_character_name() -> String:
	return character_name_input.text.strip_edges()

# Texture loading is now handled by the portrait and avatar display classes

func load_trait_icons():
	"""Load all available trait icons"""
	print("Loading trait icons...")
	
	# Load all icon files from the svgs directory
	var dir = DirAccess.open("res://assets/icons/svgs/")
	if dir:
		trait_icons = {}
		
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".svg") and not file_name.ends_with(".import"):
				var icon_path = "res://assets/icons/svgs/" + file_name
				var texture = load(icon_path)
				if texture:
					# Store using the filename without extension as the key
					var key = file_name.replace(".svg", "")
					trait_icons[key] = texture
					print("Loaded trait icon: ", key, " - Size: ", texture.get_size(), " - Valid: ", texture != null)
				else:
					print("Warning: Failed to load trait icon: ", icon_path)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("Error: Could not open svgs directory")
	
	print("Trait icon loading complete. Loaded %d icons" % trait_icons.size())
	print("DEBUG: Available trait icon keys: ", trait_icons.keys())

# Portrait and avatar display is now handled by the respective display classes

func get_selected_sex() -> String:
	return selected_sex

func get_selected_portrait() -> String:
	if portrait_display_node:
		return portrait_display_node.get_selected_portrait()
	return ""

func get_selected_avatar() -> String:
	if avatar_display_node:
		return avatar_display_node.get_selected_avatar()
	return ""

func set_selected_portrait(portrait: String):
	"""Set the selected portrait"""
	if portrait_display_node:
		portrait_display_node.set_selected_portrait(portrait)

func set_selected_avatar(avatar: String):
	"""Set the selected avatar"""
	if avatar_display_node:
		avatar_display_node.set_selected_avatar(avatar)

# Portrait and avatar area clicks are now handled by the respective display classes

# All modal creation and selection handling is now done by the portrait and avatar display classes

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
	
	# Check if selected background has a trait icon (using background name as icon name)
	var selected_background = background_manager.get_selected_background() if background_manager else ""
	if selected_background != "":
		print("DEBUG: Background '%s' selected, adding trait icon" % selected_background)
		# Create a trait data structure for the background icon
		var background_trait_data = {
			"name": selected_background,
			"description": "Background trait",
			"icon_name": selected_background  # Use background name as icon name
		}
		all_traits.append(background_trait_data)
	
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
	var trait_info = get_node_or_null("TraitsSection/TraitsContainer/TraitPanel/TraitContent/TraitMargin/TraitInfo")
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
	var trait_info = get_node_or_null("TraitsSection/TraitsContainer/TraitPanel/TraitContent/TraitMargin/TraitInfo")
	if not trait_info:
		print("Warning: Trait info container not found")
		print("DEBUG: Full path attempted: TraitsSection/TraitsContainer/TraitPanel/TraitContent/TraitMargin/TraitInfo")
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
	
	# Update personality carousel display (only if it exists)
	if personality_carousel:
		update_personality_carousel_display()
	
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
	var personality_selected = personality_manager.all_points_spent()
	var has_name = character_name.length() > 0
	var has_sex = selected_sex != ""
	var has_portrait = get_selected_portrait() != ""
	var has_avatar = get_selected_avatar() != ""
	
	print("DEBUG: Continue conditions: attributes_spent=%s, race_selected=%s, background_selected=%s, features_selected=%s, personality_selected=%s, has_name=%s, has_sex=%s, has_portrait=%s, has_avatar=%s" % [attributes_spent, race_selected, background_selected, features_selected, personality_selected, has_name, has_sex, has_portrait, has_avatar])
	
	var can_continue = attributes_spent and race_selected and background_selected and features_selected and personality_selected and has_name and has_sex and has_portrait and has_avatar

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_continue_button_pressed():
	print("DEBUG: Continue button pressed")
	# Check if all points have been spent and race selected
	var attributes_spent = attribute_manager.all_points_spent()
	print("DEBUG: Attributes spent: %s" % attributes_spent)
	
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
	
	var personality_selected = personality_manager.all_points_spent()
	print("DEBUG: Personality selected: %s" % personality_selected)
	if not personality_selected:
		print("Cannot continue: You must select a personality before proceeding!")
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
	var selected_personality = personality_manager.get_selected_personality() if personality_manager else ""
	print("DEBUG: Storing step 1 data - race: '%s', background: '%s', feature: '%s', personality: '%s'" % [selected_race, selected_background, selected_feature, selected_personality])
	
	CharacterCreation.set_step1_data(
		character_name,
		selected_race,
		selected_background,
		selected_feature,
		selected_personality,
		selected_sex,
		get_selected_portrait(),
		get_selected_avatar(),
		attribute_manager.get_character_items()
	)
	
	# Store abilities data from the abilities display (abilities are automatically set by traits)
	if abilities_area_node:
		var abilities_manager = abilities_area_node.get_abilities_manager()
		if abilities_manager:
			CharacterCreation.set_step2_data(abilities_manager.get_character_items())
		else:
			print("Warning: Could not find abilities manager")
			CharacterCreation.set_step2_data({})
	else:
		print("Warning: Could not find abilities area node")
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
	if abilities_area_node:
		# Create a new character object with current data
		var character = Character.new()
		character.name = character_name_input.text if character_name_input else ""
		var selected_race = race_manager.get_selected_race() if race_manager else ""
		var selected_background = background_manager.get_selected_background() if background_manager else ""
		var selected_feature = features_manager.get_selected_feature() if features_manager else ""
		var selected_personality = personality_manager.get_selected_personality() if personality_manager else ""
		character.race_name = selected_race
		character.background_name = selected_background
		character.feature_name = selected_feature
		character.personality_name = selected_personality
		character.sex = selected_sex
		character.portrait = get_selected_portrait()
		character.avatar = get_selected_avatar()
		character.attributes = attribute_manager.get_character_items()
		
		# Update the existing abilities display with new character data
		abilities_area_node.update_abilities_from_character(character)
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
