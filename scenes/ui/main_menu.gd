extends Control

func _ready():
	# Apply UI constants to this scene
	UIManager.setup_main_menu(self)

func _on_new_game_button_pressed():
	# Navigate to character creation step 1 (attributes & race)
	get_tree().change_scene_to_file("res://scenes/character_creation/character_creation_step1.tscn")

func _on_test_map_button_pressed():
	# Navigate directly to the hex map for testing
	print("Loading test map...")
	get_tree().change_scene_to_file("res://scenes/game_world/hex_map.tscn")

func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit() 
