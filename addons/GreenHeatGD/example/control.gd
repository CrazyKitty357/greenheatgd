extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func float_to_screen(pos: Vector2) -> Vector2:
	var screen_size = get_viewport_rect().size
	return Vector2(pos.x * screen_size.x, pos.y * screen_size.y)

func _on_green_heat_drag_received(packet: Dictionary) -> void:
	# print(packet)
	var click_pos = Vector2(packet["x"], packet["y"])
	var pixel_pos = float_to_screen(click_pos)
	$ColorRect.global_position = pixel_pos
