extends Control

func _ready():
	# Apply UI constants to this scene
	UIManager.setup_main_menu(self)

func _on_new_game_button_pressed():
	# Navigate to character creation step 1 (attributes & race)
	print("Starting new game - creating character...")
	get_tree().change_scene_to_file("res://scenes/character_creation/character_creation_step1.tscn")

func _on_load_game_button_pressed():
	# Load the last saved character and navigate to game world
	print("Loading last saved game...")
	
	# Get the last saved character from database
	var last_character = DatabaseManager.get_last_saved_character()
	
	if last_character:
		print("Found saved character: ", last_character.name)
		# Load character data into global CharacterCreation
		CharacterCreation.load_saved_character(last_character)
		# Navigate to game world
		get_tree().change_scene_to_file("res://scenes/game_world/hex_map.tscn")
	else:
		print("No saved character found. Please create a new character first.")
		# You could show a popup here to inform the user

func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit() 
