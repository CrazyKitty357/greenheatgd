@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("GreenHeat", "Node", preload("res://addons/GreenHeatGD/GreenHeat.gd"), preload("res://addons/GreenHeatGD/GreenHeat.png"))


func _exit_tree() -> void:
	remove_custom_type("GreenHeat")
