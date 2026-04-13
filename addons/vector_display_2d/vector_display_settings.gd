@icon("res://addons/vector_display_2d/icon.svg")
class_name VectorDisplaySettings extends Resource


enum LenghtModes {
	NORMAL,
	CLAMP,
	NORMALIZE,
}

enum PivotModes {
	NORMAL,
	CENTERED,
}

enum AxesPivotModes {
	SAME,
	NORMAL,
	CENTERED,
}

enum DimmingTypes {
	VISUAL,
	ABSOLUTE,
}


const SHORTCUT: InputEventKey = preload("res://addons/vector_display_2d/display_shortcut.tres")
const DIMMING_INTENSITY_CORRECTION := 10.0


## Show or hide all vectors
@export var show_vectors: bool = true:
	set(value):
		show_vectors = value
		changed.emit()
## Shows X and Y component for the vector
@export var show_axes: bool = false:
	set(value):
		show_axes = value
		changed.emit()


@export_group("Aspect")

## Change vectors size. This doesn't change the actual vector values
@export_range(0.05, 100, 0.05, "exp", "or_greater") var vector_scale: float = 1:
	set(value):
		vector_scale = value
		changed.emit()
## Line width in pixels
@export_range(0.1, 10, 0.1, "exp", "or_greater") var width: float = 2:
	set(value):
		width = value
		changed.emit()
## Change the displayed vector length. Both clamp and normalize doesn´t change the actual vector values
@export var length_mode: LenghtModes = LenghtModes.NORMAL:
	set(value):
		length_mode = value
		changed.emit()
## Max length for vector clamping or normalizing
@export_range(0.1, 1000, 0.1, "exp", "or_greater") var max_length: float = 100:
	set(value):
		max_length = value
		changed.emit()
## Add a arrowhead for vectors
@export var arrowhead: bool = true:
	set(value):
		arrowhead = value
		changed.emit()
## Arrowhead size. Each unit is equivalent to 2 times vector width
@export_range(0.1, 10, 0.1, "exp", "or_greater") var arrowhead_size: float = 3.0:
	set(value):
		arrowhead_size = value
		changed.emit()
## Change the pivot point. Normal: starts from origin. Centered: scales symmetrically
@export var pivot_mode: PivotModes = PivotModes.NORMAL:
	set(value):
		pivot_mode = value
		changed.emit()
## Keep same pivot point for axes or override them. Highly recommended to keep in "Same"
@export var axes_pivot_mode: AxesPivotModes = AxesPivotModes.SAME:
	set(value):
		axes_pivot_mode = value
		changed.emit()


@export_group("Colors")

## Color for main vector
@export var main_color: Color = Color.YELLOW:
	set(value):
		main_color = value
		changed.emit()
## Color for X component of vector
@export var x_axis_color: Color = Color.RED:
	set(value):
		x_axis_color = value
		changed.emit()
## Color for Y component of vector
@export var y_axis_color: Color = Color.GREEN:
	set(value):
		y_axis_color = value
		changed.emit()
## Color for Z component of vector. Currently not supported
@export var z_axis_color: Color = Color.BLUE:
	set(value):
		z_axis_color = value
		changed.emit()
## Change main vector color based on the its angle. Not aplies for axes
@export var rainbow: bool = false:
	set(value):
		rainbow = value
		changed.emit()


@export_group("Color dimming")

## Turns the vector color to a fallback one when the vector gets short
@export var dimming: bool = false:
	set(value):
		dimming = value
		changed.emit()
## Dimming speed for all colors
@export_range(0.01, 10, 0.01, "or_greater") var dimming_intensity: float = 1:
	set(value):
		dimming_intensity = value
		changed.emit()
## Color the vectors tend to when they get short
@export var fallback_color: Color = Color.BLACK:
	set(value):
		fallback_color = value
		changed.emit()
## Apply dimming based on visual length or actual value of vector (with scale)
@export var dimming_type: DimmingTypes = DimmingTypes.VISUAL:
	set(value):
		dimming_type = value
		changed.emit()
