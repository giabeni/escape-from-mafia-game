extends KinematicBody

onready var skeleton: Skeleton = $Armature/Skeleton
onready var IK_front_left_foot: SkeletonIK = $Armature/Skeleton/FrontLeftFootIK

onready var foot_front_left_target: Position3D = $Armature/Skeleton/Spider/FrontLeftFootTarget

onready var front_left_raycast: RayCast = $Armature/Skeleton/Spider/FrontRaycasts/LeftRayCast

var foot_front_right_target
var foot_back_left_target
var foot_back_right_target

var fixed_origin_f_l: Vector3
var fixed_origin_f_r: Vector3
var fixed_origin_b_l: Vector3
var fixed_origin_b_r: Vector3

var next_fixed_origin_f_l: Vector3
var next_fixed_origin_f_r: Vector3
var next_fixed_origin_b_l: Vector3
var next_fixed_origin_b_r: Vector3

func _ready():
	
	# Set initial origin for feet
	fixed_origin_f_l = _get_target_global_origin(foot_front_left_target)
#	fixed_origin_f_r = _get_bone_global_origin(foot_front_right_target)
#	fixed_origin_b_l = _get_bone_global_origin(foot_back_left_target)
#	fixed_origin_b_r = _get_bone_global_origin(foot_back_right_target)
	

func _physics_process(delta):
	
	# Starts handling IKs constraints
	IK_front_left_foot.start()
	
	# Moves legs linearly toward the next fixed position
	if (foot_front_left_target.global_transform.origin - next_fixed_origin_f_l).length() > 0.4:
		fixed_origin_f_l = _get_leg_movement(foot_front_left_target, fixed_origin_f_l, next_fixed_origin_f_l, delta)
	
	# Fixing feet in the ground
	_fix_foot_in_origin(foot_front_left_target, fixed_origin_f_l)
#	_fix_foot_in_origin(foot_front_right_target, fixed_origin_f_r)
#	_fix_foot_in_origin(foot_back_left_target, fixed_origin_b_l)
#	_fix_foot_in_origin(foot_back_right_target, fixed_origin_b_r)

	# Getting the next target points for all feet
	var next_point_f_l = _get_next_target_point(front_left_raycast)
	
	# Checking distance from feet to their next target
	if next_point_f_l != null:
		if _get_foot_distance_to_next_point(foot_front_left_target, next_point_f_l) > 1.5:
			# Set next fixed position
			next_fixed_origin_f_l = next_point_f_l
	
	# Move
	move_and_slide(Vector3(0, 0, -2))


func _get_target_global_origin(target: Position3D):
	return target.global_transform.origin


func _fix_foot_in_origin(foot_target: Position3D, global_origin: Vector3):
#	var pose: Transform = skeleton.get_bone_global_pose(foot_bone_id)
#	pose.origin.y = 0
#	skeleton.set_bone_global_pose_override(foot_bone_id, pose, 1, true)
	foot_target.global_transform.origin = global_origin


func _get_next_target_point(raycast: RayCast):
	if raycast.is_colliding():
		var point = raycast.get_collision_point()
		raycast.get_node("Point").global_transform.origin = point
		
		return point
	else:
		return null
		
func _get_foot_distance_to_next_point(foot_target: Position3D, next_point: Vector3):
	var foot_h_origin = Vector2(foot_target.global_transform.origin.x, foot_target.global_transform.origin.z)
	var next_point_h_origin = Vector2(next_point.x, next_point.z)
	
	return foot_h_origin.distance_to(next_point_h_origin)
	
func _get_leg_movement(foot_target, previous_origin, next_origin, delta):
	var foot_origin = foot_target.global_transform.origin
	
	var total_distance_from_steps = (Vector2(next_origin.x, next_origin.z) - Vector2(previous_origin.x, previous_origin.z)).length()
	var cur_distance_from_prev =  (Vector2(foot_origin.x, foot_origin.z) - Vector2(previous_origin.x, previous_origin.z)).length()
	var y_offset = delta * cur_distance_from_prev * (-cur_distance_from_prev - total_distance_from_steps) + 2
	
	next_origin.y = foot_origin.y + y_offset
	var next_interpolated_origin = foot_origin  + (next_origin - foot_origin).normalized() * delta * 10
	
	return next_interpolated_origin
