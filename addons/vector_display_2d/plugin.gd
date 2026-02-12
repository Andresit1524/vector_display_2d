@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("VectorDisplay2D", "Node2D", preload("res://addons/vector_display_2d/vector_display_2d.gd"), preload("icon.svg"))

func _exit_tree():
	remove_custom_type("VectorDisplay2D")
