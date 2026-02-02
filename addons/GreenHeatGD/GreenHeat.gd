@tool
extends Node
class_name GreenHeat

## An advanced clickmap for twitch
## @tutorial: https://heat.prod.kr/tutorial

## An exposed signal for detecting clicks.
signal click_received(packet: Dictionary)

## An exposed signal for detecting hovers.
signal hover_received(packet: Dictionary)

## An exposed signal for detecting when someone is dragging.
signal drag_received(packet: Dictionary)

## An exposed signal for detecting when someone releases a click or a drag.
signal release_received(packet: Dictionary)

## @deprecated: Use the [signal release_received] signal instead, this is staying for now because of compatibility with older projects.
## An exposed signal for detecting when someone releases a click or a drag.
signal drag_release_received(packet: Dictionary)



@export var detecting : bool = true ## This enables / disables the clickmap on the fly.
## @experimental: This feature is very buggy when working with multiple windows or subviewports.
## This enables / disables the emulations of click and drag in the game's viewport. [br]
## You can listen to any [InputEvent] including GreenHeat's ones using the [method Node._input] callback in any script. [br]
## Properties that can't be stored in the [InputEvent] like "time", "latency" and "type" can be found in the metadata of the Event.
## [codeblock]
## func _input(event: InputEvent) -> void:
##	print(event.get_meta("id"))
## [/codeblock]
## You can also use the helper functions provided by the [GreenHeat] class to access those values easily.
## [codeblock]
##func _input(event: InputEvent) -> void:
##	if GreenHeat.is_input_heat(event):
##		print(event) # do something with the GreenHeat inputs
## [/codeblock]
## [color=yellow]Notice[/color][br]
## -- When using subwindows, if they are embedded, the users will be able to move and interact with the window. If they are not embedded, this feature will just not work anymore, you need to set the subwindow [member Window.transient] & [member Window.transient_to_focused] to true for the simulated click to work (only on the root window)
## [br]
## -- [SubViewport]s will not receive any input
@export var simulating_input : bool = false:
	set(value):
		simulating_input = value
		notify_property_list_changed()

@export var channel_name : String = "" ## This is the channel name that GreenHeat is checking.

## By default, the inputs will be mapped to the size of the root window. If you want the inputs to be restricted to a part of the window, set this variable.[br]
## You can change the position of the wanted region and its size.
@export var mapping_override: Rect2 

var debug = false ## This will flood your console with verbose information regarding the websocket connection.

var lastCursorPositionMemory : Dictionary[String, Vector2] = {} ## Dictionary storing the last position of the cursors in the [Viewport]

var _ws := WebSocketPeer.new()

func _ready() -> void:
	if not Engine.is_editor_hint():
		_ws.connect_to_url("wss://heat.prod.kr/%s" % channel_name)

func _validate_property(property: Dictionary) -> void:
	if property.name == "mapping_override" and not simulating_input:
		property.usage |= PROPERTY_USAGE_READ_ONLY

func _process(delta: float) -> void:
	if not detecting or Engine.is_editor_hint(): return
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
	var newInput : InputEventMouseButton = _create_mouse_button(packet)
	newInput.pressed = true
	newInput.set_meta("type", "click")
	Input.parse_input_event(newInput)

func _create_hover_event(packet: Dictionary) -> void:
	var newInput : InputEventMouseMotion = _create_mouse_motion(packet)
	newInput.pressure = 0.0
	newInput.set_meta("type", "hover")
	Input.parse_input_event(newInput)

func _create_drag_event(packet: Dictionary) -> void:
	var newInput : InputEventMouseMotion = _create_mouse_motion(packet)
	newInput.pressure = 1.0
	newInput.set_meta("type", "drag")
	Input.parse_input_event(newInput)

func _create_release_event(packet: Dictionary) -> void:
	var newInput : InputEventMouseButton = _create_mouse_button(packet)
	newInput.pressed = false
	newInput.set_meta("type", "release")
	Input.parse_input_event(newInput)

func _get_position_from_event(packet: Dictionary) -> Vector2:
	if mapping_override:
		return (Vector2(float(packet["x"]), float(packet["y"])) * mapping_override.size) + mapping_override.position
	return Vector2(float(packet["x"]), float(packet["y"])) * get_tree().root.get_visible_rect().size

func _add_base_variables(event : InputEventMouse, packet : Dictionary) -> void:
	event.set_meta("id", packet["id"])
	event.set_meta("time", packet["time"])
	event.set_meta("latency", packet["latency"])
	event.alt_pressed = packet["alt"]
	event.ctrl_pressed = packet["ctrl"]
	event.shift_pressed = packet["shift"]

func _create_mouse_motion(packet : Dictionary) -> InputEventMouseMotion:
	var newInput : InputEventMouseMotion = InputEventMouseMotion.new()
	_add_base_variables(newInput, packet)
	
	var position : Vector2 = _get_position_from_event(packet)
	var lastPosition = lastCursorPositionMemory.get(packet["id"])
	if not lastPosition: lastPosition = Vector2.ZERO
	newInput.relative = position - lastPosition
	newInput.position = position
	
	lastCursorPositionMemory.set(packet["id"], position)
	return newInput

func _create_mouse_button(packet : Dictionary) -> InputEventMouseButton:
	var newInput : InputEventMouseButton = InputEventMouseButton.new()
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

## Will check if the [InputEvent] was created by GreenHeat
static func is_input_heat(event: InputEvent) -> bool:
	if event.has_meta("id"):
		return true
	else:
		return false
	
	# this worked on my machinetm but printed 3 bajillion errors to debugger - crazykitty
	# return true if event.get_meta("id") else false

## Will check if the [InputEvent] is sourced from a "click" GreenHeat packet. Return null if the event isn't from GreenHeat
static func is_input_click(event: InputEvent) -> bool:
	return true if event.get_meta("type") == "click" else false

## Will check if the [InputEvent] is sourced from a "hover" GreenHeat packet. Return null if the event isn't from GreenHeat
static func is_input_hover(event: InputEvent) -> bool:
	return true if event.get_meta("type") == "hover" else false

## Will check if the [InputEvent] is sourced from a "drag" GreenHeat packet. Return null if the event isn't from GreenHeat
static func is_input_drag(event: InputEvent) -> bool:
	return true if event.get_meta("type") == "drag" else false
	
## Will check if the [InputEvent] is sourced from a "release" GreenHeat packet. Return null if the event isn't from GreenHeat
static func is_input_release(event: InputEvent) -> bool:
	return true if event.get_meta("type") == "release" else false

## Returns the type of the source GreenHeat packet or null if the event isn't from GreenHeat
static func get_input_type(event: InputEvent):
	return event.get_meta("type")

## Returns the id of the source GreenHeat packet or null if the event isn't from GreenHeat
static func get_id(event: InputEvent):
	return event.get_meta("id")

## Returns the time of the source GreenHeat packet or null if the event isn't from GreenHeat
static func get_time(event: InputEvent):
	return event.get_meta("time")

## Returns the latency of the source GreenHeat packet or null if the event isn't from GreenHeat
static func get_latency(event: InputEvent):
	return event.get_meta("latency")
