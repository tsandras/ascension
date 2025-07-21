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
	# Main container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(400, 300)
	add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Map Seeder Tool"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	# Buttons
	var create_csv_btn = Button.new()
	create_csv_btn.text = "Recreate Sample CSV Files"
	create_csv_btn.pressed.connect(_on_create_csv_pressed)
	vbox.add_child(create_csv_btn)
	
	var clear_data_btn = Button.new()
	clear_data_btn.text = "Clear All Map Data"
	clear_data_btn.pressed.connect(_on_clear_data_pressed)
	vbox.add_child(clear_data_btn)
	
	var seed_maps_btn = Button.new()
	seed_maps_btn.text = "Seed Maps from CSV"
	seed_maps_btn.pressed.connect(_on_seed_maps_pressed)
	vbox.add_child(seed_maps_btn)
	
	var seed_tiles_btn = Button.new()
	seed_tiles_btn.text = "Seed Tiles from CSV"
	seed_tiles_btn.pressed.connect(_on_seed_tiles_pressed)
	vbox.add_child(seed_tiles_btn)
	
	var seed_map_tiles_btn = Button.new()
	seed_map_tiles_btn.text = "Seed Map Tiles from CSV"
	seed_map_tiles_btn.pressed.connect(_on_seed_map_tiles_pressed)
	vbox.add_child(seed_map_tiles_btn)
	
	var seed_all_btn = Button.new()
	seed_all_btn.text = "Seed All from CSV"
	seed_all_btn.pressed.connect(_on_seed_all_pressed)
	vbox.add_child(seed_all_btn)
	
	var export_btn = Button.new()
	export_btn.text = "Export Seed Functions"
	export_btn.pressed.connect(_on_export_pressed)
	vbox.add_child(export_btn)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)
	
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

func _on_seed_map_tiles_pressed():
	"""Seed map tiles from CSV"""
	print("Seeding map tiles from CSV...")
	map_seeder.seed_map_tiles_from_csv()
	update_status("Map tiles seeded from CSV")

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

func _on_export_pressed():
	"""Export seed functions"""
	print("Exporting seed functions...")
	map_seeder.export_seed_functions()
	update_status("Seed functions exported")

func update_status(message: String):
	"""Update the status label"""
	var status_label = get_meta("status_label")
	if status_label:
		status_label.text = message
		print("Status: ", message) 
