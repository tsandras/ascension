extends Control

func _ready():
	pass
	
	# Note: Cursor functionality is now automatically handled by MyButton, MyTextureButton, and MyControl classes


func _on_generic_button_3_button_pressed():
	# Load the last saved character and navigate to game world
	print("Loading last saved game...")
	
	# Load the last saved character using Character class
	var last_character = Character.load_from_db()
	
	if last_character and last_character.is_valid():
		print("Found saved character: ", last_character.name)
		# Navigate to game world - hex_map will load the character directly
		get_tree().change_scene_to_file("res://scenes/game_world/hex_map.tscn")
	else:
		print("No saved character found. Please create a new character first.")
		# You could show a popup here to inform the user

func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit() 


func _on_generic_button_button_pressed() -> void:
	get_tree().quit() # Replace with function body.


func _on_generic_button_2_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/character_creation/character_creation_step1.tscn")
