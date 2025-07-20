extends RefCounted
class_name AllocationManager

# Store item definitions from database (attributes or abilities)
var item_definitions = {}
# Store current character item values
var character_items = {}
# Store race bonuses (for attributes only)
var race_bonuses = {}
# Point allocation constraints
var total_points: int
var remaining_points: int
# Table information
var table_name: String
var item_type: String

func _init(p_table_name: String, p_item_type: String, total_points_to_distribute: int):
	self.table_name = p_table_name
	self.item_type = p_item_type
	self.total_points = total_points_to_distribute
	load_item_definitions()
	initialize_character_items()

func load_item_definitions():
	# Get all items from database based on table name
	var items = []
	if table_name == "attributes":
		items = DatabaseManager.get_all_attributes()
	elif table_name == "abilities":
		items = DatabaseManager.get_all_abilities()
	elif table_name == "races":
		items = DatabaseManager.get_all_races()
	elif table_name == "competences":
		items = DatabaseManager.get_all_competences()
	
	for item in items:
		if table_name == "races":
			# Races don't have base/max values, just selection
			item_definitions[item.name] = {
				"id": item.id,
				"display_order": item.display_order,
				"description": item.description
			}
		else:
			# Attributes, abilities, and competences have base/max values
			item_definitions[item.name] = {
				"id": item.id,
				"base_value": item.base_value,
				"max_value": item.max_value,
				"display_order": item.display_order,
				"description": item.description
			}
	
	print("Loaded %d %s definitions" % [item_definitions.size(), item_type])

func initialize_character_items():
	# Initialize all character items to their base values
	remaining_points = total_points
	
	for item_name in item_definitions:
		if table_name == "races":
			# For races, we don't initialize values (selection-based)
			character_items[item_name] = false  # false = not selected
		else:
			# For attributes, abilities, and competences
			var base_value = item_definitions[item_name].base_value
			character_items[item_name] = base_value

func get_item_names() -> Array:
	# Return item names sorted by display order
	var names = item_definitions.keys()
	names.sort_custom(func(a, b): 
		return item_definitions[a].display_order < item_definitions[b].display_order
	)
	return names

func get_item_value(item_name: String) -> int:
	if character_items.has(item_name):
		if table_name == "races":
			# For races, return 1 if selected, 0 if not
			return 1 if character_items[item_name] else 0
		else:
			return character_items[item_name]
	return 0

func get_item_base_value(item_name: String) -> int:
	if table_name == "races":
		return 0  # Races don't have base values
	if item_definitions.has(item_name):
		return item_definitions[item_name].base_value
	return 0

func get_item_max_value(item_name: String) -> int:
	if table_name == "races":
		return 1  # Races have max of 1 (selected or not)
	if item_definitions.has(item_name):
		var base_max = item_definitions[item_name].max_value
		
		# For attributes and competences, add race bonuses to the max value
		if (table_name == "attributes" or table_name == "competences") and race_bonuses.has(item_name):
			var race_bonus = race_bonuses[item_name]
			return base_max + race_bonus
		
		return base_max
	return 0

# Race selection methods
func select_race(race_name: String) -> bool:
	if table_name != "races":
		return false
	
	# Deselect all other races first (only one race can be selected)
	for item_name in character_items:
		character_items[item_name] = false
	
	# Select the chosen race
	if character_items.has(race_name):
		character_items[race_name] = true
		return true
	return false

func get_selected_race() -> String:
	if table_name != "races":
		return ""
	
	for race_name in character_items:
		if character_items[race_name]:
			return race_name
	return ""

func is_race_selected(race_name: String) -> bool:
	if table_name != "races":
		return false
	if character_items.has(race_name):
		return character_items[race_name]
	return false

func get_item_description(item_name: String) -> String:
	if item_definitions.has(item_name):
		return item_definitions[item_name].description
	return ""

func can_increase_item(item_name: String) -> bool:
	if not character_items.has(item_name):
		return false
	
	if table_name == "races":
		# For races, can always "increase" (select) if not already selected
		return not character_items[item_name]
	
	var current_value = character_items[item_name]
	var max_value = get_item_max_value(item_name)
	
	# For attributes and competences, check if we have race bonuses that affect the max
	if (table_name == "attributes" or table_name == "competences") and race_bonuses.has(item_name):
		var race_bonus = race_bonuses[item_name]
		var effective_max = max_value + race_bonus
		return current_value < effective_max and remaining_points > 0
	
	return current_value < max_value and remaining_points > 0

func can_decrease_item(item_name: String) -> bool:
	if not character_items.has(item_name):
		return false
	
	if table_name == "races":
		# For races, can always "decrease" (deselect) if currently selected
		return character_items[item_name]
	
	var current_value = character_items[item_name]
	var base_value = get_item_base_value(item_name)
	
	# For attributes and competences, check if we have race bonuses that prevent decrease
	if (table_name == "attributes" or table_name == "competences") and race_bonuses.has(item_name):
		var race_bonus = race_bonuses[item_name]
		var minimum_value = base_value + race_bonus
		return current_value > minimum_value
	
	return current_value > base_value

func increase_item(item_name: String) -> bool:
	if table_name == "races":
		return select_race(item_name)
	
	if can_increase_item(item_name):
		character_items[item_name] += 1
		update_remaining_points()
		return true
	return false

func decrease_item(item_name: String) -> bool:
	if table_name == "races":
		if can_decrease_item(item_name):
			character_items[item_name] = false
			return true
		return false
	
	if can_decrease_item(item_name):
		character_items[item_name] -= 1
		update_remaining_points()
		return true
	return false

func update_remaining_points():
	if table_name == "races":
		# Races don't use points, so remaining_points stays at total_points
		return
	
	var used_points = 0
	
	for item_name in character_items:
		var current_value = character_items[item_name]
		var base_value = get_item_base_value(item_name)
		var race_bonus = race_bonuses.get(item_name, 0)
		
		# Calculate points used: current_value - (base_value + race_bonus)
		# This ensures race bonuses don't count against the allocation pool
		var effective_base = base_value + race_bonus
		used_points += (current_value - effective_base)
	
	remaining_points = total_points - used_points

func get_remaining_points() -> int:
	return remaining_points

func get_character_items() -> Dictionary:
	return character_items.duplicate()

func get_all_item_values() -> Dictionary:
	"""Get all current item values as a dictionary"""
	return character_items.duplicate()

func reset_items():
	initialize_character_items()

func all_points_spent() -> bool:
	if table_name == "races":
		# For races, check if any race is selected
		return get_selected_race() != ""
	else:
		# For other types, check if all points are spent
		return remaining_points == 0

func print_character_stats():
	print("=== CHARACTER %s ===" % item_type.to_upper())
	for item_name in get_item_names():
		var value = get_item_value(item_name)
		var description = get_item_description(item_name)
		print("%s: %d (%s)" % [item_name, value, description])
	print("Remaining Points: %d" % remaining_points)
	print("=============================")

# Convenience functions for backward compatibility
func get_attribute_names() -> Array:
	return get_item_names()

func get_attribute_value(attr_name: String) -> int:
	return get_item_value(attr_name)

func can_increase_attribute(attr_name: String) -> bool:
	return can_increase_item(attr_name)

func can_decrease_attribute(attr_name: String) -> bool:
	return can_decrease_item(attr_name)

func increase_attribute(attr_name: String) -> bool:
	return increase_item(attr_name)

func decrease_attribute(attr_name: String) -> bool:
	return decrease_item(attr_name)

func get_character_attributes() -> Dictionary:
	return get_character_items()

func add_free_points(points: int):
	"""Add free points to the allocation pool (for trait bonuses)"""
	if table_name == "races":
		return  # Races don't use points
	
	remaining_points += points
	print("Added %d free points to %s allocation" % [points, item_type])

func set_race_bonuses(bonuses: Dictionary):
	"""Set race bonuses for attributes or competences (prevents decreasing below bonus level)"""
	if table_name == "attributes" or table_name == "competences":
		race_bonuses = bonuses.duplicate()
		print("Set race bonuses for %s: %s" % [table_name, race_bonuses])

func clear_race_bonuses():
	"""Clear race bonuses"""
	race_bonuses.clear()
	print("Cleared race bonuses") 
