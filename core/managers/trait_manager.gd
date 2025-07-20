extends Node

# Trait manager for interpreting and applying trait bonuses
class_name TraitManager

static func get_race_trait(race_name: String) -> Dictionary:
	"""Get the trait data for a given race"""
	var races = DatabaseManager.get_all_races()
	for race in races:
		if race.name == race_name:
			# Parse trait data from JSON columns
			var trait_data = {}
			
			# Parse attribute bonuses
			if race.has("attribute_bonuses") and race.attribute_bonuses:
				if race.attribute_bonuses is String:
					var json = JSON.new()
					if json.parse(race.attribute_bonuses) == OK:
						trait_data["attribute_bonuses"] = json.data
					else:
						trait_data["attribute_bonuses"] = []
				else:
					trait_data["attribute_bonuses"] = race.attribute_bonuses
			else:
				trait_data["attribute_bonuses"] = []
			
			# Parse ability bonuses
			if race.has("ability_bonuses") and race.ability_bonuses:
				if race.ability_bonuses is String:
					var json = JSON.new()
					if json.parse(race.ability_bonuses) == OK:
						trait_data["ability_bonuses"] = json.data
					else:
						trait_data["ability_bonuses"] = []
				else:
					trait_data["ability_bonuses"] = race.ability_bonuses
			else:
				trait_data["ability_bonuses"] = []
			
			# Parse competence bonuses
			if race.has("skill_bonuses") and race.skill_bonuses:
				if race.skill_bonuses is String:
					var json = JSON.new()
					if json.parse(race.skill_bonuses) == OK:
						trait_data["competence_bonuses"] = json.data
					else:
						trait_data["competence_bonuses"] = []
				else:
					trait_data["competence_bonuses"] = race.skill_bonuses
			else:
				trait_data["competence_bonuses"] = []
			
			# Parse other bonuses
			if race.has("other_bonuses") and race.other_bonuses:
				if race.other_bonuses is String:
					var json = JSON.new()
					if json.parse(race.other_bonuses) == OK:
						trait_data["other_bonuses"] = json.data
					else:
						trait_data["other_bonuses"] = []
				else:
					trait_data["other_bonuses"] = race.other_bonuses
			else:
				trait_data["other_bonuses"] = []
			
			return trait_data
	
	return {}

static func apply_trait_bonuses(trait_data: Dictionary, attributes: Dictionary, abilities: Dictionary, competences: Dictionary) -> Dictionary:
	"""Apply trait bonuses to character data and return modified data"""
	var result = {
		"attributes": attributes.duplicate(),
		"abilities": abilities.duplicate(),
		"competences": competences.duplicate(),
		"free_points": {
			"attributes": 0,
			"abilities": 0,
			"competences": 0
		}
	}
	
	# Apply attribute bonuses
	if trait_data.has("attribute_bonuses"):
		for bonus in trait_data.attribute_bonuses:
			var attr_name = bonus.name.to_lower()
			var bonus_value = bonus.value
			
			# Find the attribute (case-insensitive)
			for attr in result.attributes:
				if attr.to_lower() == attr_name:
					result.attributes[attr] += bonus_value
					print("Applied attribute bonus: %s +%d" % [attr, bonus_value])
					break
	
	# Apply ability bonuses
	if trait_data.has("ability_bonuses"):
		for bonus in trait_data.ability_bonuses:
			var ability_name = bonus.name.to_lower()
			var bonus_value = bonus.value
			
			# Find the ability (case-insensitive)
			for ability in result.abilities:
				if ability.to_lower() == ability_name:
					result.abilities[ability] += bonus_value
					print("Applied ability bonus: %s +%d" % [ability, bonus_value])
					break
	
	# Apply competence bonuses and count free points
	if trait_data.has("competence_bonuses"):
		for bonus in trait_data.competence_bonuses:
			var competence_name = bonus.name.to_lower()
			var bonus_value = bonus.value
			
			if competence_name == "free":
				# This is a free point bonus
				result.free_points.competences += bonus_value
				print("Added %d free competence points from trait" % bonus_value)
			else:
				# Find the competence (case-insensitive)
				for competence in result.competences:
					if competence.to_lower() == competence_name:
						result.competences[competence] += bonus_value
						print("Applied competence bonus: %s +%d" % [competence, bonus_value])
						break
	
	return result

static func get_trait_description(trait_data: Dictionary) -> String:
	"""Generate a description of the trait bonuses for display"""
	var descriptions = []
	
	# Attribute bonuses
	if trait_data.has("attribute_bonuses") and trait_data.attribute_bonuses.size() > 0:
		var attr_descriptions = []
		for bonus in trait_data.attribute_bonuses:
			var sign = "+" if bonus.value > 0 else ""
			attr_descriptions.append("%s %s%d" % [bonus.name.capitalize(), sign, bonus.value])
		descriptions.append("Attributes: " + ", ".join(attr_descriptions))
	
	# Ability bonuses
	if trait_data.has("ability_bonuses") and trait_data.ability_bonuses.size() > 0:
		var abil_descriptions = []
		for bonus in trait_data.ability_bonuses:
			var sign = "+" if bonus.value > 0 else ""
			abil_descriptions.append("%s %s%d" % [bonus.name.capitalize(), sign, bonus.value])
		descriptions.append("Abilities: " + ", ".join(abil_descriptions))
	
	# Competence bonuses
	if trait_data.has("competence_bonuses") and trait_data.competence_bonuses.size() > 0:
		var comp_descriptions = []
		for bonus in trait_data.competence_bonuses:
			if bonus.name == "free":
				comp_descriptions.append("%d free competence points" % bonus.value)
			else:
				var sign = "+" if bonus.value > 0 else ""
				comp_descriptions.append("%s %s%d" % [bonus.name.capitalize(), sign, bonus.value])
		descriptions.append("Competences: " + ", ".join(comp_descriptions))
	
	# Other bonuses
	if trait_data.has("other_bonuses") and trait_data.other_bonuses.size() > 0:
		var other_descriptions = []
		for bonus in trait_data.other_bonuses:
			var sign = "+" if bonus.value > 0 else ""
			if bonus.has("subtype"):
				other_descriptions.append("%s %s %s%d" % [bonus.type.capitalize(), bonus.subtype.capitalize(), sign, bonus.value])
			else:
				other_descriptions.append("%s %s%d" % [bonus.type.capitalize(), sign, bonus.value])
		descriptions.append("Other: " + ", ".join(other_descriptions))
	
	return "\n".join(descriptions) if descriptions.size() > 0 else "No bonuses" 