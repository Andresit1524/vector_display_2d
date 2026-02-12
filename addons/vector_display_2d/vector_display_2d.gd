extends Node2D

const SHORTCUT: InputEventKey = preload("res://addons/vector_display_2d/display_shortcut.tres")

# Constant to improve vanishing speed
const VANISH_SPEED_CORRECTION := 20

@export_group("Node")
@export var target_node: Node ## Node to show its vectors
@export var target_property: String = "velocity" ## Name of the Vector2 attribute or variable in node's script

@export_group("Rendering")
@export var show_vectors: bool = true ## Show or hide all
@export var show_axes: bool = true ## If false, shows only main vector
@export var vector_scale: float = 1 ## Change vectors size. This doesn't change the actual vector values

@export_group("Aspect")
@export var main_color: Color = Color.GREEN ## Color for main vector
@export var x_axis_color: Color = Color.RED ## Color for X component of vector
@export var y_axis_color: Color = Color.BLUE ## Color for Y component of vector
@export var width: float = 1 ## Line width

@export_subgroup("Advanced")
@export var vanish_color: bool = false ## If true, the color turns to fallback color when the vector gets short
@export var vanish_speed: float = 1 ## Vanishing speed for all colors
@export var fallback_color: Color = Color.BLACK ## Color the vectors tend to when they get short

# Auxiliar variables
var current_vector := Vector2.ZERO
var previous_vector: Vector2
var current_vanish_value: float
var current_main_color: Color
var current_x_color: Color
var current_y_color: Color

# Reassigns the target node when doesn't exist
func _ready() -> void:
	if target_node == null:
		push_error("Target node not defined. Autoassigning to parent node")
		target_node = get_parent()

	if not target_node.get(target_property) is Vector2:
		push_error("Target property is not a Vector2 or doesn't exist")

# Get the vector from given property
func _physics_process(_delta) -> void:
	previous_vector = current_vector
	current_vector = target_node.get(target_property)

	# Improves performance rendering when necesary
	if previous_vector == current_vector:
		return

	queue_redraw()

# Draw the vectors
func _draw() -> void:
	if not show_vectors:
		return

	_set_colors()
	current_vanish_value = clampf(vanish_speed * VANISH_SPEED_CORRECTION / current_vector.length(), 0, 1)

	# Main vector render
	draw_line(Vector2.ZERO, current_vector * vector_scale, current_main_color, width, true)

	if not show_axes:
		return

	# Axes components render
	draw_line(Vector2.ZERO, Vector2(current_vector.x, 0) * vector_scale, current_x_color, width, true)
	draw_line(Vector2.ZERO, Vector2(0, current_vector.y) * vector_scale, current_y_color, width, true)

## Set colors for vectors in both cases (solid color or vanishing color)
func _set_colors() -> void:
	if vanish_color:
		current_x_color = x_axis_color * (1 - current_vanish_value) + fallback_color * current_vanish_value
		current_y_color = y_axis_color * (1 - current_vanish_value) + fallback_color * current_vanish_value
		current_main_color = main_color * (1 - current_vanish_value) + fallback_color * current_vanish_value
		return

	current_x_color = x_axis_color
	current_y_color = y_axis_color
	current_main_color = main_color

# Detects shortcut to toggle visibility
func _unhandled_key_input(event) -> void:
	if event.is_pressed() and event.is_match(SHORTCUT):
		show_vectors = not show_vectors
