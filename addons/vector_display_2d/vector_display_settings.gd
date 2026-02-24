@icon("res://addons/vector_display_2d/icon.svg")

class_name VectorDisplaySettings extends Resource

const SHORTCUT: InputEventKey = preload("res://addons/vector_display_2d/display_shortcut.tres")
const DIMMING_SPEED_CORRECTION := 10

@export_group("Show")

## Show or hide all
@export var show_vectors: bool = true:
	set(value):
		show_vectors = value
		print_debug("Visibility changed")

## Shows X and Y component for the vector
@export var show_axes: bool = false


@export_group("Rendering")

## Change vectors size. This doesn't change the actual vector values
@export_range(0.05, 100, 0.05, "exp", "or_greater") var vector_scale: float = 1

## Line width
@export_range(0.1, 10, 0.1, "exp", "or_greater") var width: float = 1

## Clamp vector length to a max value defined below. This doesn't change the actual vector values
@export var clamp_vector: bool = false

## Normalize vector length to max length defined below. This doesn't change the actual vector values
@export var normalize: bool = false

## Max length for vector clamping or normalizing
@export_range(0.1, 1000, 0.1, "exp", "or_greater") var max_length: float = 100

## Add a decoration for vectors head. Is always a triangle
@export var decorator: bool = true

## Change the pivot point. Normal: starts from origin. Centered: scales symmetrically
@export_enum("Normal", "Centered") var pivot_mode: String = "Normal"

## Keep same pivot point for axes or override them. Highly recommended to keep in "Same"
@export_enum("Same", "Normal", "Centered") var axis_pivot_mode: String = "Same"


@export_group("Colors")

## Color for main vector
@export var main_color: Color = Color.GREEN

## Color for X component of vector
@export var x_axis_color: Color = Color.RED

## Color for Y component of vector
@export var y_axis_color: Color = Color.BLUE

## Change main vector color based on the its angle. Not aplies for axes
@export var rainbow: bool = false


@export_group("Color dimming")

## Turns the vector color to a fallback one when the vector gets short
@export var dimming: bool = false

## Dimming speed for all colors
@export_range(0.01, 10, 0.01, "or_greater") var dimming_speed: float = 1

## Color the vectors tend to when they get short
@export var fallback_color: Color = Color.BLACK

## Apply dimming based on actual value of vector (with scale) or visual length, or just choose None
@export_enum("None", "Absolute", "Visual") var normalized_dimming_type: String = "None"
