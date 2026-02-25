extends Node2D

## Node to show its vectors
@export var target_node: Node
## Name of the Vector2 attribute or variable in node's script
@export var target_property: String = "velocity"
## Vector display settings. Create your own using a [code]VectorDisplaySettings[/code] resource
@export var settings: VectorDisplaySettings

# Auxiliar variables
var current_vector := Vector2.ZERO
var current_raw_length := 0.0

# Reassigns the target node or throws error when it doesn't exists
func _ready() -> void:
	if target_node == null:
		push_warning("[VectorDisplay2D] Target node not defined. Autoassigning to parent node")
		target_node = get_parent()

	if not target_node:
		push_error("[VectorDisplay2D] Target node not found")
		return

	if not target_node.get(target_property) is Vector2:
		push_error("[VectorDisplay2D] Target property is not a Vector2 or doesn't exist")
		return

	if not settings:
		push_error("[VectorDisplay2D] Settings not defined")
		return

	# Redraw automatically when settings change
	settings.changed.connect(queue_redraw)

# Get and process the vector from given property
func _process(_delta) -> void:
	if not is_instance_valid(target_node): return

	var new_vector: Vector2 = target_node.get(target_property) * settings.vector_scale
	var new_raw_length := new_vector.length()

	if settings.normalize: new_vector = new_vector.normalized() * settings.max_length
	if settings.clamp_vector: new_vector = new_vector.limit_length(settings.max_length)

	# Improves performance, rendering only when is necesary
	if current_vector == new_vector and is_equal_approx(current_raw_length, new_raw_length): return

	current_vector = new_vector
	current_raw_length = new_raw_length
	queue_redraw()

# Draw the vectors
func _draw() -> void:
	if not settings.show_vectors: return

	var colors := VectorDisplayFunctions.calculate_draw_colors(current_vector, current_raw_length, settings)

	# Main vector calculations and render, according to mode
	var current_vector_position := VectorDisplayFunctions.get_main_vector_position(current_vector, settings)
	draw_line(current_vector_position.begin, current_vector_position.end, colors.main, settings.width, true)
	_draw_arrowhead(current_vector_position.begin, current_vector_position.end, colors.main)

	if not settings.show_axes: return

	# Axes calculations and render, according to mode
	var current_axes_position := _get_axes_positions()

	# Components render
	draw_line(current_axes_position.x_begin, current_axes_position.x_end, colors.x, settings.width, true)
	_draw_arrowhead(current_axes_position.x_begin, current_axes_position.x_end, colors.x)
	draw_line(current_axes_position.y_begin, current_axes_position.y_end, colors.y, settings.width, true)
	_draw_arrowhead(current_axes_position.y_begin, current_axes_position.y_end, colors.y)

## Calculates axes position based on pivot modes
func _get_axes_positions() -> Dictionary:
	var axes := {
		"x_begin": Vector2.ZERO,
		"x_end": Vector2.ZERO,
		"y_begin": Vector2.ZERO,
		"y_end": Vector2.ZERO
	}

	if settings.axes_pivot_mode == "Normal" and settings.pivot_mode == "Centered":
		axes.x_begin = - Vector2(current_vector.x / 2, current_vector.y / 2)
		axes.x_end = Vector2(current_vector.x / 2, -current_vector.y / 2)
		axes.y_begin = - Vector2(current_vector.x / 2, current_vector.y / 2)
		axes.y_end = Vector2(-current_vector.x / 2, current_vector.y / 2)
	elif settings.axes_pivot_mode == "Normal" or (settings.pivot_mode == "Normal" and settings.axes_pivot_mode == "Same"):
		axes.x_begin = Vector2.ZERO
		axes.x_end = Vector2(current_vector.x, 0)
		axes.y_begin = Vector2.ZERO
		axes.y_end = Vector2(0, current_vector.y)
	elif settings.axes_pivot_mode == "Centered" or (settings.pivot_mode == "Centered" and settings.axes_pivot_mode == "Same"):
		axes.x_begin = - Vector2(current_vector.x / 2, 0)
		axes.x_end = Vector2(current_vector.x / 2, 0)
		axes.y_begin = - Vector2(0, current_vector.y / 2)
		axes.y_end = Vector2(0, current_vector.y / 2)

	return axes

## Draws arrowhead for vector, given positions, size and color
func _draw_arrowhead(start: Vector2, position: Vector2, color: Color) -> void:
	if not settings.arrowhead: return

	var director := (position - start).normalized()
	var actual_size := settings.width * settings.arrowhead_size * 2

	# Adds a extra lenght for fix bad rendering or arrowhead
	var offset := director * settings.width * settings.arrowhead_size

	# Hides arrowhead if vector is very small. If not, continue
	if offset.length() > (position - start).length(): return
	var actual_position := position + offset

	draw_polygon(
		# Rotate 30 degrees to both sides
		PackedVector2Array([
			actual_position,
			actual_position - director.rotated(PI / 6) * actual_size,
			actual_position - director.rotated(-PI / 6) * actual_size
		]),
		PackedColorArray([color, color, color])
	)

# Detects shortcut to toggle visibility. Avoid concurrency and echo errors
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo() and event.is_match(settings.SHORTCUT):
		settings.show_vectors = not settings.show_vectors
		get_viewport().set_input_as_handled()
