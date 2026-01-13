extends Node
class_name GreenHeat

## An advanced clickmap for twitch

## An exposed signal for detecting clicks.
signal click_received(packet: Dictionary)

## An exposed signal for detecting hovers.
signal hover_received(packet: Dictionary)

## An exposed signal for detecting when someone is dragging.
signal drag_received(packet: Dictionary)

## An exposed signal for detecting when someone releases a click or a drag.
signal release_received(packet: Dictionary)

## @deprecated: Use the release_received signal instead, this is staying for now because of compatibility with older projects.
## An exposed signal for detecting when someone releases a click or a drag.
signal drag_release_received(packet: Dictionary)



@export var detecting : bool = true ## This enables / disables the clickmap on the fly.
@export var simulating_input : bool = false ## This enables / disables the emulations of click and drag in the game's viewport
@export var channel_name : String = "" ## This is the channel name that GreenHeat is checking.

var debug = true ## This will flood your console with verbose information regarding the websocket connection.

var lastCursorPositionMemory : Dictionary[String, Vector2] = {} ## Dictionary storing the last position in the viewport of the cursors

var _ws := WebSocketPeer.new()

func _ready() -> void:
	_ws.connect_to_url("wss://heat.prod.kr/%s" % channel_name)

func _process(delta: float) -> void:
	if not detecting: return
	_ws.poll()

	while _ws.get_available_packet_count() > 0:
		var raw = _ws.get_packet().get_string_from_utf8()
		var packet = JSON.parse_string(raw)
		if packet == null: continue
		if debug: print(packet)
		match packet["type"]:
			"click":
				click_received.emit(packet)
				if simulating_input: _create_click_event(packet)
			"hover":
				hover_received.emit(packet)
				if simulating_input: _create_hover_event(packet)
			"drag":
				drag_received.emit(packet)
				if simulating_input: _create_drag_event(packet)
			"release":
				release_received.emit(packet)
				drag_release_received.emit(packet)
				if simulating_input: _create_release_event(packet)

func _create_click_event(packet: Dictionary) -> void:
	var newInput : InputEventMouseButtonHeat = _create_mouse_button(packet)
	newInput.pressed = true
	Input.parse_input_event(newInput)

func _create_hover_event(packet: Dictionary) -> void:
	var newInput : InputEventMouseMotionHeat = _create_mouse_motion(packet)
	newInput.pressure = 0.0
	Input.parse_input_event(newInput)

func _create_drag_event(packet: Dictionary) -> void:
	var newInput : InputEventMouseMotionHeat = _create_mouse_motion(packet)
	newInput.pressure = 1.0
	Input.parse_input_event(newInput)

func _create_release_event(packet: Dictionary) -> void:
	var newInput : InputEventMouseButtonHeat = _create_mouse_button(packet)
	newInput.pressed = false
	Input.parse_input_event(newInput)

func _get_position_from_event(packet: Dictionary) -> Vector2:
	return Vector2(float(packet["x"]), float(packet["y"])) * get_viewport().get_visible_rect().size

func _add_base_variables(event : InputEventMouse, packet : Dictionary) -> void:
	event.id = packet["id"]
	event.alt_pressed = packet["alt"]
	event.ctrl_pressed = packet["ctrl"]
	event.shift_pressed = packet["shift"]

func _create_mouse_motion(packet : Dictionary) -> InputEventMouseMotionHeat:
	var newInput : InputEventMouseMotionHeat = InputEventMouseMotionHeat.new()
	_add_base_variables(newInput, packet)
	
	var position : Vector2 = _get_position_from_event(packet)
	var lastPosition = lastCursorPositionMemory.get(packet["id"])
	if not lastPosition: lastPosition = Vector2.ZERO
	newInput.relative = position - lastPosition
	newInput.position = position
	
	lastCursorPositionMemory.set(packet["id"], position)
	return newInput

func _create_mouse_button(packet : Dictionary) -> InputEventMouseButtonHeat:
	var newInput : InputEventMouseButtonHeat = InputEventMouseButtonHeat.new()
	_add_base_variables(newInput, packet)
	match packet["button"]:
		"left":
			newInput.button_index = 1
		"right":
			newInput.button_index = 2
		"middle":
			newInput.button_index = 3
	var position : Vector2 = _get_position_from_event(packet)
	newInput.position = position
	lastCursorPositionMemory.set(packet["id"], position)
	return newInput
