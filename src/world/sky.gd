extends ColorRect
## Feeds the Palette colours to the sky shader and drifts its mist with the camera.

@export var mist_parallax := 0.00015


func _ready() -> void:
	var mat := material as ShaderMaterial
	mat.set_shader_parameter("top_color", Palette.SKY_TOP)
	mat.set_shader_parameter("glow_color", Palette.SKY_GLOW)
	mat.set_shader_parameter("bottom_color", Palette.SKY_BOTTOM)


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam:
		(material as ShaderMaterial).set_shader_parameter("scroll", cam.get_screen_center_position().x * mist_parallax)
