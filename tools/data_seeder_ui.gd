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
	
	
	# Seeding buttons - in dependency order
	var seed_label = Label.new()
	seed_label.text = "Seed Data from CSV (in dependency order):"
	seed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(seed_label)
	
	# First: Traits (no dependencies)
	var seed_traits_btn = Button.new()
	seed_traits_btn.text = "1. Seed Traits from CSV (FIRST - no dependencies)"
	seed_traits_btn.custom_minimum_size = Vector2(300, 40)
	seed_traits_btn.pressed.connect(_on_seed_traits_pressed)
	container.add_child(seed_traits_btn)
	
	# Second: Personalities (no dependencies)
	var seed_personalities_btn = Button.new()
	seed_personalities_btn.text = "2. Seed Personalities from CSV"
	seed_personalities_btn.custom_minimum_size = Vector2(300, 40)
	seed_personalities_btn.pressed.connect(_on_seed_personalities_pressed)
	container.add_child(seed_personalities_btn)
	
	# Third: Races (depends on traits)
	var seed_races_btn = Button.new()
	seed_races_btn.text = "3. Seed Races from CSV (needs traits)"
	seed_races_btn.custom_minimum_size = Vector2(300, 40)
	seed_races_btn.pressed.connect(_on_seed_races_pressed)
	container.add_child(seed_races_btn)
	
	# Fourth: Backgrounds (no dependencies)
	var seed_backgrounds_btn = Button.new()
	seed_backgrounds_btn.text = "4. Seed Backgrounds from CSV"
	seed_backgrounds_btn.custom_minimum_size = Vector2(300, 40)
	seed_backgrounds_btn.pressed.connect(_on_seed_backgrounds_pressed)
	container.add_child(seed_backgrounds_btn)
	
	# Fifth: Features (depends on traits)
	var seed_features_btn = Button.new()
	seed_features_btn.text = "5. Seed Features from CSV (needs traits)"
	seed_features_btn.custom_minimum_size = Vector2(300, 40)
	seed_features_btn.pressed.connect(_on_seed_features_pressed)
	container.add_child(seed_features_btn)
	
	# Sixth: Nodes (depends on traits and skills)
	var seed_nodes_btn = Button.new()
	seed_nodes_btn.text = "6. Seed Nodes from CSV (needs traits & skills)"
	seed_nodes_btn.custom_minimum_size = Vector2(300, 40)
	seed_nodes_btn.pressed.connect(_on_seed_nodes_pressed)
	container.add_child(seed_nodes_btn)
	
	# Special: Seed with traits first (for dependencies)
	var seed_with_traits_btn = Button.new()
	seed_with_traits_btn.text = "Seed Data with Traits First (auto dependency order)"
	seed_with_traits_btn.custom_minimum_size = Vector2(300, 40)
	seed_with_traits_btn.pressed.connect(_on_seed_with_traits_pressed)
	container.add_child(seed_with_traits_btn)
	
	# All at once
	var seed_all_btn = Button.new()
	seed_all_btn.text = "Seed All Data from CSV (full dependency order)"
	seed_all_btn.custom_minimum_size = Vector2(300, 40)
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

func _on_seed_personalities_pressed():
	print("Seeding personalities from CSV...")
	data_seeder.seed_personalities_from_csv()

func _on_seed_races_pressed():
	print("Seeding races from CSV...")
	data_seeder.seed_races_from_csv()

func _on_seed_with_traits_pressed():
	print("Seeding data with traits first...")
	data_seeder.seed_with_traits_first()

func _on_seed_all_pressed():
	print("Seeding all data from CSV...")
	data_seeder.seed_all_from_csv()

func _on_clear_all_pressed():
	print("Clearing all game data...")
	data_seeder.clear_all_game_data()
