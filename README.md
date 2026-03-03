# Vector Display 2D
Inspired by [Easy Vector Display](https://github.com/neropatti/easy_vector_display) by neropatti.

Show vectors on your 2D game with ease, customization and good performance. Some examples:

![demo image](demo_content/demo.png)
![demo image 2](demo_content/demo_2.png)

## Usage
- Create a new `VectorDisplay2D` node on your scene
- Choose a target node and a property on it (e.g.: velocity) of type **Vector2**
- Customize and setup colors, scale, and behaviours, even on runtime, using a `VectorDisplay2DSettings` resource
- Enjoy! Use `Shift + V` to quickly toggle visibility during runtime
- Change the visibility shortcut on [`display shortcut file`](addons/vector_display_2d/display_shortcut.tres) on **Godot editor**
- Save presets and share them easily

## New functions (v1.4)
- Arrowheads
- Now you can save presets on VectorDisplaySettings resources
- Less options but more intuitive to do the same and more!

## Planned features
- Performance improvements
- Batch rendering for vector arrays (v2)
- 3D compatibility (v2)
- Autoload access and utilities (if needed, v2 or v3 even)
