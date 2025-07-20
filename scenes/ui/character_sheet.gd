extends Control

# Character sheet popup that displays over the map
class_name CharacterSheet

# UI node references
@onready var character_name_label = $SheetContainer/VBoxContainer/HeaderContainer/CharacterInfo/CharacterName
@onready var race_info_label = $SheetContainer/VBoxContainer/HeaderContainer/CharacterInfo/RaceInfo
@onready var avatar_sprite = $SheetContainer/VBoxContainer/HeaderContainer/AvatarContainer/AvatarSprite
@onready var close_button = $SheetContainer/VBoxContainer/HeaderContainer/CloseButton
@onready var attributes_list = $SheetContainer/VBoxContainer/StatsContainer/LeftColumn/AttributesSection/AttributesList
@onready var abilities_list = $SheetContainer/VBoxContainer/StatsContainer/LeftColumn/AbilitiesSection/AbilitiesList
@onready var competences_list = $SheetContainer/VBoxContainer/StatsContainer/RightColumn/CompetencesSection/CompetencesList
@onready var skills_list = $SheetContainer/VBoxContainer/StatsContainer/RightColumn/SkillsSection/SkillsList

# Character data
var character_data: Dictionary = {}

func _ready():
	# Connect close button
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Add cursor functionality to buttons
	add_cursor_to_buttons()
	
	# Hide the sheet initially
	visible = false

func _input(event):
	# Close on ESC key
	if event.is_action_pressed("ui_cancel"):
		hide_sheet()

func show_sheet(character: Dictionary):
	"""Display the character sheet with character data"""
	character_data = character
	populate_character_info()
	populate_attributes()
	populate_abilities()
	populate_competences()
	populate_skills()
	visible = true
	
	# Focus the close button for keyboard navigation
	close_button.grab_focus()

func hide_sheet():
	"""Hide the character sheet"""
	visible = false

func populate_character_info():
	"""Populate the character name, race, and avatar"""
	if character_data.has("name"):
		character_name_label.text = character_data.name
	
	if character_data.has("race_name") and character_data.has("sex"):
		race_info_label.text = "%s (%s)" % [character_data.race_name, character_data.sex]
	
	# Load avatar
	if character_data.has("sex") and character_data.has("race_name"):
		var avatar_path = "res://assets/avatars/%s_%s_1.png" % [
			character_data.sex, 
			character_data.race_name.to_lower()
		]
		var avatar_texture = load(avatar_path)
		if avatar_texture:
			avatar_sprite.texture = avatar_texture
		else:
			print("Warning: Could not load avatar: ", avatar_path)

func populate_attributes():
	"""Populate the attributes list"""
	clear_container(attributes_list)
	
	if character_data.has("attributes_dict"):
		var attributes = character_data.attributes_dict
		for attr_name in attributes:
			var value = attributes[attr_name]
			create_stat_row(attributes_list, attr_name, value)

func populate_abilities():
	"""Populate the abilities list"""
	clear_container(abilities_list)
	
	if character_data.has("abilities_dict"):
		var abilities = character_data.abilities_dict
		for ability_name in abilities:
			var value = abilities[ability_name]
			create_stat_row(abilities_list, ability_name, value)

func populate_competences():
	"""Populate the competences list"""
	clear_container(competences_list)
	
	if character_data.has("competences_dict"):
		var competences = character_data.competences_dict
		for competence_name in competences:
			var value = competences[competence_name]
			create_stat_row(competences_list, competence_name, value)

func populate_skills():
	"""Populate the skills list"""
	clear_container(skills_list)
	
	if character_data.has("skills_dict"):
		var skills_data = character_data.skills_dict
		
		# Handle skills data - could be string, array, or dictionary
		if skills_data is String:
			var json = JSON.new()
			if json.parse(skills_data) == OK:
				skills_data = json.data
			else:
				skills_data = []
		
		if skills_data is Array:
			# Convert skill IDs to skill names
			var all_skills = DatabaseManager.get_all_skills()
			var skill_names = []
			
			for skill_id in skills_data:
				for skill in all_skills:
					if skill.id == skill_id:
						skill_names.append(skill.name)
						break
			
			for skill_name in skill_names:
				create_skill_row(skills_list, skill_name)
		elif skills_data is Dictionary:
			for skill_id in skills_data:
				# Find skill name by ID
				var all_skills = DatabaseManager.get_all_skills()
				for skill in all_skills:
					if skill.id == skill_id:
						create_skill_row(skills_list, skill.name)
						break

func create_stat_row(container: VBoxContainer, name: String, value: int):
	"""Create a stat row with name and value"""
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = name.capitalize() + ":"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var value_label = Label.new()
	value_label.text = str(value)
	value_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	row.add_child(name_label)
	row.add_child(value_label)
	container.add_child(row)

func create_skill_row(container: VBoxContainer, skill_name: String):
	"""Create a skill row with just the name"""
	var row = Label.new()
	row.text = "• " + skill_name
	container.add_child(row)

func clear_container(container: VBoxContainer):
	"""Clear all children from a container"""
	for child in container.get_children():
		child.queue_free()

func _on_close_button_pressed():
	"""Handle close button press"""
	hide_sheet() 

func add_cursor_to_buttons():
	"""Add cursor functionality to all buttons"""
	if close_button:
		CursorUtils.add_cursor_to_button(close_button) 