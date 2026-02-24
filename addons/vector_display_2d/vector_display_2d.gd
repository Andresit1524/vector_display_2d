extends Node2D

## Node to show its vectors
@export var target_node: Node
## Name of the Vector2 attribute or variable in node's script
@export var target_property: String = "velocity"
## Display settings. Create your own using [code]VectorDisplaySettings[/code] resource class
@export var settings: VectorDisplaySettings

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

	# Redraw when settings change
	settings.changed.connect(queue_redraw)

# Get the vector from given property
func _process(_delta) -> void:
	if not is_instance_valid(target_node): return

	var new_vector: Vector2 = target_node.get(target_property) * settings.vector_scale
	var new_raw_length := new_vector.length()

	if settings.normalize: new_vector = new_vector.normalized() * settings.max_length
	if settings.clamp_vector: new_vector = new_vector.limit_length(settings.max_length)

	# Improves performance rendering when necesary
	if current_vector == new_vector and is_equal_approx(current_raw_length, new_raw_length): return

	current_vector = new_vector
	current_raw_length = new_raw_length
	queue_redraw()

# Draw the vectors
func _draw() -> void:
	if not settings.show_vectors: return

	var colors := _get_draw_colors()

	# Main vector calculos and render, according to mode
	var current_vector_position := _get_main_vector_position()
	draw_line(current_vector_position.begin, current_vector_position.end, colors.main, settings.width, true)
	_draw_decorators(current_vector_position.end, settings.width * 3, colors.main)

	if not settings.show_axes: return

	# Axes components calculus, according to mode
	var current_axes_position := _get_axes_position()

	# Axis render
	draw_line(current_axes_position.x_begin, current_axes_position.x_end, colors.x, settings.width, true)
	_draw_decorators(current_axes_position.x_end, settings.width * 3, colors.x)
	draw_line(current_axes_position.y_begin, current_axes_position.y_end, colors.y, settings.width, true)
	_draw_decorators(current_axes_position.y_end, settings.width * 3, colors.y)

## Calculate colors based on current settings (Rainbow, Dimming, etc)
func _get_draw_colors() -> Dictionary:
	var colors := {
		"main": settings.main_color,
		"x": settings.x_axis_color,
		"y": settings.y_axis_color
	}

	if settings.rainbow:
		var angle := current_vector.angle()
		if angle < 0: angle += TAU

		colors.main = Color.from_hsv(angle / TAU, 1.0, 1.0)

	if settings.dimming and (not settings.normalize or settings.normalized_dimming_type != "None"):
		var length: float = current_vector.length()
		match settings.normalized_dimming_type:
			"Absolute": length = current_raw_length
			"Visual": length = current_vector.length()

		var dimming_value := 1.0
		if not is_zero_approx(length):
			dimming_value = clampf(settings.dimming_speed * settings.DIMMING_SPEED_CORRECTION / length, 0.0, 1.0)

		colors.x = colors.x.lerp(settings.fallback_color, dimming_value)
		colors.y = colors.y.lerp(settings.fallback_color, dimming_value)
		colors.main = colors.main.lerp(settings.fallback_color, dimming_value)

	return colors

## Calculate main vector position based on pivot mode
func _get_main_vector_position() -> Dictionary:
	var main_vector := {
		"begin": Vector2.ZERO,
		"end": Vector2.ZERO
	}

	match settings.pivot_mode:
		"Normal":
			main_vector.begin = Vector2.ZERO
			main_vector.end = current_vector
		"Centered":
			main_vector.begin = - current_vector / 2
			main_vector.end = current_vector / 2

	return main_vector

## Calculates axes position based on pivot modes
func _get_axes_position() -> Dictionary:
	var axes := {
		"x_begin": Vector2.ZERO,
		"x_end": Vector2.ZERO,
		"y_begin": Vector2.ZERO,
		"y_end": Vector2.ZERO
	}

	if settings.axis_pivot_mode == "Normal" and settings.pivot_mode == "Centered":
		axes.x_begin = - Vector2(current_vector.x / 2, current_vector.y / 2)
		axes.x_end = Vector2(current_vector.x / 2, -current_vector.y / 2)
		axes.y_begin = - Vector2(current_vector.x / 2, current_vector.y / 2)
		axes.y_end = Vector2(-current_vector.x / 2, current_vector.y / 2)
	elif settings.axis_pivot_mode == "Normal" or (settings.pivot_mode == "Normal" and settings.axis_pivot_mode == "Same"):
		axes.x_begin = Vector2.ZERO
		axes.x_end = Vector2(current_vector.x, 0)
		axes.y_begin = Vector2.ZERO
		axes.y_end = Vector2(0, current_vector.y)
	elif settings.axis_pivot_mode == "Centered" or (settings.pivot_mode == "Centered" and settings.axis_pivot_mode == "Same"):
		axes.x_begin = - Vector2(current_vector.x / 2, 0)
		axes.x_end = Vector2(current_vector.x / 2, 0)
		axes.y_begin = - Vector2(0, current_vector.y / 2)
		axes.y_end = Vector2(0, current_vector.y / 2)

	return axes

## Draws decorator for vector, let given position
func _draw_decorators(decorator_position: Vector2, size: float, color: Color) -> void:
	if not settings.decorator: return

	# TODO: Make ts

# Detects shortcut to toggle visibility. Avoid concurrency and echo errors
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo() and event.is_match(settings.SHORTCUT):
		settings.show_vectors = not settings.show_vectors
		get_viewport().set_input_as_handled()
