extends VBoxContainer
class_name AbilitiesDisplay

## AbilitiesDisplay - Manages the abilities display scene
##
## This scene contains the visual elements including:
## - Title label
## - Expand/collapse button  
## - 8 ability value labels for all abilities
## - Status label
##
## Usage:
##   var abilities_display = preload("res://core/ui/abilities_display.tscn").instantiate()
##   parent_node.add_child(abilities_display)
##   abilities_display.update_abilities_from_character(character)

# The 8 ability names (must match the order in allocation_manager.gd)
var ability_names = ["Survival", "Perception", "Stealth", "Knowledge", "Arcana", "SleightOfHand", "Persuasion", "Athletics"]

# Map ability names to their value label node paths in the scene
var ability_value_paths = {
	"Survival": "AbilitiesContainer/SurvivalRow/SurvivalValue",
	"Perception": "AbilitiesContainer/PerceptionRow/PerceptionValue",
	"Stealth": "AbilitiesContainer/StealthRow/StealthValue",
	"Knowledge": "AbilitiesContainer/KnowledgeRow/KnowledgeValue",
	"Arcana": "AbilitiesContainer/ArcanaRow/ArcanaValue",
	"SleightOfHand": "AbilitiesContainer/SleightOfHandRow/SleightOfHandValue",
	"Persuasion": "AbilitiesContainer/PersuasionRow/PersuasionValue",
	"Athletics": "AbilitiesContainer/AthleticsRow/AthleticsValue"
}

# Store the abilities manager
var abilities_manager: AllocationManager
# Track expanded state
var is_expanded = false

func _ready():
	"""Initialize the abilities display"""
	print("AbilitiesDisplay scene initialized")
	
	# Connect the expand button
	var expand_button = get_node("ExpandButton")
	if expand_button:
		expand_button.pressed.connect(_on_expand_button_pressed)

func initialize_abilities_manager(character: Character):
	"""Initialize the abilities manager and apply bonuses"""
	# Create abilities allocation manager
	abilities_manager = AllocationManager.new("abilities", "abilities", 4)
	print("Created abilities manager with %d abilities" % abilities_manager.get_item_names().size())
	print("Initial ability values: ", abilities_manager.get_all_item_values())
	
	# Apply trait bonuses if character has them
	if character and character.race_name != "":
		var trait_data = TraitManager.get_race_trait(character.race_name)
		if trait_data.size() > 0:
			print("Applying trait bonuses for race: ", character.race_name)
			apply_trait_bonuses(abilities_manager, trait_data)
		else:
			print("No trait data found for race: ", character.race_name)
	else:
		print("No race name in character: ", character.race_name if character else "no character")
	
	# Apply background bonuses if character has them
	print("Checking character for background bonuses:")
	print("  Character exists: ", character != null)
	print("  Background name: ", character.background_name if character else "N/A")
	print("  Background name empty: ", character.background_name == "" if character else "N/A")
	
	if character and character.background_name != "":
		var background_data = DatabaseManager.get_background_by_name(character.background_name)
		if background_data.size() > 0:
			print("Found background data for: ", character.background_name)
			apply_background_bonuses(abilities_manager, background_data)
			print("Background bonuses applied, now checking ability values...")
		else:
			print("No background data found for: ", character.background_name)
	else:
		print("No background name in character: ", character.background_name if character else "no character")
	
	# Update the display
	update_abilities_display()
	update_visibility_based_on_values()

func update_abilities_from_character(character: Character):
	"""Update the abilities display with character data"""
	if not character:
		print("Warning: No character provided to AbilitiesDisplay")
		return
	
	print("AbilitiesDisplay updating with character:")
	print("  Name: ", character.name)
	print("  Race: ", character.race_name)
	print("  Background: ", character.background_name)
	
	# Initialize the abilities manager with character data
	initialize_abilities_manager(character)

func update_abilities_display():
	"""Update the ability values in the display"""
	if not abilities_manager:
		print("Warning: No abilities manager available")
		return
	
	print("AbilitiesDisplay updating values")
	
	# Update each ability value
	for ability_name in ability_names:
		var value_path = ability_value_paths.get(ability_name, "")
		if value_path != "":
			var value_label = get_node_or_null(value_path)
			if value_label:
				var ability_value = abilities_manager.get_item_value(ability_name)
				# Ensure the value is displayed as an integer
				value_label.text = str(int(ability_value))
				
				# Add visual indicator for race bonuses only
				if abilities_manager.race_bonuses.has(ability_name):
					value_label.text += " (race bonus)"
				
				print("  Updated %s: %d" % [ability_name, ability_value])
			else:
				print("Warning: Could not find value label for %s at path: %s" % [ability_name, value_path])
		else:
			print("Warning: No path mapping for ability: %s" % ability_name)

func update_visibility_based_on_values():
	"""Show/hide ability rows based on values (like the original dynamic behavior)"""
	if not abilities_manager:
		return
	
	# If not expanded, only show abilities with > 1 point or that have bonuses
	if not is_expanded:
		for ability_name in ability_names:
			var ability_value = abilities_manager.get_item_value(ability_name)
			var base_value = abilities_manager.get_item_base_value(ability_name)
			var should_show = ability_value > 1 or ability_value > base_value
			
			# Get the row container
			var row_path = "AbilitiesContainer/%sRow" % ability_name.replace(" ", "")
			var row_container = get_node_or_null(row_path)
			if row_container:
				row_container.visible = should_show
				print("  %s row visibility: %s (value=%d, base=%d)" % [ability_name, should_show, ability_value, base_value])
	else:
		# Show all abilities when expanded
		for ability_name in ability_names:
			var row_path = "AbilitiesContainer/%sRow" % ability_name.replace(" ", "")
			var row_container = get_node_or_null(row_path)
			if row_container:
				row_container.visible = true

func apply_trait_bonuses(abilities_manager: AllocationManager, trait_data: Dictionary):
	"""Apply trait bonuses to abilities"""
	print("Applying trait bonuses to abilities...")
	
	var current_abilities = abilities_manager.get_all_item_values()
	var modified_data = TraitManager.apply_trait_bonuses(trait_data, {}, current_abilities, {})
	
	# Extract ability bonuses for race bonus tracking
	var ability_bonuses = {}
	if trait_data.has("competence_bonuses"):  # Note: still using competence_bonuses from trait data
		for bonus in trait_data.competence_bonuses:
			if bonus.name != "free":  # Skip free points, only track specific bonuses
				var abil_name = bonus.name.to_lower()
				# Find the ability (case-insensitive)
				for abil in current_abilities:
					if abil.to_lower() == abil_name:
						ability_bonuses[abil] = bonus.value
						break
	
	# Set ability race bonuses in the allocation manager
	abilities_manager.set_race_bonuses(ability_bonuses)
	
	# Apply ability bonuses
	for ability_name in modified_data.abilities:
		var base_value = abilities_manager.get_item_base_value(ability_name)
		var target_value = modified_data.abilities[ability_name]
		var current_value = abilities_manager.get_item_value(ability_name)
		
		# Adjust points to reach target value
		var points_needed = target_value - current_value
		if points_needed > 0:
			# Add points
			for i in range(points_needed):
				abilities_manager.increase_item(ability_name)
		elif points_needed < 0:
			# Remove points (but don't go below base value)
			for i in range(-points_needed):
				if abilities_manager.get_item_value(ability_name) > base_value:
					abilities_manager.decrease_item(ability_name)
	
	# Add free ability points if any
	if modified_data.free_points.competences > 0:
		abilities_manager.add_free_points(modified_data.free_points.competences)
		print("Added %d free ability points from trait" % modified_data.free_points.competences)
	
	# Update the remaining points calculation
	abilities_manager.update_remaining_points()
	
	print("Trait bonuses applied to abilities successfully")

func apply_background_bonuses(abilities_manager: AllocationManager, background_data: Dictionary):
	"""Apply background bonuses to abilities"""
	print("Applying background bonuses to abilities...")
	print("Background data: ", background_data)
	print("Background ability bonuses: ", background_data.get("ability_bonuses_dict", {}))
	
	var current_abilities = abilities_manager.get_all_item_values()
	print("Current abilities before background bonuses: ", current_abilities)
	
	# Extract ability bonuses from background data
	if background_data.has("ability_bonuses_dict") and background_data.ability_bonuses_dict.size() > 0:
		var ability_bonuses = background_data.ability_bonuses_dict
		
		# Apply each ability bonus
		for ability_name in ability_bonuses:
			var bonus_value = int(ability_bonuses[ability_name])  # Ensure bonus value is an integer
			var current_value = abilities_manager.get_item_value(ability_name)
			print("  Before bonus: %s = %d" % [ability_name, current_value])
			
			# Check if the ability exists in the abilities manager
			var available_abilities = abilities_manager.get_item_names()
			print("  Available abilities: ", available_abilities)
			print("  Looking for ability: '%s'" % ability_name)
			
			# Find the exact ability name (case-insensitive)
			var exact_ability_name = ""
			for available_ability in available_abilities:
				if available_ability.to_lower() == ability_name.to_lower():
					exact_ability_name = available_ability
					break
			
			if exact_ability_name != "":
				print("  Found exact match: '%s'" % exact_ability_name)
				# Add the bonus points using the exact name
				for i in range(bonus_value):
					abilities_manager.increase_item(exact_ability_name)
				
				var new_value = abilities_manager.get_item_value(exact_ability_name)
				print("  After bonus: %s = %d (added +%d)" % [exact_ability_name, new_value, bonus_value])
			else:
				print("  WARNING: Ability '%s' not found in abilities manager!" % ability_name)
	else:
		print("No background ability bonuses found")
	
	var final_abilities = abilities_manager.get_all_item_values()
	print("Final abilities after background bonuses: ", final_abilities)
	print("Background bonuses applied to abilities successfully")

func _on_expand_button_pressed():
	"""Handle expand button press to expand/collapse abilities"""
	is_expanded = !is_expanded
	
	var expand_button = get_node("ExpandButton")
	if expand_button:
		if is_expanded:
			# Show all abilities
			expand_button.text = "Click to show only high abilities"
		else:
			# Show only abilities with > 1 point or bonuses
			expand_button.text = "Click to show all abilities"
	
	# Update visibility
	update_visibility_based_on_values()

func reset_to_defaults():
	"""Reset all ability values to default (0)"""
	for ability_name in ability_names:
		var value_path = ability_value_paths.get(ability_name, "")
		if value_path != "":
			var value_label = get_node_or_null(value_path)
			if value_label:
				value_label.text = "0"
				print("Reset %s to default value: 0" % ability_name)

func update_abilities_from_dict(abilities_dict: Dictionary):
	"""Update ability values directly from a dictionary"""
	print("AbilitiesDisplay updating values from dictionary: ", abilities_dict)
	
	for ability_name in ability_names:
		var value_path = ability_value_paths.get(ability_name, "")
		if value_path != "":
			var value_label = get_node_or_null(value_path)
			if value_label:
				var ability_value = abilities_dict.get(ability_name, 0)
				# Ensure the value is displayed as an integer
				value_label.text = str(int(ability_value))
				print("  Updated %s: %d" % [ability_name, ability_value])

func update_ability_ui(ability_name: String):
	"""Update the UI for a specific ability"""
	if not abilities_manager:
		return
	
	var value_path = ability_value_paths.get(ability_name, "")
	if value_path != "":
		var value_label = get_node_or_null(value_path)
		if value_label:
			var current_value = abilities_manager.get_item_value(ability_name)
			
			# Update value display
			value_label.text = str(current_value)
			
			# Add visual indicator for race bonuses only
			if abilities_manager.race_bonuses.has(ability_name):
				value_label.text += " (race bonus)"


func get_abilities_manager() -> AllocationManager:
	"""Get the abilities manager from this display"""
	return abilities_manager

func get_ability_values() -> Dictionary:
	"""Get the current ability values from this display"""
	if abilities_manager:
		return abilities_manager.get_character_items()
	return {}

func can_continue() -> bool:
	"""Check if all ability points have been spent"""
	if abilities_manager:
		return abilities_manager.all_points_spent()
	return false

func get_remaining_points() -> int:
	"""Get the remaining ability points"""
	if abilities_manager:
		return abilities_manager.get_remaining_points()
	return 0

func refresh_abilities_display():
	"""Refresh the abilities display to show current values"""
	update_abilities_display()
	update_visibility_based_on_values()
