extends RefCounted
class_name OverlayManager

# Overlay layer reference
var overlay_layer: Node2D

func _init(layer: Node2D):
	overlay_layer = layer

func create_overlay_sprite(overlay_data: Dictionary, position: Vector2 = Vector2.ZERO) -> Sprite2D:
	"""Create an overlay sprite from database data"""
	var texture_path = overlay_data.get("texture_path", "")
	if texture_path.is_empty():
		print("Warning: No texture path for overlay: ", overlay_data.get("name", ""))
		return null
	
	var texture = load(texture_path)
	if not texture:
		print("Warning: Failed to load overlay texture: ", texture_path)
		return null
	
	# Create overlay sprite
	var overlay = Sprite2D.new()
	overlay.texture = texture
	overlay.position = position
	overlay.z_index = 10  # Ensure overlay appears above tile (higher z_index)
	
	# Scale overlay to be more visible (make it larger for debugging)
	var overlay_size = texture.get_size()
	var max_size = overlay_size.x if overlay_size.x > overlay_size.y else overlay_size.y
	var scale_factor = (HexTileConstants.OVERLAY_WIDTH / HexTileConstants.OVERLAY_SCALE_FACTOR) / max_size  # Full tile size for debugging
	overlay.scale = Vector2(scale_factor, scale_factor)
	
	print("Created overlay: ", overlay_data.get("name", ""))
	
	return overlay

func add_overlay_to_tile(tile: Sprite2D, tile_data: Dictionary):
	"""Add overlays to a tile based on database data"""
	# Check if tile has overlay data
	var first_overlay_id = tile_data.get("first_overlay_id")
	var second_overlay_id = tile_data.get("second_overlay_id")
	var first_overlay_x = tile_data.get("first_overlay_x", 0.5)
	var first_overlay_y = tile_data.get("first_overlay_y", 0.5)
	var second_overlay_x = tile_data.get("second_overlay_x", 0.5)
	var second_overlay_y = tile_data.get("second_overlay_y", 0.5)
	
	# Add first overlay if present
	if first_overlay_id != null and first_overlay_id != 0:
		var overlay_data = DatabaseManager.get_overlay_by_id(first_overlay_id)
		if overlay_data:
			print("Found overlay data: ", overlay_data.get("name", ""))
		else:
			print("No overlay data found for ID: ", first_overlay_id)
			return
		
		var overlay = create_overlay_sprite(overlay_data)
		if overlay:
			print("Overlay sprite created successfully")
		else:
			print("Failed to create overlay sprite!")
			return
		
		overlay_layer.add_child(overlay)
		
		# Position overlay relative to tile center (0.5, 0.5 is center)
		var tile_size = 1024.0
		var offset_x = (first_overlay_x - 0.5) * tile_size
		var offset_y = (first_overlay_y - 0.5) * tile_size
		overlay.global_position = tile.global_position + Vector2(offset_x, offset_y)
		
		# Store reference to overlay in tile metadata
		tile.set_meta("first_overlay", overlay)
	
	# Add second overlay if present
	if second_overlay_id != null and second_overlay_id != 0:
		print("Looking up overlay ID: ", second_overlay_id)
		var overlay_data = DatabaseManager.get_overlay_by_id(second_overlay_id)
		if overlay_data:
			print("Found overlay data: ", overlay_data.get("name", ""))
		else:
			print("No overlay data found for ID: ", second_overlay_id)
			return
		
		var overlay = create_overlay_sprite(overlay_data)
		if overlay:
			print("Second overlay sprite created successfully")
		else:
			print("Failed to create second overlay sprite!")
			return
		
		overlay_layer.add_child(overlay)
		
		# Position overlay relative to tile center (0.5, 0.5 is center)
		var tile_size = 1024.0
		var offset_x = (second_overlay_x - 0.5) * tile_size
		var offset_y = (second_overlay_y - 0.5) * tile_size
		overlay.global_position = tile.global_position + Vector2(offset_x, offset_y)
		
		# Store reference to overlay in tile metadata
		tile.set_meta("second_overlay", overlay)

func remove_overlay_from_tile(tile: Sprite2D):
	"""Remove overlays from a tile if they exist"""
	var first_overlay = tile.get_meta("first_overlay", null)
	var second_overlay = tile.get_meta("second_overlay", null)
	
	if first_overlay:
		first_overlay.queue_free()
		tile.set_meta("first_overlay", null)
		print("Removed first overlay from tile")
	
	if second_overlay:
		second_overlay.queue_free()
		tile.set_meta("second_overlay", null)
		print("Removed second overlay from tile")

func clear_all_overlays():
	"""Clear all overlays from the overlay layer"""
	if overlay_layer:
		for child in overlay_layer.get_children():
			child.queue_free()
		print("Cleared all overlays") 
