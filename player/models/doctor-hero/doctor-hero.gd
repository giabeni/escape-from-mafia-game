extends KinematicBody

onready var anim_tree = $AnimationTree

var gravity = Vector3.ZERO
var velocity = Vector3.ZERO


func _physics_process(delta):
	var root_motion: Transform = anim_tree.get_root_motion_transform()
	var root_velocity = (root_motion.origin) / delta
	
	velocity = root_velocity.rotated(Vector3(1, 0, 0), deg2rad(-90))
	
	print(velocity)
	
	if is_on_floor():
		print("On floor")
		gravity = Vector3.ZERO
	else:
		gravity += Vector3(0, -9.8, 0)
		
	velocity += gravity
		
	if Input.is_action_pressed("move_forward"):
		if Input.is_action_pressed("move_right"):
			anim_tree["parameters/playback"].travel("RunningRight")
		elif Input.is_action_pressed("move_left"):
			anim_tree["parameters/playback"].travel("RunningLeft")
		else:
			anim_tree["parameters/playback"].travel("Running")
	else:
		anim_tree["parameters/playback"].travel("T-Pose")
		
	if Input.is_action_just_pressed("jump"):
		anim_tree["parameters/playback"].travel("Jump")

	print("Grav vel = ", velocity)
	velocity = move_and_slide(velocity, Vector3.UP)
	
	
	if self.translation.y < -100:
		get_tree().reload_current_scene()
