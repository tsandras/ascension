extends Node

# Trait manager for interpreting and applying trait bonuses
class_name TraitManager

static func get_race_trait(race_name: String) -> Dictionary:
	"""Get the trait data for a given race by combining race bonuses and trait bonuses"""
	var races = DatabaseManager.get_all_races()
	var race_data = null
	
	# Find the race
	for race in races:
		if race.name == race_name:
			race_data = race
			break
	
	if not race_data:
		return {}
	
	# Get traits for this race
	var traits = DatabaseManager.get_race_traits(race_name)
	
	# Combine race attribute bonuses with trait bonuses
	var combined_trait_data = {
		"attribute_bonuses": [],
		"ability_bonuses": [],
		"competence_bonuses": [],
		"other_bonuses": []
	}
	
	# Add race attribute bonuses
	if race_data.has("race_attribute_bonuses_dict") and race_data.race_attribute_bonuses_dict.size() > 0:
		for attr_name in race_data.race_attribute_bonuses_dict:
			var bonus_value = int(race_data.race_attribute_bonuses_dict[attr_name])  # Ensure bonus value is an integer
			combined_trait_data.attribute_bonuses.append({
				"name": attr_name,
				"value": bonus_value
			})
	
	# Add trait bonuses from all traits
	for vtrait in traits:
		# Add attribute bonuses from trait
		if vtrait.has("attribute_bonuses_dict") and vtrait.attribute_bonuses_dict.size() > 0:
			for bonus in vtrait.attribute_bonuses_dict:
				combined_trait_data.attribute_bonuses.append(bonus)
		
		# Add ability bonuses from trait
		if vtrait.has("ability_bonuses_dict") and vtrait.ability_bonuses_dict.size() > 0:
			for bonus in vtrait.ability_bonuses_dict:
				combined_trait_data.ability_bonuses.append(bonus)
		
		# Add competence bonuses from trait
		if vtrait.has("skill_bonuses_dict") and vtrait.skill_bonuses_dict.size() > 0:
			for bonus in vtrait.skill_bonuses_dict:
				combined_trait_data.competence_bonuses.append(bonus)
		
		# Add other bonuses from trait
		if vtrait.has("other_bonuses_dict") and vtrait.other_bonuses_dict.size() > 0:
			for bonus in vtrait.other_bonuses_dict:
				combined_trait_data.other_bonuses.append(bonus)
	
	return combined_trait_data

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
			var bonus_value = int(bonus.value)  # Ensure bonus value is an integer
			
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
			var bonus_value = int(bonus.value)  # Ensure bonus value is an integer
			
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
			var bonus_value = int(bonus.value)  # Ensure bonus value is an integer
			
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
