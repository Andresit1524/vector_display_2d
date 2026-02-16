extends Node2D

const SHORTCUT: InputEventKey = preload("res://addons/vector_display_2d/display_shortcut.tres")

# Constant to improve dimming speed
const DIMMING_SPEED_CORRECTION := 10

@export_group("Node")
@export var target_node: Node: ## Node to show its vectors
	set(value):
		target_node = value
		queue_redraw()
@export var target_property: String = "velocity": ## Name of the Vector2 attribute or variable in node's script
	set(value):
		target_property = value
		queue_redraw()

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
@export_range(0.05, 100, 0.05, "exp", "or_greater") var vector_scale: float = 1: ## Change vectors size. This doesn't change the actual vector values
	set(value):
		vector_scale = value
		queue_redraw()
@export_range(0.1, 10, 0.1, "exp", "or_greater") var width: float = 1: ## Line width
	set(value):
		width = value
		queue_redraw()
@export var clamp_vector: bool = false: ## Clamp the vector length to a max value defined below. This doesn't change the actual vector values
	set(value):
		clamp_vector = value
		queue_redraw()
@export var normalize: bool = false: ## Normalize vector length to max length defined below. This doesn't change the actual vector values
	set(value):
		normalize = value
		queue_redraw()
@export_range(0.1, 1000, 0.1, "exp", "or_greater") var max_length: float = 100: ## Max length for vector clamping or normalizing
	set(value):
		max_length = value
		queue_redraw()
@export_enum("Normal", "Centered") var pivot_mode: String = "Normal": ## Change the pivot point. Normal: starts from origin. Centered: scales symmetrically
	set(value):
		pivot_mode = value
		queue_redraw()
@export_enum("Same", "Normal", "Centered") var axis_pivot_mode: String = "Same": ## Keep same pivot point for axes or override them. Highly recommended to keep in "Same"
	set(value):
		axis_pivot_mode = value
		queue_redraw()

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
@export_enum("Absolute", "Visual") var normalized_dimming_type: String = "Absolute": ## Apply dimming based on actual value (with scale) of vector or visual length
	set(value):
		normalized_dimming_type = value
		queue_redraw()

# Auxiliar variables
var current_vector := Vector2.ZERO
var current_raw_length := 0.0

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

	var new_vector: Vector2 = target_node.get(target_property) * vector_scale
	var new_raw_length := new_vector.length()

	if normalize: new_vector = new_vector.normalized() * max_length
	if clamp_vector: new_vector = new_vector.limit_length(max_length)

	# Improves performance rendering when necesary
	if current_vector == new_vector and is_equal_approx(current_raw_length, new_raw_length): return

	current_vector = new_vector
	current_raw_length = new_raw_length
	queue_redraw()

# Draw the vectors
func _draw() -> void:
	if not show_vectors: return

	var colors := _get_draw_colors()

	# Main vector render
	match pivot_mode:
		"Normal": draw_line(Vector2.ZERO, current_vector, colors.main, width, true)
		"Centered": draw_line(-current_vector / 2, current_vector / 2, colors.main, width, true)

	if not show_axes: return

	# Axes components calculus, according to mode
	var current_axes := {
		"x_begin": Vector2.ZERO,
		"x_end": Vector2.ZERO,
		"y_begin": Vector2.ZERO,
		"y_end": Vector2.ZERO
	}

	if axis_pivot_mode == "Normal" and pivot_mode == "Centered":
		current_axes.x_begin = - Vector2(current_vector.x / 2, current_vector.y / 2)
		current_axes.x_end = Vector2(current_vector.x / 2, -current_vector.y / 2)
		current_axes.y_begin = - Vector2(current_vector.x / 2, current_vector.y / 2)
		current_axes.y_end = Vector2(-current_vector.x / 2, current_vector.y / 2)
	elif axis_pivot_mode == "Normal" or (pivot_mode == "Normal" and axis_pivot_mode == "Same"):
		current_axes.x_begin = Vector2.ZERO
		current_axes.x_end = Vector2(current_vector.x, 0)
		current_axes.y_begin = Vector2.ZERO
		current_axes.y_end = Vector2(0, current_vector.y)
	elif axis_pivot_mode == "Centered" or (pivot_mode == "Centered" and axis_pivot_mode == "Same"):
		current_axes.x_begin = - Vector2(current_vector.x / 2, 0)
		current_axes.x_end = Vector2(current_vector.x / 2, 0)
		current_axes.y_begin = - Vector2(0, current_vector.y / 2)
		current_axes.y_end = Vector2(0, current_vector.y / 2)

	# Axis draw
	draw_line(current_axes.x_begin, current_axes.x_end, colors.x, width, true)
	draw_line(current_axes.y_begin, current_axes.y_end, colors.y, width, true)

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
		var length: float
		match normalized_dimming_type:
			"Absolute": length = current_raw_length
			"Visual": length = current_vector.length()

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
