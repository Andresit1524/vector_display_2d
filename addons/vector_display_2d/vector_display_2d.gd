extends Node2D

const SHORTCUT: InputEventKey = preload("res://addons/vector_display_2d/display_shortcut.tres")

# Constant to improve dimming speed
const DIMMING_SPEED_CORRECTION := 10

@export_group("Node")
@export var target_node: Node ## Node to show its vectors
@export var target_property: String = "velocity" ## Name of the Vector2 attribute or variable in node's script

@export_group("Show")
@export var show_vectors: bool = true: ## Show or hide all
	set(value):
		show_vectors = value
		queue_redraw()
@export var show_axes: bool = false: ## Shows X and Y component for the vector
	set(value):
		show_axes = value
		queue_redraw()

@export_group("Rendering")
@export_range(0.05, 100, 0.05, "exp", "or_greater") var vector_scale: float = 1 ## Change vectors size. This doesn't change the actual vector values
@export_range(0.1, 10, 0.1, "exp", "or_greater") var width: float = 1: ## Line width
	set(value):
		width = value
		queue_redraw()
@export var clamp_vector: bool = false ## Clamp the vector length to a max value defined below. This doesn't change the actual vector values
@export var normalize: bool = false ## Normalize vector length to max length defined below. This doesn't change the actual vector values
@export_range(0.1, 1000, 0.1, "exp", "or_greater") var max_length: float = 100 ## Max length for vector clamping or normalizing

@export_group("Colors")
@export var main_color: Color = Color.GREEN: ## Color for main vector
	set(value):
		main_color = value
		queue_redraw()
@export var x_axis_color: Color = Color.RED: ## Color for X component of vector
	set(value):
		x_axis_color = value
		queue_redraw()
@export var y_axis_color: Color = Color.BLUE: ## Color for Y component of vector
	set(value):
		y_axis_color = value
		queue_redraw()
@export var rainbow: bool = false: ## Change main vector color based on the its angle. Not aplies for axes
	set(value):
		rainbow = value
		queue_redraw()

@export_group("Color dimming")
@export var dimming: bool = false: ## Turns the vector color to a fallback one when the vector gets short
	set(value):
		dimming = value
		queue_redraw()
@export_range(0.01, 2, 0.01, "or_greater") var dimming_speed: float = 1: ## Dimming speed for all colors
	set(value):
		dimming_speed = value
		queue_redraw()
@export var fallback_color: Color = Color.BLACK: ## Color the vectors tend to when they get short
	set(value):
		fallback_color = value
		queue_redraw()
@export var dimming_if_normalized: bool = false: ## Apply dimming even when vectors are normalized
	set(value):
		dimming_if_normalized = value
		queue_redraw()

# Auxiliar variables
var current_vector := Vector2.ZERO

# Reassigns the target node or throws error when it doesn't exists
func _ready() -> void:
	if target_node == null:
		push_warning("Target node not defined. Autoassigning to parent node")
		target_node = get_parent()

	if not target_node:
		push_error("Parent node not found")
		return

	if not target_node.get(target_property) is Vector2:
		push_error("Target property is not a Vector2 or doesn't exist")

# Get the vector from given property
func _physics_process(_delta) -> void:
	if not is_instance_valid(target_node): return

	var new_vector: Vector2 = target_node.get(target_property)

	new_vector *= vector_scale
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
	draw_line(Vector2.ZERO, current_vector, colors.main, width, true)

	if not show_axes: return

	# Axes components render
	draw_line(Vector2.ZERO, Vector2(current_vector.x, 0), colors.x, width, true)
	draw_line(Vector2.ZERO, Vector2(0, current_vector.y), colors.y, width, true)

## Calculate colors based on current settings (Rainbow, Dimming, etc)
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

	if dimming and (not normalize or dimming_if_normalized):
		var length := current_vector.length()
		var dimming_value := 1.0
		if not is_zero_approx(length):
			dimming_value = clampf(dimming_speed * DIMMING_SPEED_CORRECTION / length, 0.0, 1.0)

		result.x = result.x.lerp(fallback_color, dimming_value)
		result.y = result.y.lerp(fallback_color, dimming_value)
		result.main = result.main.lerp(fallback_color, dimming_value)

	return result

# Detects shortcut to toggle visibility
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and event.is_match(SHORTCUT): show_vectors = not show_vectors
