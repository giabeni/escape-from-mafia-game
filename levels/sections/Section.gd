extends Spatial

class_name Section

export(int) var DIFFICULTY = 1
export(Array, float) var ALLOWED_ANGLES = [0, 90, -90, 180]

export(PackedScene) var ENEMY_SCENE: PackedScene = null
export(PackedScene) var OBSTACLE_SCENE: PackedScene = null
export(PackedScene) var PILL_SCENE: PackedScene = preload("res://items/pill.tscn")

export(int, -1, 10) var WALLS_SURFACE = -1
export(int, -1, 10) var ROOF_SURFACE = -1
export(int, -1, 10) var GLASS_SURFACE = -1
export(int, -1, 10) var DETAIL_SURFACE = -1
export(Array, NodePath) var WALLS_BODIES = [null]
export(Array, NodePath) var ROOFS_BODIES = [null]

export(bool) var IS_START_POINT = false

export(float) var DELETE_DISTANCE: float = 80
export(float) var CURVATURE_START_DISTANCE: float = 350
export(float, 0, 360) var CURVATURE_ANGLE: float = 70
export(NodePath) var CAMERA_PATH = null

export(float, -100, 100) var LEFT_LANE_LIMIT = -15 
export(float, -100, 100) var RIGHT_LANE_LIMIT = 15
export(float, -100, 100) var LANE_INTERVAL = 5
export(float, -100, 100) var LANE_HEIGHT = 3
export(float, -100, 100) var LANE_CHANGE_PROB = 0.4

var camera: Camera
var walls: Array
var roofs: Array
var initial_rotation: Vector3
var pills_count = 0
var item: Spatial = null
var global_origin: Vector3

enum Materials {
	WALLS,
	ROOF,
	DETAIL,
	GLASS,
}

onready var enemy_spots = $EnemySpots

func _ready():
	
	initial_rotation = rotation
	
	if global_origin:
		global_transform.origin = global_origin
	
	if is_instance_valid(ENEMY_SCENE) and is_instance_valid(enemy_spots):
		call_deferred("spawn_enemy")
		
	if CAMERA_PATH:
		camera = get_node(CAMERA_PATH)
	
	for wall in WALLS_BODIES:
		if wall is NodePath:
			walls.append(get_node(wall))
	
	for roof in ROOFS_BODIES:
		if roof is NodePath:
			roofs.append(get_node(roof))
			
	if IS_START_POINT:
		if has_node("Obstacles"):
			$Obstacles.queue_free()
		if has_node("ItemsPath"):
			$ItemsPath.queue_free()
		
	if pills_count or is_instance_valid(item):
		add_pills(pills_count, item)
		
	if OBSTACLE_SCENE:
		var obstacle = OBSTACLE_SCENE.instance() as Spatial
		if has_node("ObstaclesSpots"):
			var obstacles_spots = $ObstaclesSpots
			var random_point = $ObstaclesSpots.get_node("Path/RandomPoint")
			obstacles_spots.get_node("Path").call_deferred("add_child", obstacle)
			obstacle.translation = random_point.translation

func _process(delta):
	if is_instance_valid(camera):
		var distance_to_camera = global_transform.origin - camera.global_transform.origin
		var angle = 0
		if not is_nan(distance_to_camera.z / CURVATURE_START_DISTANCE):
			angle = CURVATURE_ANGLE * pow(distance_to_camera.z / CURVATURE_START_DISTANCE, 2) * 1.2
		global_transform.origin.x = distance_to_camera.z * tan(deg2rad(CURVATURE_ANGLE)) * 0.01
		rotation.y = initial_rotation.y + deg2rad(angle)
#			if name == "Section 14":
#				print("Dist = ", distance_to_camera.z)
#				print(name, " ", translation.x, " ", rotation.y)
#		else:
#			translation.x = 0
#			rotation = initial_rotation
		if distance_to_camera.z > DELETE_DISTANCE:
			call_deferred("queue_free")

func set_global_origin(origin):
	global_origin = origin
	
func set_camera_node(path: NodePath):
	CAMERA_PATH = path
	
func set_enemy(scene: PackedScene):
	ENEMY_SCENE = scene

func set_obstacle(scene: PackedScene):
	OBSTACLE_SCENE = scene
	
func spawn_enemy():
	var spots = enemy_spots.get_children()
#	print (get_instance_id(), "   => SECTION ENEMY SPOTS = ", spots)
	var enemy = ENEMY_SCENE.instance() as Spatial
	
	
	if enemy.type == "balloon":
		enemy.transform.origin = spots[0].transform.origin
		enemy_spots.add_child(enemy)
		enemy.set_spots(spots)
	elif enemy.type == "spiky":
		if has_node("ObstaclesSpots"):
			var obstacles_spots = $ObstaclesSpots
			var random_point = $ObstaclesSpots.get_node("Path/RandomPoint")
			obstacles_spots.get_node("Path").call_deferred("add_child", enemy)
			enemy.translation = random_point.translation
			
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
	if has_node("Obstacles"):
		return $Obstacles.get_child_count()
	else:
		return 0
		
func set_obstacle_group(show, index = 1):
	if not has_node("Obstacles"):
		return
	for group in $Obstacles.get_children():
		if group.name != str(index):
			group.call_deferred("queue_free")
						

func set_pills_count(count):
	pills_count = count

func add_pills(count: int, item_instance: Spatial):
	if not PILL_SCENE:
		return

	var x = rand_range(LEFT_LANE_LIMIT, RIGHT_LANE_LIMIT)
	var y = LANE_HEIGHT
	var z = LANE_INTERVAL * count / 2
	if $ItemsPath:
		$ItemsPath.rotation.y = rotation.y
		
	var item_index = -1
	if is_instance_valid(item_instance):
		item_index = round(rand_range(0, count))
	
	var change_lane_prob = LANE_CHANGE_PROB
	for i in range(0, count):
		if i != 0 and randf() < change_lane_prob:
			x = clamp(x + (LANE_INTERVAL if randf() < 0.5 else -LANE_INTERVAL), LEFT_LANE_LIMIT, RIGHT_LANE_LIMIT)
			change_lane_prob *= 0.5
			
		var collectable: Spatial
		if i == item_index:
			collectable = item_instance
			collectable.name = "Item_" + str(i + 1)
		else:
			collectable = PILL_SCENE.instance()
			collectable.name = "Pill_" + str(i + 1)
			
		if $ItemsPath:
			$ItemsPath.add_child(collectable)
			collectable.translate_object_local(Vector3(x, y, z))
#			print(collectable.name, " = ", collectable.translation)
		z = z - LANE_INTERVAL
			


func set_item(item_scene: PackedScene):
	item = item_scene.instance()
