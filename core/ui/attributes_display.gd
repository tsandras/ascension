extends RefCounted
class_name AttributesDisplay

func create_attributes_area(character: Character = null) -> Control:
	"""Create the attributes area with SVG symbols - reusable function"""
	# Create attributes area container
	var attributes_area = VBoxContainer.new()
	attributes_area.name = "AttributesArea"
	attributes_area.custom_minimum_size = Vector2(500, 400)  # Increased size to accommodate circles
	attributes_area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	attributes_area.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Create title label
	var title_label = Label.new()
	title_label.text = "Attributes"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	attributes_area.add_child(title_label)
	
	# Create a Control container to hold the background SVG, overlay icons, and attribute circles
	var svg_container = Control.new()
	svg_container.name = "SVGContainer"
	svg_container.custom_minimum_size = Vector2(500, 400)  # Increased size to accommodate circles
	svg_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	svg_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Create the main attributes area SVG background (centered)
	var main_svg = TextureRect.new()
	main_svg.name = "MainAttributesSVG"
	main_svg.custom_minimum_size = Vector2(400, 250)
	main_svg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_svg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_svg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	main_svg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	main_svg.position = Vector2(50, 75)  # Center the main SVG in the container
	
	# Load the main attributes area SVG
	var svg_texture = load("res://assets/symbols/attributes_area.svg")
	if svg_texture:
		main_svg.texture = svg_texture
		print("Loaded attributes_area.svg successfully")
	else:
		print("Warning: Failed to load attributes_area.svg")
	
	svg_container.add_child(main_svg)
	
	# Add magic2.svg icon positioned inside the attributes area
	var magic_svg = TextureRect.new()
	magic_svg.name = "MagicSVG"
	magic_svg.custom_minimum_size = Vector2(50, 50)
	magic_svg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	magic_svg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	magic_svg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	magic_svg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	magic_svg.position = Vector2(180, 145)  # Position inside the attributes area (adjusted for new container)
	
	var magic_texture = load("res://assets/symbols/magic2.svg")
	if magic_texture:
		magic_svg.texture = magic_texture
		print("Loaded magic2.svg successfully")
	else:
		print("Warning: Failed to load magic2.svg")
	
	svg_container.add_child(magic_svg)
	
	# Add resistance2.svg icon positioned inside the attributes area
	var resistance_svg = TextureRect.new()
	resistance_svg.name = "ResistanceSVG"
	resistance_svg.custom_minimum_size = Vector2(50, 50)
	resistance_svg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	resistance_svg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	resistance_svg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	resistance_svg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	resistance_svg.position = Vector2(270, 145)  # Position inside the attributes area (adjusted for new container)
	
	var resistance_texture = load("res://assets/symbols/resistance2.svg")
	if resistance_texture:
		resistance_svg.texture = resistance_texture
		print("Loaded resistance2.svg successfully")
	else:
		print("Warning: Failed to load resistance2.svg")
	
	svg_container.add_child(resistance_svg)

	# Add speed2.svg icon positioned inside the attributes area
	var speed_svg = TextureRect.new()
	speed_svg.name = "SpeedSVG"
	speed_svg.custom_minimum_size = Vector2(50, 50)
	speed_svg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	speed_svg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	speed_svg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	speed_svg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	speed_svg.position = Vector2(225, 235)  # Position inside the attributes area (adjusted for new container)
	
	var speed_texture = load("res://assets/symbols/speed2.svg")
	if speed_texture:
		speed_svg.texture = speed_texture
		print("Loaded speed2.svg successfully")
	else:
		print("Warning: Failed to load speed2.svg")
	
	svg_container.add_child(speed_svg)
	
	# Create 6 attribute circles around the MainAttributesSVG
	create_attribute_circles(svg_container, character)
	
	# Add the SVG container to the attributes area
	attributes_area.add_child(svg_container)
	
	return attributes_area

func create_attribute_circles(svg_container: Control, character: Character = null):
	# Debug: Print character info
	if character != null:
		print("AttributesDisplay received character:")
		print("  Name: ", character.name)
		print("  Race: ", character.race_name)
		print("  Attributes: ", character.attributes)
	else:
		print("AttributesDisplay: No character provided")
	
	# Get the 6 attribute names (must match the order in allocation_manager.gd)
	var attribute_names = ["Intelligence", "Strength", "Ruse", "Agility", "Resolution", "Vitality"]
	
	var circle_positions = [
		Vector2(100, 220),   # Top center - Intelligence
		Vector2(170, 80),  # Top right - Strength
		Vector2(350, 80),  # Bottom right - Ruse
		Vector2(420, 220),  # Bottom center - Agility
		Vector2(340, 330),  # Bottom left - Resolution
		Vector2(200, 330)   # Top left - Vitality
	]
	
	# Create circles for each attribute
	for i in range(attribute_names.size()):
		var circle_container = VBoxContainer.new()
		circle_container.name = attribute_names[i] + "Circle"
		circle_container.custom_minimum_size = Vector2(80, 80)
		circle_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		circle_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		circle_container.position = circle_positions[i] - Vector2(40, 40)  # Center the circle
		
		# Create the circle background (using a Panel for now, can be replaced with custom drawing)
		var circle_panel = Panel.new()
		circle_panel.name = "CircleBackground"
		circle_panel.custom_minimum_size = Vector2(80, 80)
		circle_panel.size_flags_horizontal = Control.SIZE_FILL
		circle_panel.size_flags_vertical = Control.SIZE_FILL
		
		# Make the panel circular by using a custom style (basic approach)
		# In a more advanced implementation, you could use a custom shader or texture
		
		circle_container.add_child(circle_panel)
		
		# Create attribute name label
		var name_label = Label.new()
		name_label.name = "AttributeName"
		name_label.text = attribute_names[i]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.size_flags_horizontal = Control.SIZE_FILL
		name_label.size_flags_vertical = Control.SIZE_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		circle_panel.add_child(name_label)
		
		# Add attribute value label if character is provided
		if character != null:
			var value_label = Label.new()
			value_label.name = "AttributeValue"
			# Get the attribute value from the character's attributes dictionary
			var attribute_value = 0
			if character.attributes.has(attribute_names[i]):
				attribute_value = character.attributes[attribute_names[i]]
			# Ensure the value is displayed as an integer
			value_label.text = str(int(attribute_value))
			value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			value_label.add_theme_font_size_override("font_size", 12)
			value_label.size_flags_horizontal = Control.SIZE_FILL
			value_label.size_flags_vertical = Control.SIZE_FILL
			value_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			value_label.position.y = 50  # Position below the name
			
			# Debug: Print attribute access
			print("  Accessing attribute: ", attribute_names[i], " = ", attribute_value)
			
			circle_panel.add_child(value_label)
		
		# Add the circle to the SVG container
		svg_container.add_child(circle_container)
		
		print("Created attribute circle for: " + attribute_names[i] + " at position: " + str(circle_positions[i]))
