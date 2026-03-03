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
	VectorDisplayFunctions.check_targets_and_settings(self , target_node, target_property, settings)

	# Redraw automatically when settings change
	settings.changed.connect(queue_redraw)


# Get and process the vector from given property
func _process(_delta) -> void:
	if not is_instance_valid(target_node): return

	var new_vector: Vector2 = target_node.get(target_property) * settings.vector_scale
	var new_raw_length := new_vector.length()

	new_vector = VectorDisplayFunctions.apply_lenght_mode(new_vector, settings)

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
	var current_axes_pos := VectorDisplayFunctions.get_axes_positions(current_vector, settings)

	# Components render
	draw_line(current_axes_pos.x_begin, current_axes_pos.x_end, colors.x, settings.width, true)
	_draw_arrowhead(current_axes_pos.x_begin, current_axes_pos.x_end, colors.x)
	draw_line(current_axes_pos.y_begin, current_axes_pos.y_end, colors.y, settings.width, true)
	_draw_arrowhead(current_axes_pos.y_begin, current_axes_pos.y_end, colors.y)


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
	if VectorDisplayFunctions.check_shortcut(event, settings):
		get_viewport().set_input_as_handled()
