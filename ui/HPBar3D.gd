extends Spatial

class_name HPBar3D

onready var progress_bar: ProgressBar = $Viewport/HPBar

export(Color) var fg_color = "#245500"
export(float) var max_hp: float = 100
var current_hp = 100

func _ready():
	progress_bar.max_value = max_hp
	
func set_current_hp(hp: float):
	progress_bar.value = hp
