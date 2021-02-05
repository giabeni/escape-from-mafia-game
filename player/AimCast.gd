extends RayCast

export(NodePath) var aim_pointer_node
export(Color) var NORMAL_AIM_COLOR = Color("#d251c185")
export(Color) var ENEMY_AIM_COLOR = Color("#e2ff0000")

var aim_pointer: CSGTorus

onready var aim_line: CSGCylinder = $AimLine
onready var aim_arrow: CSGCylinder = $AimLine/AimArrow

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
		if is_instance_valid(colider) and (colider as Spatial).is_in_group("Enemies"):
			_set_color(ENEMY_AIM_COLOR)
		else:
			_set_color(NORMAL_AIM_COLOR)
	else:
		aim_pointer.translation = Vector3(0, 0, -200)
		aim_line.height = abs(self.cast_to.z)
		aim_line.translation.z = -aim_line.height / 2
		aim_arrow.translation.y = aim_line.height / 2 - 2
		
		_set_color(NORMAL_AIM_COLOR)

func _set_color(color):
	aim_pointer.material.albedo_color = color
	aim_line.material.albedo_color = color
	aim_arrow.material.albedo_color = color
