extends RefCounted
class_name AllocationManager

# Store item definitions from database (attributes or abilities)
var item_definitions = {}
# Store current character item values
var character_items = {}
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
	
	for item in items:
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
		return character_items[item_name]
	return 0

func get_item_base_value(item_name: String) -> int:
	if item_definitions.has(item_name):
		return item_definitions[item_name].base_value
	return 0

func get_item_max_value(item_name: String) -> int:
	if item_definitions.has(item_name):
		return item_definitions[item_name].max_value
	return 0

func get_item_description(item_name: String) -> String:
	if item_definitions.has(item_name):
		return item_definitions[item_name].description
	return ""

func can_increase_item(item_name: String) -> bool:
	if not character_items.has(item_name):
		return false
	
	var current_value = character_items[item_name]
	var max_value = get_item_max_value(item_name)
	
	return current_value < max_value and remaining_points > 0

func can_decrease_item(item_name: String) -> bool:
	if not character_items.has(item_name):
		return false
	
	var current_value = character_items[item_name]
	var base_value = get_item_base_value(item_name)
	
	return current_value > base_value

func increase_item(item_name: String) -> bool:
	if can_increase_item(item_name):
		character_items[item_name] += 1
		update_remaining_points()
		return true
	return false

func decrease_item(item_name: String) -> bool:
	if can_decrease_item(item_name):
		character_items[item_name] -= 1
		update_remaining_points()
		return true
	return false

func update_remaining_points():
	var used_points = 0
	
	for item_name in character_items:
		var current_value = character_items[item_name]
		var base_value = get_item_base_value(item_name)
		used_points += (current_value - base_value)
	
	remaining_points = total_points - used_points

func get_remaining_points() -> int:
	return remaining_points

func get_character_items() -> Dictionary:
	return character_items.duplicate()

func reset_items():
	initialize_character_items()

func all_points_spent() -> bool:
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
