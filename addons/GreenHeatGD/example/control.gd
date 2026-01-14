extends Control

var input_emu = false

var _click_type

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
	if input_emu == false:
		var click_pos = Vector2(packet["x"], packet["y"])
		var pixel_pos = float_to_screen(click_pos)
		$ColorRect.color = "#00c14f"
		$ColorRect.global_position = pixel_pos
	else:
		pass


func _on_green_heat_release_received(packet: Dictionary) -> void:
	if input_emu == false:
		var click_pos = Vector2(packet["x"], packet["y"])
		var pixel_pos = float_to_screen(click_pos)
		$ColorRect.color = "#c20041"
		$ColorRect.global_position = pixel_pos
	else:
		pass


func _on_green_heat_hover_received(packet: Dictionary) -> void:
	if input_emu == false:
		var click_pos = Vector2(packet["x"], packet["y"])
		var pixel_pos = float_to_screen(click_pos)
		$ColorRect.color = "#c2c2c2"
		$ColorRect.global_position = pixel_pos
	else:
		pass


func _on_green_heat_click_received(packet: Dictionary) -> void:
	if input_emu == false:
		var click_pos = Vector2(packet["x"], packet["y"])
		var pixel_pos = float_to_screen(click_pos)
		$ColorRect.color = "#c2c200"
		$ColorRect.global_position = pixel_pos
	else:
		pass


func _on_option_button_item_selected(index: int) -> void:
	if index == 1:
		input_emu = true
		$GreenHeat.simulating_input = true
		# print("input emulation is enabled")
		
	else: 
		input_emu = false
		$GreenHeat.simulating_input = false


func _input(event: InputEvent) -> void:
	if GreenHeat.is_input_heat(event):
		# print(event)
		
		$ColorRect.global_position = event.position
		$ColorRect.color = "#c2c2c2"
		if event is InputEventMouseButton and event.pressed:
			$ColorRect.color = "#c2c200"
			match event.button_index:
				1: 
					_click_type = 1
					print("left click!")
				2:
					_click_type = 2
					print("right click!")
				3:
					_click_type = 3
					print("middle click!")
		
		if event is InputEventMouseMotion and event.pressure:
			$ColorRect.color = "#00c14f"
			# print("dragging...")
			match _click_type:
				1:
					print("left click drag...")
				2:
					print("right click drag...")
				3:
					print("middle click drag...")
		
		if event is InputEventMouseButton and event.pressed == false:
			$ColorRect.color = "#c20041"
			# print("released!")
