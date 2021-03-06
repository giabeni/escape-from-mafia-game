extends RayCast

export(NodePath) var aim_pointer_node
export(Color) var PILL_AIM_COLOR = Color("#d251c185")
export(Color) var CAPSULE_AIM_COLOR = Color("#ab0a66f7")
export(Color) var EMPTY_AIM_COLOR = Color("#d4282828")
export(Color) var ENEMY_AIM_COLOR = Color("#e2ff0000")

var aim_pointer: CSGTorus
var current_color: Color
var enemy_color = false

onready var aim_line: CSGCylinder = $AimLine
onready var aim_arrow: CSGCylinder = $AimLine/AimArrow

enum BulletType {
	PILL,
	CAPSULE,
	EMPTY,
}

func _ready():
	if aim_pointer_node:
		aim_pointer = get_node(aim_pointer_node)


func _physics_process(delta):
	
	if is_colliding():
		var point = get_collision_point()
		aim_pointer.global_transform.origin = point
		
		var distance_to_point = global_transform.origin.distance_to(point)
		aim_line.height = distance_to_point
		aim_line.translation.z = -distance_to_point / 2
		aim_arrow.translation.y = distance_to_point / 2 - 2
		
		var colider = get_collider()
		if is_instance_valid(colider) and current_color != EMPTY_AIM_COLOR and (colider as Spatial).is_in_group("Enemies"):
			enemy_color = true
			_set_color(ENEMY_AIM_COLOR)
		else:
			enemy_color = false
			_set_color(current_color)
	else:
		aim_pointer.translation = Vector3(0, 0, -200)
		aim_line.height = abs(self.cast_to.z)
		aim_line.translation.z = -aim_line.height / 2
		aim_arrow.translation.y = aim_line.height / 2 - 2
		
		_set_color(current_color)

func set_bullet_type(bullet_type):
	match bullet_type:
		BulletType.CAPSULE:
			current_color = CAPSULE_AIM_COLOR
		BulletType.PILL:
			current_color = PILL_AIM_COLOR
		BulletType.EMPTY:
			current_color = EMPTY_AIM_COLOR
	_set_color(current_color)
	

func _set_color(color):
	aim_pointer.material.albedo_color = color
	aim_line.material.albedo_color = color
	aim_arrow.material.albedo_color = color
	
	aim_pointer.material.emission = color
	aim_line.material.emission = color
	aim_arrow.material.emission = color
	
func get_aim_color():
	return ENEMY_AIM_COLOR if enemy_color else current_color
	
func get_shooting_direction(muzzle_origin: Vector3):
	if is_colliding():
		return (get_collision_point() - muzzle_origin).normalized()
	else:
		return -global_transform.basis.z.normalized()
