extends VBoxContainer
class_name AttributesDisplay

## AttributesDisplay - Manages the attributes display scene
##
## This scene contains the visual elements including:
## - Main attributes frame with background
## - Symbol overlays (magic, resistance, speed) 
## - 6 attribute value labels positioned on the frame
##
## Usage:
##   var attributes_display = preload("res://core/ui/attributes_display.tscn").instantiate()
##   parent_node.add_child(attributes_display)
##   attributes_display.update_attributes_from_character(character)

# The 6 attribute names (must match the order in allocation_manager.gd)
var attribute_names = ["Intelligence", "Strength", "Ruse", "Agility", "Resolution", "Vitality"]

# Map attribute names to their value label node paths in the scene
var attribute_value_paths = {
	"Intelligence": "AttributesFrameWithBg/IntelligenceBox/IntelligenceValue",
	"Strength": "AttributesFrameWithBg/StrengthBox/StrenghtValue",  # Note: typo in scene
	"Ruse": "AttributesFrameWithBg/RuseCircle/RuseValue",
	"Agility": "AttributesFrameWithBg/AgilityCircle/AgilityValue", 
	"Resolution": "AttributesFrameWithBg/ResolutionCircle/ResolutionValue",
	"Vitality": "AttributesFrameWithBg/VitalityCircle/VitalityValue"
}

func _ready():
	"""Initialize the attributes display"""
	print("AttributesDisplay scene initialized")

func update_attributes_from_character(character: Character):
	"""Update the attributes display with character data"""
	if not character:
		print("Warning: No character provided to AttributesDisplay")
		return
	
	print("AttributesDisplay updating with character:")
	print("  Name: ", character.name)
	print("  Race: ", character.race_name)
	print("  Attributes: ", character.attributes)
	
	# Update each attribute value
	for attribute_name in attribute_names:
		var value_path = attribute_value_paths.get(attribute_name, "")
		if value_path != "":
			var value_label = get_node_or_null(value_path)
			if value_label:
				var attribute_value = 0
				if character.attributes.has(attribute_name):
					attribute_value = character.attributes[attribute_name]
				# Ensure the value is displayed as an integer
				value_label.text = str(int(attribute_value))
				print("  Updated %s: %d" % [attribute_name, attribute_value])
			else:
				print("Warning: Could not find value label for %s at path: %s" % [attribute_name, value_path])
		else:
			print("Warning: No path mapping for attribute: %s" % attribute_name)

func update_attributes_from_dict(attributes_dict: Dictionary):
	"""Update attribute values directly from a dictionary"""
	print("AttributesDisplay updating values from dictionary: ", attributes_dict)
	
	for attribute_name in attribute_names:
		var value_path = attribute_value_paths.get(attribute_name, "")
		if value_path != "":
			var value_label = get_node_or_null(value_path)
			if value_label:
				var attribute_value = attributes_dict.get(attribute_name, 0)
				# Ensure the value is displayed as an integer
				value_label.text = str(int(attribute_value))
				print("  Updated %s: %d" % [attribute_name, attribute_value])

func reset_to_defaults():
	"""Reset all attribute values to default (8)"""
	for attribute_name in attribute_names:
		var value_path = attribute_value_paths.get(attribute_name, "")
		if value_path != "":
			var value_label = get_node_or_null(value_path)
			if value_label:
				value_label.text = "8"
				print("Reset %s to default value: 8" % attribute_name)
