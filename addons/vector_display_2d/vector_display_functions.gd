## Class for abstract (pure logical) functions for VectorDisplay. Used on both 2D and (future) 3D versions
class_name VectorDisplayFunctions extends RefCounted

## Calculate colors based on current settings (Rainbow, Dimming, etc)
static func calculate_draw_colors(vector, current_raw_length: float, settings: VectorDisplaySettings) -> Dictionary:
	var colors := {
		"main": settings.main_color,
		"x": settings.x_axis_color,
		"y": settings.y_axis_color
	}

	# Check type, throws error or add new color for 3D if necessary
	if not _is_vector_type(vector): return colors
	if vector is Vector3: colors["z"] = settings.z_axis_color

	# Color rainbow
	if settings.rainbow:
		var angle: float = vector.angle()
		if angle < 0: angle += TAU

		colors.main = Color.from_hsv(angle / TAU, 1.0, 1.0)

	# Color dimming
	if settings.dimming and (not settings.normalize or settings.normalized_dimming_type != "None"):
		var length: float = vector.length()
		match settings.normalized_dimming_type:
			"Absolute": length = current_raw_length
			"Visual": length = vector.length()

		var dimming_value := 1.0
		if not is_zero_approx(length):
			dimming_value = clampf(settings.dimming_speed * settings.DIMMING_SPEED_CORRECTION / length, 0.0, 1.0)

		colors.x = colors.x.lerp(settings.fallback_color, dimming_value)
		colors.y = colors.y.lerp(settings.fallback_color, dimming_value)
		if vector is Vector3: colors.z = colors.z.lerp(settings.fallback_color, dimming_value)
		colors.main = colors.main.lerp(settings.fallback_color, dimming_value)

	return colors

## Calculate main vector position based on pivot mode
static func get_main_vector_position(vector, settings) -> Dictionary:
	var current_vector := {"begin": null, "end": null}

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

## Auxiliar: check vector type
static func _is_vector_type(vector) -> bool:
	if vector is Vector2 or vector is Vector3: return true

	push_error("Vector property is not from a vector type")
	return false
