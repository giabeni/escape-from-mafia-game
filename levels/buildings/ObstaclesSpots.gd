extends Spatial

onready var path: Path = $Path

func _ready():
	randomize()
	$Path/RandomPoint.transform.origin = get_random_point()
#
#func _process(delta):
#	if Input.is_action_just_pressed("throw"):
#		$Path/RandomPoint.transform.origin = get_random_point()
		
	
func get_random_point():
	var random_t = rand_range(0, path.curve.get_baked_length())
	return path.curve.interpolate_baked(random_t)
