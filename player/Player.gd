extends KinematicBody

class_name Player

export(float) var MAX_SPEED = 20
export(float) var GRAVITY = 25
export(float) var FRONTAL_ACC = 8
export(float) var LATERAL_ACC = 15
export(float) var ANGULAR_ACC = 10
export(float) var JUMP_FORCE = 18
export(float) var MOUSE_SENSITIVITY = 5
export(float) var AIM_LIMIT = 45
export(float) var LINEAR_SPEED_FACTOR_RATE = 0.1
export(NodePath) var AIM_GIMBAL = "Gimbal"

onready var collision_shape: CollisionShape = $CollisionShape
onready var ui: UIPlayer = $PlayerUI
onready var doctor = $Doctor
onready var anim_player: AnimationPlayer = $Doctor/AnimationPlayer
onready var anim_tree: AnimationTree = $Doctor/AnimationTree
onready var camera: ClippedCamera = $Doctor/ClippedCamera
onready var infected_paricles: Particles = $Doctor/Armature/Skeleton/BoneAttachment/InfectedParticles

enum PlayerStates {
	IDLE,
	RUNNING,
	FALLING,
	STUMBLED,
	FALLEN,
}

var direction = Vector3.ZERO
var velocity = Vector3.ZERO
var resultant_velocity = Vector3.ZERO
var angle = 0
var gimbal: Spatial
var mouse_motion: Vector2 = Vector2.ZERO
var speed_factor: float = 1
var last_score_position: Vector3
var score_acc: float = 0
var game_running = false
var anim_playback: AnimationNodeStateMachinePlayback
var anim_root_motion
var jumping = false
var state = PlayerStates.IDLE


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	gimbal = get_node(AIM_GIMBAL)
	last_score_position = self.global_transform.origin
	anim_playback = anim_tree["parameters/playback"]
	anim_root_motion = anim_tree.root_motion_track
	
func _physics_process(delta):
	_get_input_direction()
	_get_jump()
	_aim(delta)

	
	if state == PlayerStates.IDLE:
		var root_motion: Transform = anim_tree.get_root_motion_transform().rotated(Vector3.RIGHT, deg2rad(-90))
		var locomotion = root_motion.origin / delta
		velocity.x = locomotion.x
		velocity.z = locomotion.z
	elif state == PlayerStates.RUNNING:
		velocity.x = lerp(velocity.x, MAX_SPEED * speed_factor * direction.x, delta * LATERAL_ACC)
		velocity.z = lerp(velocity.z, MAX_SPEED * speed_factor * direction.z, delta * FRONTAL_ACC)

	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		
	_set_rotation(delta)
	
	
	if state in [PlayerStates.RUNNING, PlayerStates.FALLING]:
		resultant_velocity = move_and_slide(velocity.rotated(Vector3.UP, self.rotation.y), Vector3.UP)
	
	_set_animations(delta)
	
	if Input.is_action_just_pressed("ui_cancel") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif Input.is_action_just_pressed("ui_cancel") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	if game_running and state == PlayerStates.RUNNING:
		_check_for_death()
		
#	if infected_paricles.emitting:
#		infected_paricles.amount = min(infected_paricles.amount + 25, 125)


func _get_input_direction():
	# Frontal direction
	if Input.is_action_just_pressed("move_forward"):
		direction.z = -1
		state = PlayerStates.RUNNING
	
	if not Input.is_action_pressed("rotate"):
		# Lateral direction
		if Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
			direction.x -= 1 
		elif Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"):
			direction.x += 1
		else:
			direction.x = 0
	else:
		# Rotation
		if Input.is_action_just_pressed("move_left") and not Input.is_action_pressed("move_right"):
			angle += deg2rad(90)
		elif Input.is_action_just_pressed("move_right") and not Input.is_action_pressed("move_left"):
			angle -= deg2rad(90)
		
	if Input.is_action_just_pressed("rotate_left") and not Input.is_action_pressed("rotate_right"):
		angle += deg2rad(90)
	elif Input.is_action_just_pressed("rotate_right") and not Input.is_action_pressed("rotate_left"):
		angle -= deg2rad(90)
		
	
	direction.x = clamp(direction.x, -1, 1)
	direction.z = clamp(direction.z, -1, 0)


func _set_rotation(delta):
	self.rotation.y = lerp_angle(rotation.y, angle, delta * ANGULAR_ACC)

func _get_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_FORCE
		jumping = true
		anim_playback.travel("JUMP")
		
	if Input.is_action_just_pressed("roll") and not is_on_floor():
		velocity.y = -JUMP_FORCE


func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion = event.relative
	
func _aim(delta):
	gimbal.rotate_y(deg2rad(-mouse_motion.x) * delta * MOUSE_SENSITIVITY)
	gimbal.rotation_degrees.y = clamp(gimbal.rotation_degrees.y, -AIM_LIMIT, AIM_LIMIT)
	mouse_motion = Vector2()
	

func _set_animations(delta):
	var strafe = "parameters/RUNNING/Strafe/blend_position"
	var speed = "parameters/RUNNING/Speed/scale"
	var jump = "parameters/RUNNING/Jump/active"

#	print(" ANIM = ", playback.get_current_node(), "  State = ", state)
	match state:
		PlayerStates.IDLE:
			anim_playback.travel("START")

		PlayerStates.RUNNING:
			if anim_playback.get_current_node() in ["FALLING_JUMP", "JUMP"]: 
				if is_on_floor():
					jumping = false
					anim_tree.root_motion_track = anim_root_motion
#					camera.add_trauma(0.05)
					anim_playback.travel("RUNNING")
				elif global_transform.origin.y < -60:
					anim_tree.root_motion_track = ""
					anim_playback.travel("FALLING")
					doctor.get_node("Armature").rotation_degrees.x += delta * 30
			elif not jumping:
				anim_tree.root_motion_track = anim_root_motion
				anim_playback.travel("RUNNING")
				anim_tree[strafe].x = velocity.x / MAX_SPEED
				anim_tree[strafe].y = -velocity.z / MAX_SPEED
				anim_tree[speed] = speed_factor
				if resultant_velocity.y < -9:
					anim_playback.travel("FALLING_JUMP")
			
			
	
	
func _check_for_death():
	
	# Death if falling
	if self.global_transform.origin.y < -240:
		state = PlayerStates.FALLING
		_die()
		
	# Death if collided and stopped
	if resultant_velocity.length() < 2:
		for i in range (0, get_slide_count() - 1):
			var collision = get_slide_collision(i)
#			print("Collision ", i, "  -  normal dot = ", collision.normal.dot(-self.global_transform.basis.z))
			if collision != null and collision.normal.dot(-self.global_transform.basis.z) < 0:
				state = PlayerStates.STUMBLED
				anim_playback.travel("STUMBLE")
				camera.add_trauma(0.2)
				var wait: GDScriptFunctionState = yield(get_tree().create_timer(4), "timeout")
				_die()


func _die():
	get_tree().call_deferred("reload_current_scene")
	

func on_Touch_Enemy():
	velocity.x = 0
	velocity.z = 0
	infected_paricles.emitting = true
	state = PlayerStates.STUMBLED
	anim_playback.travel("STUMBLE")
	camera.add_trauma(0.2)
	var wait: GDScriptFunctionState = yield(get_tree().create_timer(4), "timeout")
	_die()
	

func _on_CheckPoint_reached(body: CollisionObject):
	if body.get_instance_id() == self.get_instance_id():
		speed_factor += LINEAR_SPEED_FACTOR_RATE


func _on_ScoreTimer_timeout():
	var player_origin = self.global_transform.origin
	var cur_position = Vector2(player_origin.x, player_origin.z)
	var last_position = Vector2(last_score_position.x, last_score_position.z)
	var distance_traveled = cur_position.distance_to(last_position)
	
	score_acc += distance_traveled * 0.01
	score_acc = round(score_acc)
	
	ui.set_score(score_acc)
