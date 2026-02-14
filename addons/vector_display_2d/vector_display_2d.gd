extends Node2D

const SHORTCUT: InputEventKey = preload("res://addons/vector_display_2d/display_shortcut.tres")

# Constant to improve vanishing speed
const VANISH_SPEED_CORRECTION := 10

@export_group("Node")
@export var target_node: Node ## Node to show its vectors
@export var target_property: String = "velocity" ## Name of the Vector2 attribute or variable in node's script

@export_group("Rendering")
@export var show_vectors: bool = true ## Show or hide all
@export var show_axes: bool = false ## Shows X and Y component for the vector
@export var vector_scale: float = 1 ## Change vectors size. This doesn't change the actual vector values

@export_group("Aspect")
@export_subgroup("Basic")
@export var main_color: Color = Color.GREEN ## Color for main vector
@export var x_axis_color: Color = Color.RED ## Color for X component of vector
@export var y_axis_color: Color = Color.BLUE ## Color for Y component of vector
@export var width: float = 1 ## Line width

@export_subgroup("Vanish colors")
@export var vanish_color: bool = false ## If true, the color turns to fallback color when the vector gets short
@export var vanish_speed: float = 1 ## Vanishing speed for all colors
@export var fallback_color: Color = Color.BLACK ## Color the vectors tend to when they get short
@export var vanish_if_normalized: bool = false ## Apply vanish even when vectors are normalized

@export_subgroup("Advanced")
@export var rainbow: bool = false ## Use rainbow colors based on the vector angle. Only aplies to main vector, not for axes
@export var clamp_vector: bool = false ## Clamp the vector length to a max value. This doesn't change the actual vector values
@export var normalize: bool = false ## Normalize vectors instead of clamping, at max length defined below. This doesn't change the actual vector values
@export var max_length: float = 100 ## Max length for vector clamping

# Auxiliar variables
var current_vector := Vector2.ZERO

# Reassigns the target node when doesn't exist
func _ready() -> void:
	if target_node == null:
		push_error("Target node not defined. Autoassigning to parent node")
		target_node = get_parent()

	if not target_node.get(target_property) is Vector2:
		push_error("Target property is not a Vector2 or doesn't exist")

# Get the vector from given property
func _physics_process(_delta) -> void:
	var new_vector: Vector2 = target_node.get(target_property)

	if normalize: new_vector = new_vector.normalized() * max_length
	if clamp_vector: new_vector = new_vector.limit_length(max_length)

	# Improves performance rendering when necesary
	if current_vector == new_vector: return

	current_vector = new_vector
	queue_redraw()

# Draw the vectors
func _draw() -> void:
	if not show_vectors: return

	var colors := _get_draw_colors()

	# Main vector render
	draw_line(Vector2.ZERO, current_vector * vector_scale, colors.main, width, true)

	if not show_axes: return

	# Axes components render
	draw_line(Vector2.ZERO, Vector2(current_vector.x, 0) * vector_scale, colors.x, width, true)
	draw_line(Vector2.ZERO, Vector2(0, current_vector.y) * vector_scale, colors.y, width, true)

# Calculates the colors based on current settings (Rainbow, Vanish, etc)
func _get_draw_colors() -> Dictionary:
	var result := {
		"main": main_color,
		"x": x_axis_color,
		"y": y_axis_color
	}

	if rainbow:
		var angle := current_vector.angle()
		if angle < 0: angle += TAU

		result.main = Color.from_hsv(angle / TAU, 1.0, 1.0)

	if vanish_color and (not normalize or vanish_if_normalized):
		var vanish_value := clampf(vanish_speed * VANISH_SPEED_CORRECTION / current_vector.length(), 0.0, 1.0)

		result.x = result.x.lerp(fallback_color, vanish_value)
		result.y = result.y.lerp(fallback_color, vanish_value)
		result.main = result.main.lerp(fallback_color, vanish_value)

	return result

# Detects shortcut to toggle visibility
func _unhandled_key_input(event) -> void:
	if event.is_pressed() and event.is_match(SHORTCUT):
		show_vectors = not show_vectors
