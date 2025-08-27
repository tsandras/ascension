extends RefCounted
class_name AbilitiesDisplay

# Constants for abilities display
const ABILITY_ROW_HEIGHT = 40
const ABILITY_ROW_SPACING = 5

# Store UI elements for each ability
var ability_ui_elements = {}
# Track expanded state
var is_expanded = false

func create_abilities_area(character: Character) -> Control:
	"""Create the abilities display area with allocation controls"""
	var abilities_container = VBoxContainer.new()
	abilities_container.name = "AbilitiesContainer"
	abilities_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Create abilities label
	var abilities_label = Label.new()
	abilities_label.text = "ABILITIES"
	abilities_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	abilities_label.add_theme_font_size_override("font_size", 16)
	abilities_container.add_child(abilities_label)
	
	# Create abilities allocation manager
	var abilities_manager = AllocationManager.new("abilities", "abilities", 4)
	print("Created abilities manager with %d abilities" % abilities_manager.get_item_names().size())
	print("Initial ability values: ", abilities_manager.get_all_item_values())
	
	# Create clickable header to expand/collapse
	var header_button = Button.new()
	header_button.text = "Click to show all abilities"
	header_button.custom_minimum_size = Vector2(0, 30)
	header_button.pressed.connect(_on_header_button_pressed.bind(abilities_container, abilities_manager))
	abilities_container.add_child(header_button)
	
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
	
	# Create UI for each ability - show abilities with > 1 point or that have bonuses
	var ability_names = abilities_manager.get_item_names()
	print("Creating UI for abilities. Total abilities: ", ability_names.size())
	for ability_name in ability_names:
		var ability_value = abilities_manager.get_item_value(ability_name)
		var base_value = abilities_manager.get_item_base_value(ability_name)
		print("  %s: value=%d, base=%d, should_show=%s" % [ability_name, ability_value, base_value, str(ability_value > 1 or ability_value > base_value)])
		# Show abilities with more than 1 point OR abilities that have been boosted by bonuses
		if ability_value > 1 or ability_value > base_value:
			create_ability_row(abilities_container, ability_name, abilities_manager)
			print("    Created UI row for %s" % ability_name)
	
	# Store the full list for expansion
	abilities_container.set_meta("all_ability_names", ability_names)
	
	# Create points display
	var points_label = Label.new()
	points_label.text = "Trait and background bonuses applied to abilities"
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	abilities_container.add_child(points_label)
	
	# Store the manager for later access
	abilities_container.set_meta("abilities_manager", abilities_manager)
	abilities_container.set_meta("points_label", points_label)
	
	return abilities_container

func create_ability_row(container: VBoxContainer, ability_name: String, abilities_manager: AllocationManager):
	"""Create a row for ability allocation"""
	# Create horizontal container for this ability
	var h_container = HBoxContainer.new()
	h_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	h_container.custom_minimum_size = Vector2(0, ABILITY_ROW_HEIGHT)
	
	# Create ability name label
	var name_label = Label.new()
	name_label.text = ability_name + ":"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 14)
	
	# Create value label
	var value_label = Label.new()
	var current_value = abilities_manager.get_item_value(ability_name)
	value_label.text = str(current_value)
	value_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	value_label.custom_minimum_size = Vector2(50, 0)
	value_label.add_theme_font_size_override("font_size", 14)
	
	# Add visual indicator for race bonuses only
	if abilities_manager.race_bonuses.has(ability_name):
		value_label.text += " (race bonus)"
	
	# Add elements to container
	h_container.add_child(name_label)
	h_container.add_child(value_label)
	
	# Add to abilities container
	container.add_child(h_container)
	
	# Store references for easy access
	ability_ui_elements[ability_name] = {
		"container": h_container,
		"label": name_label,
		"value_label": value_label
	}

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

func _on_header_button_pressed(container: Control, abilities_manager: AllocationManager):
	"""Handle header button press to expand/collapse abilities"""
	is_expanded = !is_expanded
	
	var header_button = container.get_child(1)  # The button is the second child
	var all_ability_names = container.get_meta("all_ability_names")
	
	if is_expanded:
		# Show all abilities
		header_button.text = "Click to show only high abilities"
		show_all_abilities(container, abilities_manager, all_ability_names)
	else:
		# Show only abilities with > 1 point or bonuses
		header_button.text = "Click to show all abilities"
		show_filtered_abilities(container, abilities_manager, all_ability_names)

func show_all_abilities(container: Control, abilities_manager: AllocationManager, all_ability_names: Array):
	"""Show all abilities"""
	# Remove existing ability rows (keep label, button, and points label)
	var children_to_remove = []
	for i in range(2, container.get_child_count() - 1):  # Skip label, button, and points label
		children_to_remove.append(container.get_child(i))
	
	for child in children_to_remove:
		container.remove_child(child)
		child.queue_free()
	
	# Add all abilities
	for ability_name in all_ability_names:
		create_ability_row(container, ability_name, abilities_manager)

func show_filtered_abilities(container: Control, abilities_manager: AllocationManager, all_ability_names: Array):
	"""Show only abilities with more than 1 point or that have bonuses"""
	# Remove existing ability rows (keep label, button, and points label)
	var children_to_remove = []
	for i in range(2, container.get_child_count() - 1):  # Skip label, button, and points label
		children_to_remove.append(container.get_child(i))
	
	for child in children_to_remove:
		container.remove_child(child)
		child.queue_free()
	
	# Add abilities with > 1 point OR abilities that have been boosted by bonuses
	for ability_name in all_ability_names:
		var ability_value = abilities_manager.get_item_value(ability_name)
		var base_value = abilities_manager.get_item_base_value(ability_name)
		if ability_value > 1 or ability_value > base_value:
			create_ability_row(container, ability_name, abilities_manager)

func update_ability_ui(ability_name: String, abilities_manager: AllocationManager, container: Control):
	"""Update the UI for a specific ability"""
	if not ability_ui_elements.has(ability_name):
		return
	
	var ui_elements = ability_ui_elements[ability_name]
	var current_value = abilities_manager.get_item_value(ability_name)
	
	# Update value display
	ui_elements.value_label.text = str(current_value)
	
	# Add visual feedback for race-bonused abilities
	if abilities_manager.race_bonuses.has(ability_name):
		var race_bonus = abilities_manager.race_bonuses[ability_name]
		var base_value = abilities_manager.get_item_base_value(ability_name)
		var minimum_value = base_value + race_bonus
		
		# Add visual indicator to value label for race bonuses
		if current_value > base_value:
			ui_elements.value_label.text = str(current_value) + " (race bonus)"
	


func get_abilities_manager(container: Control) -> AllocationManager:
	"""Get the abilities manager from the container"""
	if container.has_meta("abilities_manager"):
		return container.get_meta("abilities_manager")
	return null

func get_ability_values(container: Control) -> Dictionary:
	"""Get the current ability values from the container"""
	var abilities_manager = get_abilities_manager(container)
	if abilities_manager:
		return abilities_manager.get_character_items()
	return {}

func can_continue(container: Control) -> bool:
	"""Check if all ability points have been spent"""
	var abilities_manager = get_abilities_manager(container)
	if abilities_manager:
		return abilities_manager.all_points_spent()
	return false

func get_remaining_points(container: Control) -> int:
	"""Get the remaining ability points"""
	var abilities_manager = get_abilities_manager(container)
	if abilities_manager:
		return abilities_manager.get_remaining_points()
	return 0

func refresh_abilities_display(container: Control):
	"""Refresh the abilities display to show current values"""
	var abilities_manager = get_abilities_manager(container)
	if not abilities_manager:
		return
	
	# Update all ability value labels
	for ability_name in ability_ui_elements:
		if ability_ui_elements.has(ability_name):
			var ui_elements = ability_ui_elements[ability_name]
			var current_value = abilities_manager.get_item_value(ability_name)
			var base_value = abilities_manager.get_item_base_value(ability_name)
			
			# Update value display
			ui_elements.value_label.text = str(current_value)
			
			# Add visual indicator for race bonuses only
			if abilities_manager.race_bonuses.has(ability_name):
				ui_elements.value_label.text += " (race bonus)"
			else:
				# Remove any existing bonus indicators
				ui_elements.value_label.text = str(current_value)
