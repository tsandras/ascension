extends Control

# UI script for the Data Seeder tool

@onready var data_seeder: Node = get_parent()

func _ready():
	# Create UI elements
	create_ui()

func create_ui():
	# Create main container
	var container = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(container)
	
	# Title
	var title = Label.new()
	title.text = "Data Seeder Tool"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	container.add_child(spacer1)
	
	# Sample CSV creation buttons
	var sample_label = Label.new()
	sample_label.text = "Sample CSV Files:"
	sample_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(sample_label)
	
	var create_samples_btn = Button.new()
	create_samples_btn.text = "Create Sample CSV Files"
	create_samples_btn.custom_minimum_size = Vector2(200, 40)
	create_samples_btn.pressed.connect(_on_create_samples_pressed)
	container.add_child(create_samples_btn)
	
	var force_create_btn = Button.new()
	force_create_btn.text = "Force Create Sample CSV Files (Overwrite)"
	force_create_btn.custom_minimum_size = Vector2(200, 40)
	force_create_btn.pressed.connect(_on_force_create_samples_pressed)
	container.add_child(force_create_btn)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	container.add_child(spacer2)
	
	# Seeding buttons
	var seed_label = Label.new()
	seed_label.text = "Seed Data from CSV:"
	seed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(seed_label)
	
	var seed_nodes_btn = Button.new()
	seed_nodes_btn.text = "Seed Nodes from CSV"
	seed_nodes_btn.custom_minimum_size = Vector2(200, 40)
	seed_nodes_btn.pressed.connect(_on_seed_nodes_pressed)
	container.add_child(seed_nodes_btn)
	
	var seed_traits_btn = Button.new()
	seed_traits_btn.text = "Seed Traits from CSV"
	seed_traits_btn.custom_minimum_size = Vector2(200, 40)
	seed_traits_btn.pressed.connect(_on_seed_traits_pressed)
	container.add_child(seed_traits_btn)
	
	var seed_backgrounds_btn = Button.new()
	seed_backgrounds_btn.text = "Seed Backgrounds from CSV"
	seed_backgrounds_btn.custom_minimum_size = Vector2(200, 40)
	seed_backgrounds_btn.pressed.connect(_on_seed_backgrounds_pressed)
	container.add_child(seed_backgrounds_btn)
	
	var seed_features_btn = Button.new()
	seed_features_btn.text = "Seed Features from CSV"
	seed_features_btn.custom_minimum_size = Vector2(200, 40)
	seed_features_btn.pressed.connect(_on_seed_features_pressed)
	container.add_child(seed_features_btn)
	
	var seed_all_btn = Button.new()
	seed_all_btn.text = "Seed All Data from CSV"
	seed_all_btn.custom_minimum_size = Vector2(200, 40)
	seed_all_btn.pressed.connect(_on_seed_all_pressed)
	container.add_child(seed_all_btn)
	
	# Spacer
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 20)
	container.add_child(spacer3)
	
	# Clear data buttons
	var clear_label = Label.new()
	clear_label.text = "Clear Data:"
	clear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(clear_label)
	
	var clear_all_btn = Button.new()
	clear_all_btn.text = "Clear All Game Data"
	clear_all_btn.custom_minimum_size = Vector2(200, 40)
	clear_all_btn.pressed.connect(_on_clear_all_pressed)
	container.add_child(clear_all_btn)

# Button event handlers
func _on_create_samples_pressed():
	print("Creating sample CSV files...")
	data_seeder.create_sample_csv_files()

func _on_force_create_samples_pressed():
	print("Force creating sample CSV files...")
	data_seeder.force_create_sample_csv_files()

func _on_seed_nodes_pressed():
	print("Seeding nodes from CSV...")
	data_seeder.seed_nodes_from_csv()

func _on_seed_traits_pressed():
	print("Seeding traits from CSV...")
	data_seeder.seed_traits_from_csv()

func _on_seed_backgrounds_pressed():
	print("Seeding backgrounds from CSV...")
	data_seeder.seed_backgrounds_from_csv()

func _on_seed_features_pressed():
	print("Seeding features from CSV...")
	data_seeder.seed_features_from_csv()

func _on_seed_all_pressed():
	print("Seeding all data from CSV...")
	data_seeder.seed_all_from_csv()

func _on_clear_all_pressed():
	print("Clearing all game data...")
	data_seeder.clear_all_game_data()
