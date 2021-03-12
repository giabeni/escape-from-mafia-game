extends Spatial

export(String) var SCORE = "+100"
export(Color) var outline_color = "#000000"
export(Color) var fill_color = "#ffffff"

func _ready():
	$Viewport.size = $Viewport/Label.rect_size * 1.2
	$Viewport/Label.add_color_override("font_color", fill_color)
	$Viewport/Label.get_font("font").outline_color = outline_color
	$Viewport/Label.text = SCORE
	
func pop_up():
	show()
#	var viewport_texture = ViewportTexture.new()
#	viewport_texture.viewport_path = "Viewport"
#	texture = viewport_texture
