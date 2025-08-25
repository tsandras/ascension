extends Control

# Reference to the map seeder
var map_seeder: Node

func _ready():
	print("=== MAP SEEDER UI ===")
	
	# Get the map seeder reference (UI is a child of MapSeeder)
	map_seeder = get_parent()
	if not map_seeder:
		print("ERROR: MapSeeder not found!")
		return
	
	# Create UI
	create_ui()
	
	print("Map Seeder UI initialized")

func create_ui():
	"""Create the user interface"""
	# Set the control to fill the entire viewport
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create a center container with manual positioning
	var center_container = Control.new()
	center_container.custom_minimum_size = Vector2(450, 500)
	
	# Wait for the next frame to get proper viewport size
	await get_tree().process_frame
	
	# Calculate center position
	var viewport_size = get_viewport().get_visible_rect().size
	var center_x = (viewport_size.x - 450) / 2
	var center_y = (viewport_size.y - 500) / 2
	
	center_container.position = Vector2(center_x, center_y)
	add_child(center_container)
	
	# Main container inside the center container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	center_container.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Map Seeder Tool"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Spacer after title
	var title_spacer = Control.new()
	title_spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(title_spacer)
	
	# Create a centered container for buttons
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 15)
	button_container.custom_minimum_size = Vector2(400, 0)
	vbox.add_child(button_container)
	
	# Buttons with consistent sizing
	var create_csv_btn = Button.new()
	create_csv_btn.text = "Recreate Sample CSV Files"
	create_csv_btn.custom_minimum_size = Vector2(0, 40)
	create_csv_btn.pressed.connect(_on_create_csv_pressed)
	button_container.add_child(create_csv_btn)
	
	var clear_data_btn = Button.new()
	clear_data_btn.text = "Clear All Map Data"
	clear_data_btn.custom_minimum_size = Vector2(0, 40)
	clear_data_btn.pressed.connect(_on_clear_data_pressed)
	button_container.add_child(clear_data_btn)
	
	var seed_maps_btn = Button.new()
	seed_maps_btn.text = "Seed Maps from CSV"
	seed_maps_btn.custom_minimum_size = Vector2(0, 40)
	seed_maps_btn.pressed.connect(_on_seed_maps_pressed)
	button_container.add_child(seed_maps_btn)
	
	var seed_tiles_btn = Button.new()
	seed_tiles_btn.text = "Seed Tiles from CSV"
	seed_tiles_btn.custom_minimum_size = Vector2(0, 40)
	seed_tiles_btn.pressed.connect(_on_seed_tiles_pressed)
	button_container.add_child(seed_tiles_btn)
	
	var seed_overlays_btn = Button.new()
	seed_overlays_btn.text = "Seed Overlays from CSV"
	seed_overlays_btn.custom_minimum_size = Vector2(0, 40)
	seed_overlays_btn.pressed.connect(_on_seed_overlays_pressed)
	button_container.add_child(seed_overlays_btn)
	
	var seed_map_tiles_btn = Button.new()
	seed_map_tiles_btn.text = "Seed Map Tiles from CSV"
	seed_map_tiles_btn.custom_minimum_size = Vector2(0, 40)
	seed_map_tiles_btn.pressed.connect(_on_seed_map_tiles_pressed)
	button_container.add_child(seed_map_tiles_btn)
	
	var seed_abilities_btn = Button.new()
	seed_abilities_btn.text = "Seed Abilities from CSV"
	seed_abilities_btn.custom_minimum_size = Vector2(0, 40)
	seed_abilities_btn.pressed.connect(_on_seed_abilities_pressed)
	button_container.add_child(seed_abilities_btn)
	

	
	var seed_all_btn = Button.new()
	seed_all_btn.text = "Seed All from CSV"
	seed_all_btn.custom_minimum_size = Vector2(0, 40)
	seed_all_btn.pressed.connect(_on_seed_all_pressed)
	button_container.add_child(seed_all_btn)
	
	# Spacer before quit button
	var quit_spacer = Control.new()
	quit_spacer.custom_minimum_size = Vector2(0, 20)
	button_container.add_child(quit_spacer)
	
	# Quit button
	var quit_btn = Button.new()
	quit_btn.text = "Quit"
	quit_btn.custom_minimum_size = Vector2(0, 40)
	quit_btn.pressed.connect(_on_quit_pressed)
	button_container.add_child(quit_btn)
	
	# Spacer before status
	var status_spacer = Control.new()
	status_spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(status_spacer)
	
	# Status label
	var status_label = Label.new()
	status_label.text = "Ready to use CSV files for map generation"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color.GRAY)
	vbox.add_child(status_label)
	
	# Store reference to status label
	set_meta("status_label", status_label)

func _on_create_csv_pressed():
	"""Create sample CSV files"""
	print("Creating sample CSV files...")
	map_seeder.force_create_sample_csv_files()
	update_status("Sample CSV files recreated")

func _on_seed_maps_pressed():
	"""Seed maps from CSV"""
	print("Seeding maps from CSV...")
	map_seeder.seed_maps_from_csv()
	update_status("Maps seeded from CSV")

func _on_seed_tiles_pressed():
	"""Seed tiles from CSV"""
	print("Seeding tiles from CSV...")
	map_seeder.seed_tiles_from_csv()
	update_status("Tiles seeded from CSV")

func _on_seed_overlays_pressed():
	"""Seed overlays from CSV"""
	print("Seeding overlays from CSV...")
	map_seeder.seed_overlays_from_csv()
	update_status("Overlays seeded from CSV")

func _on_seed_map_tiles_pressed():
	"""Seed map tiles from CSV"""
	print("Seeding map tiles from CSV...")
	map_seeder.seed_map_tiles_from_csv()
	update_status("Map tiles seeded from CSV")

func _on_seed_abilities_pressed():
	"""Seed abilities from CSV"""
	print("Seeding abilities from CSV...")
	map_seeder.seed_abilities_from_csv()
	update_status("Abilities seeded from CSV")



func _on_seed_all_pressed():
	"""Seed all data from CSV"""
	print("Seeding all data from CSV...")
	map_seeder.seed_all_from_csv()
	update_status("All data seeded from CSV")

func _on_clear_data_pressed():
	"""Clear all map data from database"""
	print("Clearing all map data...")
	map_seeder.clear_all_map_data()
	update_status("All map data cleared")

func _on_quit_pressed():
	"""Quit the application"""
	print("Quitting Map Seeder Tool...")
	get_tree().quit()

func update_status(message: String):
	"""Update the status label"""
	var status_label = get_meta("status_label")
	if status_label:
		status_label.text = message
		print("Status: ", message) 
