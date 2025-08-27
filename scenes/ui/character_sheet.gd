extends Control

# Character sheet popup that displays over the map
class_name CharacterSheet

# Character instance
var character: Character = null

# UI References
@onready var character_name_label: Label = $SheetContainer/VBoxContainer/HeaderContainer/CharacterInfo/CharacterName
@onready var race_info_label: Label = $SheetContainer/VBoxContainer/HeaderContainer/CharacterInfo/RaceInfo
@onready var avatar_sprite: TextureRect = $SheetContainer/VBoxContainer/HeaderContainer/AvatarContainer/AvatarSprite
@onready var close_button: Button = $SheetContainer/VBoxContainer/HeaderContainer/CloseButton

# Stats UI References
@onready var pv_max_value: Label = $SheetContainer/VBoxContainer/StatsSection/StatsGrid/PVMaxValue
@onready var endurance_max_value: Label = $SheetContainer/VBoxContainer/StatsSection/StatsGrid/EnduranceMaxValue
@onready var mana_max_value: Label = $SheetContainer/VBoxContainer/StatsSection/StatsGrid/ManaMaxValue
@onready var block_max_value: Label = $SheetContainer/VBoxContainer/StatsSection/StatsGrid/BlockMaxValue
@onready var willpower_max_value: Label = $SheetContainer/VBoxContainer/StatsSection/StatsGrid/WillpowerMaxValue

# Lists UI References
@onready var attributes_list: VBoxContainer = $SheetContainer/VBoxContainer/StatsContainer/LeftColumn/AttributesSection/AttributesList
@onready var abilities_list: VBoxContainer = $SheetContainer/VBoxContainer/StatsContainer/LeftColumn/AbilitiesSection/AbilitiesList

func _ready():
	# Hide the sheet initially
	visible = false
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

func _input(event):
	# Close on ESC key
	if event.is_action_pressed("ui_cancel"):
		hide_sheet()

func _on_close_button_pressed():
	hide_sheet()

func show_sheet(character_instance: Character = null):
	"""Display the character sheet with character data"""
	if character_instance == null:
		# Try to load character from creation or last saved
		character = Character.load_from_creation()
		if character == null:
			character = Character.load_from_db()
		if character == null:
			print("No character data available for character sheet")
			return
	else:
		character = character_instance
	
	populate_character_info()
	populate_character_stats()
	populate_attributes()
	populate_abilities()
	visible = true

func hide_sheet():
	"""Hide the character sheet"""
	visible = false

func populate_character_info():
	"""Populate the character name, race, background, and avatar"""
	if character and character.is_valid():
		if character_name_label:
			character_name_label.text = character.name
		if race_info_label:
			var background_text = ""
			if character.background_name != "":
				background_text = " - " + character.background_name
			race_info_label.text = "%s%s (%s)" % [character.race_name, background_text, character.sex]
		
		# Load avatar
		if avatar_sprite:
			var avatar_path = character.get_avatar_path()
			if avatar_path != "":
				var avatar_texture = load(avatar_path)
				if avatar_texture:
					avatar_sprite.texture = avatar_texture

func populate_character_stats():
	"""Populate the character stats using the Character class"""
	if character and character.is_valid():
		var all_stats = character.get_all_stats()
		print("DEBUG: All stats: ", all_stats)
		
		if pv_max_value:
			pv_max_value.text = str(all_stats.pv_max)
		if endurance_max_value:
			endurance_max_value.text = str(all_stats.endurance_max)
		if mana_max_value:
			mana_max_value.text = str(all_stats.mana_max)
		if block_max_value:
			block_max_value.text = str(all_stats.block_max)
		if willpower_max_value:
			willpower_max_value.text = str(all_stats.willpower_max)

func populate_attributes():
	"""Populate the attributes list"""
	if not attributes_list:
		return
		
	clear_container(attributes_list)
	
	if character and character.is_valid():
		for attr_name in character.attributes:
			var value = character.attributes[attr_name]
			create_stat_row(attributes_list, attr_name, value)

func populate_abilities():
	"""Populate the abilities list"""
	if not abilities_list:
		return
		
	clear_container(abilities_list)
	
	if character and character.is_valid():
		for ability_name in character.abilities:
			var value = character.abilities[ability_name]
			if value > 0:  # Only show abilities with value > 0
				create_stat_row(abilities_list, ability_name, value)



func create_stat_row(container: VBoxContainer, p_name: String, value: int):
	"""Create a stat row with name and value"""
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = p_name.capitalize() + ":"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var value_label = Label.new()
	value_label.text = str(value)
	value_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	row.add_child(name_label)
	row.add_child(value_label)
	container.add_child(row)



func clear_container(container: VBoxContainer):
	"""Clear all children from a container"""
	for child in container.get_children():
		child.queue_free() 
