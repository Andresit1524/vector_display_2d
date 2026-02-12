extends Node2D

const shortcut: InputEventKey = preload("res://addons/vector_display_2d/display_shortcut.tres")

@export_group("Node")
@export var target_node: Node = get_parent() ## Node to show its vectors
@export var target_property: String = "velocity" ## Name of the Vector2 atribute or variable in node's script

@export_group("Rendering")
@export var show: bool = true ## Show or hide all
@export var show_axes: bool = true ## If false, show only main vector
@export var vector_scale: float = 1 ## Change vectors size. This doesn't change the actual vector values

@export_group("Aspect")
@export var main_color: Color = Color.GREEN ## Color for main vector
@export var x_axis_xolor: Color = Color.RED ## Color for X component of vector
@export var y_axis_color: Color = Color.BLUE ## Color for Y component of vector
@export var width: float = 1 ## Line width

@export_subgroup("Advanced")
@export var vanish_color: bool = false ## If true, the color turns to fallback color when the vector gets short
@export var vanish_speed: float = 1 ## Vanishing speed for all colors
@export var fallback_color: Color = Color.BLACK ## Color the vectors tend to when gets short

# Constant for improve vanishing speed
const vanish_speed_correction := 20

var vector: Vector2
var vanish_value: float
var current_main_color: Color
var current_x_color: Color
var current_y_color: Color

# Get the vector from given property
func _physics_process(delta) -> void:
	vector = target_node.get(target_property)
	queue_redraw()

# Draw the vectors
func _draw() -> void:
	if not show:
		return

	_set_colors()

	vanish_value = clampf(vanish_speed_correction * vanish_speed / vector.length(), 0, 1)

	# Main vector render
	draw_line(Vector2.ZERO, vector * vector_scale, current_main_color, width, true)

	if not show_axes:
		return

	# Axes components render
	draw_line(Vector2.ZERO, Vector2(vector.x, 0) * vector_scale, current_x_color, width, true)
	draw_line(Vector2.ZERO, Vector2(0, vector.y) * vector_scale, current_y_color, width, true)

func _set_colors() -> void:
	if vanish_color:
		current_x_color = (x_axis_xolor * (1 - vanish_value)) + fallback_color * vanish_value
		current_y_color = (y_axis_color * (1 - vanish_value)) + fallback_color * vanish_value
		current_main_color = (main_color * (1 - vanish_value)) + fallback_color * vanish_value
		return

	current_x_color = x_axis_xolor
	current_y_color = y_axis_color
	current_main_color = main_color

# Detects shortcuts for switch visibility
func _unhandled_key_input(event) -> void:
	if event.is_pressed() and event.is_match(shortcut):
		show = not show
