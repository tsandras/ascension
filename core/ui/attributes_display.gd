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
	
	# Map attribute names to their SVG file names
	var attribute_svg_files = {
		"Intelligence": "intelligence.svg",
		"Strength": "strenght.svg",  # Note: typo in filename
		"Ruse": "ruse.svg",
		"Agility": "agility.svg",
		"Resolution": "resolution.svg",
		"Vitality": "vitality.svg"
	}
	
	var circle_positions = [
		Vector2(100, 220),   # Top center - Intelligence
		Vector2(170, 80),  # Top right - Strength
		Vector2(350, 80),  # Bottom right - Ruse
		Vector2(420, 220),  # Bottom center - Agility
		Vector2(340, 330),  # Bottom left - Resolution
		Vector2(200, 330)   # Top left - Vitality
	]
	
	# Load the attribute frame texture
	var frame_texture = load("res://assets/ui/attribute_frame_with_bg.svg")
	if not frame_texture:
		print("Warning: Could not load attribute_frame_with_bg.svg")
	
	# Create circles for each attribute
	for i in range(attribute_names.size()):
		var attribute_name = attribute_names[i]
		var circle_container = VBoxContainer.new()
		circle_container.name = attribute_name + "Circle"
		circle_container.custom_minimum_size = Vector2(80, 80)
		circle_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		circle_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		circle_container.position = circle_positions[i] - Vector2(40, 40)  # Center the circle
		
		# Create attribute name label
		var name_label = Label.new()
		name_label.name = "AttributeName"
		name_label.text = attribute_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.size_flags_horizontal = Control.SIZE_FILL
		name_label.size_flags_vertical = Control.SIZE_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		circle_container.add_child(name_label)
		
		# Add attribute value label if character is provided
		if character != null:
			# Create a container for the framed value
			var value_container = Control.new()
			value_container.name = "ValueContainer"
			value_container.custom_minimum_size = Vector2(50, 50)
			value_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			value_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			value_container.position = Vector2(15, 45)  # Position below the SVG icon
			
			# Add the frame background (z-index: 1 - background)
			if frame_texture:
				var frame_background = TextureRect.new()
				frame_background.name = "ValueFrame"
				frame_background.texture = frame_texture
				frame_background.custom_minimum_size = Vector2(50, 50)
				frame_background.size_flags_horizontal = Control.SIZE_FILL
				frame_background.size_flags_vertical = Control.SIZE_FILL
				frame_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				frame_background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				frame_background.z_index = 1
				
				value_container.add_child(frame_background)
			
			# Add attribute SVG illustration inside the frame (z-index: 2 - middle)
			var svg_name = attribute_svg_files.get(attribute_name, "")
			if svg_name != "":
				var svg_texture = load("res://assets/icons/svgs/" + svg_name)
				if svg_texture:
					var svg_icon = TextureRect.new()
					svg_icon.name = "AttributeSVG"
					svg_icon.texture = svg_texture
					svg_icon.custom_minimum_size = Vector2(25, 25)  # Reduced from 30x30 to 25x25
					svg_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
					svg_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
					svg_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					svg_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
					svg_icon.position = Vector2(12.5, 12.5)  # Center within the 50x50 frame (50-25)/2
					svg_icon.z_index = 2
					svg_icon.modulate = Color(1, 1, 1, 0.4)  # Reduce opacity to 40% for less visibility
					
					value_container.add_child(svg_icon)
					print("Added SVG icon inside frame for attribute: ", attribute_name, " - ", svg_name)
				else:
					print("Warning: Failed to load SVG for attribute: ", attribute_name, " - ", svg_name)
			
			# Create the value label on top of everything (z-index: 3 - foreground)
			var value_label = Label.new()
			value_label.name = "AttributeValue"
			# Get the attribute value from the character's attributes dictionary
			var attribute_value = 0
			if character.attributes.has(attribute_name):
				attribute_value = character.attributes[attribute_name]
			# Ensure the value is displayed as an integer
			value_label.text = str(int(attribute_value))
			value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			value_label.add_theme_font_size_override("font_size", 12)
			value_label.custom_minimum_size = Vector2(50, 50)  # Match frame size
			value_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			value_label.z_index = 3
			value_label.modulate = Color(1, 0.8, 0)  # Golden orange color for better visibility
			value_label.position = Vector2.ZERO  # Position at the top-left of the container
			
			# Debug: Print attribute access
			print("  Accessing attribute: ", attribute_name, " = ", attribute_value)
			
			value_container.add_child(value_label)
			circle_container.add_child(value_container)
		
		# Add the circle to the SVG container
		svg_container.add_child(circle_container)
		
		print("Created attribute circle for: " + attribute_name + " at position: " + str(circle_positions[i]))
