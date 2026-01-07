extends Node
class_name GreenHeat

## An advanced clickmap for twitch

signal click_received(packet: Dictionary) ## An exposed signal for detecting clicks.
signal hover_received(packet: Dictionary) ## An exposed signal for detecting hovers.
signal drag_received(packet: Dictionary) ## An exposed signal for detecting when someone is dragging.
signal release_received(packet: Dictionary) ## An exposed signal for detecting when someone releases a click or a drag.

@export var detecting = true ## This enables / disables the clickmap on the fly.
@export var channel_name = "" ## This is the channel name that GreenHeat is checking.

var debug = false ## This will flood your console with verbose information regarding the websocket connection.

var _ws := WebSocketPeer.new()

func _ready() -> void:
	_ws.connect_to_url("wss://heat.prod.kr/%s" % channel_name)

func _process(delta: float) -> void:
	if detecting:
		_ws.poll()
	else:
		return

	while _ws.get_available_packet_count() > 0:
		var raw = _ws.get_packet().get_string_from_utf8()
		var packet = JSON.parse_string(raw)
		if packet == null: continue
		if debug: print(packet)
		match packet["type"]:
			"click":
				click_received.emit(packet)
			"hover":
				hover_received.emit(packet)
			"drag":
				drag_received.emit(packet)
			"release":
				release_received.emit(packet)
