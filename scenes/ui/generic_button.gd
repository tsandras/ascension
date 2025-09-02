extends Control
class_name GenericButton

@export var text: String = "Button" :
	set(value):
		text = value
		if has_node("TextureButton/Label"):
			$TextureButton/Label.text = value

@export var click_sound_enabled: bool = true
@export var sound_volume: float = -10.0

signal button_pressed

func _ready():
	# Check if TextureButton exists before accessing it
	if not has_node("TextureButton"):
		print("Error: TextureButton not found in GenericButton")
		return
	
	# Automatically add cursor functionality
	CursorUtils.add_cursor_to_texture_button($TextureButton)
	
	# Connect the texture button signal
	$TextureButton.pressed.connect(_on_texture_button_pressed)
	
	# Set initial text
	if has_node("TextureButton/Label"):
		$TextureButton/Label.text = text
	
	# Configure audio player
	if has_node("AudioStreamPlayer"):
		$AudioStreamPlayer.volume_db = sound_volume

func _on_texture_button_pressed():
	# Play click sound if enabled
	if click_sound_enabled and has_node("AudioStreamPlayer"):
		$AudioStreamPlayer.play()
	
	# Emit our custom signal
	button_pressed.emit()
	print("GenericButton pressed: ", text)
