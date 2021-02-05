extends Spatial

class_name Section

export(int) var DIFFICULTY = 1
export(PackedScene) var ENEMY_SCENE = null
export(Array, float) var ALLOWED_ANGLES = [0, 90, -90, 180]

onready var enemy_spots = $EnemySpots

func _ready():
	if is_instance_valid(ENEMY_SCENE) and is_instance_valid(enemy_spots):
		call_deferred("spawn_enemy")
	
func set_enemy(scene: PackedScene):
	ENEMY_SCENE = scene
	
func spawn_enemy():
	var spots = enemy_spots.get_children()
#	print (get_instance_id(), "   => SECTION ENEMY SPOTS = ", spots)
	var enemy = ENEMY_SCENE.instance() as Spatial
	
	enemy.transform.origin = spots[0].transform.origin
	
	enemy_spots.add_child(enemy)
	enemy.set_spots(spots)
