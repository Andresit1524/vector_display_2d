## Class for abstract (pure logical) functions for VectorDisplay. Used on both 2D and (future) 3D versions
class_name VectorDisplayFunctions extends RefCounted


#region Initial verifications


## Check the target node, its property value and settings resource
static func check_targets_and_settings(self_node: Node, target_node: Node, target_property: String, settings: VectorDisplaySettings):
	if target_node == null:
		push_warning("[VectorDisplay] Target node not defined. Autoassigning to parent node")
		target_node = self_node.get_parent()

	if not target_node:
		push_error("[VectorDisplay] Target node not found")
		return

	if not target_node.get(target_property) is Vector2:
		push_error("[VectorDisplay] Target property is not a Vector2 or doesn't exist")
		return

	if not settings:
		push_error("[VectorDisplay] Settings not defined")
		return


## Process a vector to apply lenght mode
static func apply_lenght_mode(vector, settings: VectorDisplaySettings):
	match settings.length_mode:
		"Clamp": return vector.limit_length(settings.max_length)
		"Normalize": return vector.normalized() * settings.max_length
		"Normal": return vector

	return null


## Auxiliar: check vector type
static func _is_vector_type(vector) -> bool:
	if vector is Vector2 or vector is Vector3: return true

	push_error("[VectorDisplay] Vector property has not a vector type")
	return false


#endregion


#region Colors


## Class for store rendering colors, packed to be more efficient and clean
class VDColors:
	var main: Color
	var x: Color
	var y: Color
	var z: Color

	func _init(main := Color.BLACK, x := Color.BLACK, y := Color.BLACK, z := Color.BLACK) -> void:
		self.main = main
		self.x = x
		self.y = y
		self.z = z


## Calculate colors based on current settings (Rainbow, Dimming, etc)
static func calculate_draw_colors(vector, current_raw_length: float, settings: VectorDisplaySettings) -> VDColors:
	var colors := VDColors.new(
		settings.main_color,
		settings.x_axis_color,
		settings.y_axis_color,
		settings.z_axis_color
	)

	# Check type, throws error or add new color for 3D if necessary
	if not _is_vector_type(vector): return colors

	# Color rainbow
	if settings.rainbow:
		var angle: float = vector.angle()
		if angle < 0: angle += TAU

		colors.main = Color.from_hsv(angle / TAU, 1.0, 1.0)

	# Color dimming
	if settings.dimming and (not settings.length_mode == "Normalize" or settings.normalized_dimming_type != "None"):
		var length: float = vector.length()
		match settings.normalized_dimming_type:
			"Absolute": length = current_raw_length
			"Visual": length = vector.length()

		var dimming_value := 1.0
		if not is_zero_approx(length):
			dimming_value = clampf(settings.dimming_intensity * settings.DIMMING_INTENSITY_CORRECTION / length, 0.0, 1.0)

		colors.x = colors.x.lerp(settings.fallback_color, dimming_value)
		colors.y = colors.y.lerp(settings.fallback_color, dimming_value)
		colors.z = colors.z.lerp(settings.fallback_color, dimming_value)
		colors.main = colors.main.lerp(settings.fallback_color, dimming_value)

	return colors


#endregion


#region Positions


## Class for store rendering positions, either from the main vector or its components
class VDPosition:
	var begin: Vector2
	var end: Vector2
	var x_begin: Vector2
	var x_end: Vector2
	var y_begin: Vector2
	var y_end: Vector2
	var z_begin: Vector3
	var z_end: Vector3


## Calculate main vector position based on pivot mode
static func get_main_vector_position(vector, settings: VectorDisplaySettings) -> VDPosition:
	var current_vector := VDPosition.new()

	# Check type, throws error or add new position for 3D if necessary
	if not _is_vector_type(vector): return current_vector

	match settings.pivot_mode:
		"Normal":
			# The rest of calculations can be made directly without worring for type
			current_vector.begin = Vector2.ZERO if vector is Vector2 else Vector3.ZERO
			current_vector.end = vector
		"Centered":
			current_vector.begin = - vector / 2
			current_vector.end = vector / 2

	return current_vector


## Calculates axes position based on pivot modes
static func get_axes_positions(vector, settings: VectorDisplaySettings) -> VDPosition:
	var axes := VDPosition.new()

	# Check type, throws error or add new axes for 3D if necessary
	if not _is_vector_type(vector): return axes
	if vector is Vector3:
		axes.z_begin = Vector3.ZERO
		axes.z_end = Vector3.ZERO

	# Special case: Centered and Normal Axis
	# Takes the normal axes ends and then substracts half of original vector
	if settings.axes_pivot_mode == "Normal" and settings.pivot_mode == "Centered":
		axes.x_begin = - vector / 2
		axes.x_end = (Vector2(vector.x, 0) if vector is Vector2 else Vector3(vector.x, 0, 0)) - vector / 2
		axes.y_begin = - vector / 2
		axes.y_end = (Vector2(0, vector.y) if vector is Vector2 else Vector3(0, vector.y, 0)) - vector / 2

		if vector is Vector3:
			axes.z_begin = - vector / 2
			axes.z_end = Vector3(0, 0, vector.z) - vector / 2

		return axes

	# Normal setting: takes the normal components
	if settings.axes_pivot_mode == "Normal" or (settings.pivot_mode == "Normal" and settings.axes_pivot_mode == "Same"):
		axes.x_begin = Vector2.ZERO if vector is Vector2 else Vector3.ZERO
		axes.x_end = Vector2(vector.x, 0) if vector is Vector2 else Vector3(vector.x, 0, 0)
		axes.y_begin = Vector2.ZERO if vector is Vector2 else Vector3.ZERO
		axes.y_end = Vector2(0, vector.y) if vector is Vector2 else Vector3(0, vector.y, 0)

		if vector is Vector3:
			axes.z_begin = Vector3.ZERO
			axes.z_end = Vector3(0, 0, vector.z)

		return axes

	# Centered setting: center all axes (- axis / 2, axis / 2)
	if settings.axes_pivot_mode == "Centered" or (settings.pivot_mode == "Centered" and settings.axes_pivot_mode == "Same"):
		axes.x_begin = - Vector2(vector.x / 2, 0) if vector is Vector2 else -Vector3(vector.x / 2, 0, 0)
		axes.x_end = Vector2(vector.x / 2, 0) if vector is Vector2 else Vector3(vector.x / 2, 0, 0)
		axes.y_begin = - Vector2(0, vector.y / 2) if vector is Vector2 else -Vector3(0, vector.y / 2, 0)
		axes.y_end = Vector2(0, vector.y / 2) if vector is Vector2 else Vector3(0, vector.y / 2, 0)

		if vector is Vector3:
			axes.z_begin = - Vector3(0, 0, vector.z / 2)
			axes.z_end = Vector3(0, 0, vector.z / 2)

		return axes

	# Just for avoid errors
	return axes


#endregion


#region Input


## Check for shortcut to toggle visibility. Returns true if handled
static func check_shortcut(event: InputEvent, settings: VectorDisplaySettings) -> bool:
	if event.is_pressed() and not event.is_echo() and event.is_match(settings.SHORTCUT):
		settings.show_vectors = not settings.show_vectors
		return true
	return false


#endregion
