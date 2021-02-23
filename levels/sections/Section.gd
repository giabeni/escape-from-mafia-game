extends Spatial

class_name Section

export(int) var DIFFICULTY = 1
export(PackedScene) var ENEMY_SCENE = null
export(Array, float) var ALLOWED_ANGLES = [0, 90, -90, 180]
export(int, -1, 10) var WALLS_SURFACE = -1
export(int, -1, 10) var ROOF_SURFACE = -1
export(int, -1, 10) var GLASS_SURFACE = -1
export(int, -1, 10) var DETAIL_SURFACE = -1
export(Array, NodePath) var WALLS_BODIES = [null]
export(Array, NodePath) var ROOFS_BODIES = [null]
export var is_start_point = false

var walls: Array
var roofs: Array

enum Materials {
	WALLS,
	ROOF,
	DETAIL,
	GLASS,
}

onready var enemy_spots = $EnemySpots

func _ready():
	if is_instance_valid(ENEMY_SCENE) and is_instance_valid(enemy_spots):
		call_deferred("spawn_enemy")
	
	for wall in WALLS_BODIES:
		if wall is NodePath:
			walls.append(get_node(wall))
	
	for roof in ROOFS_BODIES:
		if roof is NodePath:
			roofs.append(get_node(roof))
			
	if is_start_point:
		$Obstacles.queue_free()
		$ItemsPath.queue_free()
		$PillsPaths.queue_free()
	
func set_enemy(scene: PackedScene):
	ENEMY_SCENE = scene
	
func spawn_enemy():
	var spots = enemy_spots.get_children()
#	print (get_instance_id(), "   => SECTION ENEMY SPOTS = ", spots)
	var enemy = ENEMY_SCENE.instance() as Spatial
	
	enemy.transform.origin = spots[0].transform.origin
	
	enemy_spots.add_child(enemy)
	enemy.set_spots(spots)
	
func set_surface_material(surface: int, material: SpatialMaterial):
	match surface:
		Materials.WALLS:
#			print("setting WALLS  material...", walls.size())
			if WALLS_SURFACE != -1 and walls.size() > 0:
				for wall in walls:
					if is_instance_valid(wall):
						wall.set_surface_material(WALLS_SURFACE, material)
		Materials.ROOF:
			if ROOF_SURFACE != -1 and roofs.size() > 0:
				for roof in roofs:
					if is_instance_valid(roof):
						roof.set_surface_material(ROOF_SURFACE, material)
		Materials.DETAIL:
			if DETAIL_SURFACE != -1 and walls.size() > 0:
				for wall in walls:
					if is_instance_valid(wall):
						wall.set_surface_material(DETAIL_SURFACE, material)
		Materials.GLASS:
			if GLASS_SURFACE != -1 and walls.size() > 0:
				for wall in walls:
					if is_instance_valid(wall):
						wall.set_surface_material(GLASS_SURFACE, material)
						
func get_obstacles_count():
	if $Obstacles:
		return $Obstacles.get_child_count()
	else:
		return 0
		
func set_obstacle_group(show, index = 1):
	if not $Obstacles:
		return
	for group in $Obstacles.get_children():
		if group.name != str(index):
			group.call_deferred("queue_free")
						
func get_pills_count():
	if $Obstacles:
		return $Obstacles.get_child_count()
	else:
		return 0
		
func set_pill_path(show, index = 1):
	if not $PillsPaths:
		return
	for group in $PillsPaths.get_children():
		if group.name != str(index):
			group.call_deferred("queue_free")

func set_item(show):
	if not show and $ItemsPath:
		$ItemsPath.call_deferred("queue_free")
		
		
