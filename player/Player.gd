extends KinematicBody

class_name Player

export(float) var MAX_SPEED = 15
export(float) var GRAVITY = 60
export(float) var FRONTAL_ACC = 8
export(float) var LATERAL_ACC = 8
export(float) var ANGULAR_ACC = 10
export(float) var JUMP_FORCE = 30
export(float) var JUMP_FRONT_ACC = 14
export(Vector2) var MOUSE_SENSITIVITY = Vector2(0.08, 0.08)
export(Vector2) var AIM_LIMIT = Vector2(80, 80)
export(Vector2) var AIM_ACC = Vector2(10, 10)
export(float) var LINEAR_SPEED_FACTOR_RATE = 1.025
export(float) var THROW_FORCE = 300
export(NodePath) var AIM_GIMBAL = "Gimbal"
export(PackedScene) var PILL_SCENE: PackedScene = null
export(PackedScene) var CAPSULE_SCENE: PackedScene = null
export(float) var SPEED_FACTOR: float = 1
export(float) var FALLING_HEIGHT: float = 20

onready var collision_shape: CollisionShape = $CollisionShape
onready var ui: UIPlayer = $PlayerUI
#onready var doctor = $Doctor
onready var anim_player: AnimationPlayer = $AnimationPlayer
onready var anim_tree: AnimationTree = $AnimationTree
onready var camera: ClippedCamera = $Gimbal/h/v/ClippedCamera
onready var infected_paricles: Particles = $Armature/Skeleton/NeckBone/InfectedParticles
onready var hand_bone: BoneAttachment = $Armature/Skeleton/RightHandBone
onready var aim_cast: RayCast = $Gimbal/h/v/ClippedCamera/RayCast
onready var burn_sound: AudioStreamPlayer = $BurnSound
onready var collect_anim_player: AnimationPlayer = $CollectedEffects/CollectSpriteAnimationPlayer
onready var jump_timer: Timer = $JumpTimer

enum PlayerStates {
	IDLE,
	RUNNING,
	FALLING,
	STUMBLED,
	FALLEN,
}

enum BulletType {
	NONE,
	PILL,
	CAPSULE,
	EMPTY,
}

var direction = Vector3.ZERO
var velocity = Vector3.ZERO
var resultant_velocity = Vector3.ZERO
var current_front_acc_z = 1
var angle = 0
var gimbal: Spatial
var camrot_h = 0
var camrot_v = 0
var mouse_motion: Vector2 = Vector2.ZERO
var cur_speed_limit = SPEED_FACTOR * MAX_SPEED
var last_score_position: Vector3
var score_acc: float = 0
var game_running = false
var anim_playback: AnimationNodeStateMachinePlayback
var anim_root_motion
var snap = Vector3.UP * -0.5
var jumping = false
var aiming = false
var falling = false
var pill_count = 0
var capsule_count = 0
var state = PlayerStates.IDLE


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	gimbal = get_node(AIM_GIMBAL)
	last_score_position = self.global_transform.origin
	anim_playback = anim_tree["parameters/Main/playback"]
	anim_playback = anim_tree["parameters/Main/playback"]
	anim_root_motion = anim_tree.root_motion_track
	cur_speed_limit = SPEED_FACTOR * MAX_SPEED
	
func _physics_process(delta):
	if state in [PlayerStates.IDLE, PlayerStates.RUNNING, PlayerStates.FALLING]:
		_get_input_direction()
		_get_jump(delta)
	
	
		if game_running:
			if Input.is_action_just_released("throw_mouse") or Input.is_action_just_pressed("throw"):
				_throw_pill(delta)
			elif Input.is_action_just_released("throw_mouse2") or Input.is_action_just_pressed("throw_2"):
				_throw_capsule(delta)
			elif Input.is_action_pressed("throw_mouse") or Input.is_action_pressed("aim"):
				aiming = true
				_aim(delta, BulletType.PILL if pill_count > 0 else BulletType.EMPTY, AIM_LIMIT, AIM_ACC * 2)
			elif Input.is_action_pressed("throw_mouse2") or Input.is_action_pressed("aim"):
				aiming = true
				_aim(delta, BulletType.CAPSULE if capsule_count > 0 else BulletType.EMPTY, AIM_LIMIT, AIM_ACC * 2)
			else:
				aiming = false
				_aim(delta, BulletType.NONE, AIM_LIMIT / 2, AIM_ACC)

	
	if state == PlayerStates.IDLE:
		var root_motion: Transform = anim_tree.get_root_motion_transform().rotated(Vector3.RIGHT, deg2rad(-90))
		var locomotion = root_motion.origin / delta
		velocity.x = locomotion.x
		velocity.z = locomotion.z
	elif state == PlayerStates.RUNNING:
		velocity.x = lerp(velocity.x, cur_speed_limit * direction.x * 1.25, delta * LATERAL_ACC)
		velocity.z = lerp(velocity.z, cur_speed_limit * direction.z * current_front_acc_z, delta * FRONTAL_ACC)
		
	
	if not is_on_floor():
		if falling or not jumping:
			velocity.y = -lerp(velocity.y, MAX_SPEED * 5, GRAVITY * delta)
		else:
			velocity.y -= GRAVITY * delta
	else:
		velocity.y = velocity.y - get_floor_normal().normalized().y * 4
		
	_set_rotation(delta)
	
	
	if state in [PlayerStates.RUNNING, PlayerStates.FALLING, PlayerStates.STUMBLED]:
		resultant_velocity = move_and_slide_with_snap(velocity.rotated(Vector3.UP, self.rotation.y), snap, Vector3.UP, true, 16, deg2rad(70), false)
	
		# Hack to stop on slope
		if state != PlayerStates.STUMBLED:
			var slides = get_slide_count()
			if slides:
				for i in slides:
					var touched = get_slide_collision(i)
#					print(is_on_floor(), " ",touched.normal.y, " ", cos(0), " ",  resultant_velocity.y)
					if is_on_floor() and touched.normal.y < cos(0) and resultant_velocity.y < 0 and (resultant_velocity.x != 0 or resultant_velocity.y != 0):
#						print(touched.normal.y)
						velocity.y = 0
						
	elif state == PlayerStates.STUMBLED:
		resultant_velocity = move_and_slide(resultant_velocity)
		
	
	_set_sounds()
	_set_animations(delta)
	
	if not game_running and not state == PlayerStates.IDLE:
		pass
#		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		if Input.is_action_just_pressed("ui_cancel") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif Input.is_action_just_pressed("ui_cancel") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
		
		
	if game_running and state == PlayerStates.RUNNING:
		_check_for_death()
		
	if state == PlayerStates.IDLE:
		ui.hide()
	else:
		ui.show()


func _get_input_direction():
	# Frontal direction
	if Input.is_action_just_pressed("move_forward") or Input.is_action_just_pressed("jump"):
		direction.z = -1
		state = PlayerStates.RUNNING
#	else:
#		direction.z = 0
		
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


func _get_jump(delta):
	
	
	if Input.is_action_pressed("jump") and not is_on_floor() and jumping and not jump_timer.is_stopped():
#		print('constant jump')
		velocity.y += JUMP_FORCE * delta * 2
		current_front_acc_z = 1 + JUMP_FRONT_ACC * delta * 2
		snap = Vector3.ZERO
	elif Input.is_action_just_pressed("jump") and is_on_floor():
#		print('initial jump')
		velocity.y = JUMP_FORCE / 1.5
		current_front_acc_z = 1 + JUMP_FRONT_ACC / 2
		jumping = true
		$JumpSound.play()
		jump_timer.start()
		anim_playback.travel("JUMP")
		snap = Vector3.ZERO
	else:
		snap = Vector3.UP * -0.5
		current_front_acc_z = lerp(current_front_acc_z, 1, delta * 3)
		
	if Input.is_action_just_pressed("roll") and not is_on_floor():
		velocity.y = -JUMP_FORCE * 2.5
	
	
	if jumping:
		if not aiming and not falling:
			camera.set_target_position("JUMP")
		
	else:
		if not aiming and not falling:
			camera.set_target_position("DEFAULT")

func _input(event):
	
	var sensitivity = MOUSE_SENSITIVITY * 0.6 if aiming else MOUSE_SENSITIVITY
		
	if event is InputEventMouseMotion and game_running:
		mouse_motion = event.relative
		
		camrot_h += -event.relative.x * sensitivity.x
		camrot_v += -event.relative.y * sensitivity.y
	
	elif event is InputEventJoypadMotion and game_running:
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
		input_vector.y = Input.get_action_strength("look_up") - Input.get_action_strength("look_down")
		input_vector = input_vector.normalized()
		
		camrot_h += -input_vector.x * sensitivity.x * 25
		camrot_v += input_vector.y * sensitivity.y * 25
		
	
	if Input.is_action_just_pressed("reset_aim"):
#		_reset_aim()
		camrot_h = 0
		camrot_v = 0


func get_horizontal_speed():
	return Vector2(velocity.x, velocity.z).length()

func _aim(delta, bullet_type: int, aim_limit: Vector2, acc):
	if not falling:
			camera.set_target_position("AIM" if bullet_type != BulletType.NONE else "LAST")
			
	aim_cast.visible = true
	aim_cast.set_bullet_type(bullet_type)

	camrot_v = clamp(camrot_v, -aim_limit.y, aim_limit.y)
	camrot_h = clamp(camrot_h, -aim_limit.x, aim_limit.x)
	
	$Gimbal/h.rotation_degrees.y = lerp($Gimbal/h.rotation_degrees.y, camrot_h, delta * acc.x)
	$Gimbal/h/v.rotation_degrees.x = lerp($Gimbal/h/v.rotation_degrees.x, camrot_v, delta * acc.y)
	
#	gimbal.rotate_y(deg2rad(-mouse_motion.x) * delta * MOUSE_SENSITIVITY.x)
#	gimbal.rotate_x(deg2rad(-mouse_motion.y) * delta * MOUSE_SENSITIVITY.y)
#	gimbal.rotation.z = 0
#	mouse_motion = Vector2()
#	mouse_motion = mouse_motion.linear_interpolate(Vector2.ZERO, delta * MOUSE_SENSITIVITY.length() * 100) 
	
func _reset_aim():
	if not falling:
		camera.set_target_position("DEFAULT")
	aiming = false
#	aim_cast.visible = false
	$Gimbal/h.rotation_degrees.y = 0
	$Gimbal/h/v.rotation_degrees.x = 0


func _throw_pill(delta):
	if state == PlayerStates.RUNNING and $PillFireRateTimer.is_stopped() and is_instance_valid(PILL_SCENE) and pill_count > 0:
#		var forward = -global_transform.basis.z.normalized()
#		var forward = -aim_cast.global_transform.basis.z.normalized()
		var forward: Vector3 = aim_cast.get_shooting_direction($Muzzle.global_transform.origin)
		var pill: RigidBody = PILL_SCENE.instance()
		pill.state = 1 # THROWN State
		pill.translation = Vector3(0, 0, 0)
		pill.rotation_degrees.x = 90
		pill.scale = Vector3(50, 50, 50)
		pill.set_player(self)
		hand_bone.add_child(pill)
		anim_tree["parameters/Throw/active"] = true
		$ThrowSound.play()
		$PillFireRateTimer.start()
		pill.throw(forward * THROW_FORCE, aim_cast.global_transform.origin)
		pill_count = pill_count - 1
		ui.set_pill_count(pill_count)
		
func _throw_capsule(delta):
	if state == PlayerStates.RUNNING and $PillFireRateTimer.is_stopped() and is_instance_valid(CAPSULE_SCENE) and capsule_count > 0:
#		var forward = -global_transform.basis.z.normalized()
		var forward = -aim_cast.global_transform.basis.z.normalized()
		var capsule: RigidBody = CAPSULE_SCENE.instance()
		capsule.state = 1 # THROWN State
		capsule.translation = Vector3(0, 0.4, 0)
		capsule.rotation_degrees.x = 90
		capsule.scale = Vector3(50, 50, 50)
		capsule.set_player(self)
		hand_bone.add_child(capsule)
		anim_tree["parameters/Throw/active"] = true
		$ThrowSound.play()
		$PillFireRateTimer.start()
		capsule.throw(forward * THROW_FORCE, aim_cast.global_transform.origin)
		capsule_count = capsule_count - 1
		ui.set_capsules_count(capsule_count)

func _set_sounds():
	if not is_on_floor() or state == PlayerStates.STUMBLED:
		$RightStep.stop()
		$LeftStep.stop()

func _set_animations(delta):
	var strafe = "parameters/Main/RUNNING/Strafe/blend_position"
	var speed = "parameters/Main/RUNNING/Speed/scale"
	var jump = "parameters/Main/RUNNING/Jump/active"

#	print(" ANIM = ", playback.get_current_node(), "  State = ", state)
	match state:
		PlayerStates.IDLE:
			anim_playback.travel("START")

		PlayerStates.RUNNING:
			if anim_playback.get_current_node() in ["FALLING_JUMP", "JUMP"]: 
				if is_on_floor():
#					if not $RightStep.playing:
#						$RightStep.play()
#					if not $LeftStep.playing:
#						 $LeftStep.play()
					if not $LandSound.playing:
						$LandSound.play()
					jumping = false
					falling = false
					anim_tree.root_motion_track = anim_root_motion
#					camera.add_trauma(0.05)
					anim_playback.travel("RUNNING")
				elif global_transform.origin.y < FALLING_HEIGHT:
					anim_tree.root_motion_track = ""
					camera.set_target_position("FALL")
					falling = true
					anim_playback.travel("FALLING")
				elif resultant_velocity.y < -0.75 * GRAVITY:
					falling = false
					anim_playback.travel("FALLING_JUMP")
			elif not jumping:
				falling = false
				anim_tree.root_motion_track = anim_root_motion
				anim_playback.travel("RUNNING")
				anim_tree[strafe].x = velocity.x / cur_speed_limit
				anim_tree[strafe].y = -velocity.z / cur_speed_limit
				anim_tree[speed] = SPEED_FACTOR
				if resultant_velocity.y < -15:
					anim_playback.travel("FALLING_JUMP")
	
	
func _check_for_death():
	
	if is_on_wall():
#		print("WAll")
		pass
		
	# Death if collided and stopped
	if resultant_velocity.length() < 3:
		for i in range (0, get_slide_count() - 1):
			var collision = get_slide_collision(i)
#			print("Collision ", i, "  -  normal dot = ", collision.normal.dot(-self.global_transform.basis.z))
			if collision != null:
				var normal_dot = collision.normal.normalized().dot(-self.global_transform.basis.z.normalized())
				if normal_dot < -0.3:
					state = PlayerStates.STUMBLED
#					camera.set_target_position("FALL")
					anim_playback.travel("STUMBLE")
					$FallenCollisionShape.disabled = false
					camera.add_trauma(0.2)
					yield(get_tree().create_timer(1), "timeout")
					_die()


func _die():
	game_running = false
	get_tree().call_deferred("reload_current_scene")
	

func on_Touch_Enemy(damage = 100):
	velocity.x = 0
	velocity.z = 0
	infected_paricles.emitting = true
	state = PlayerStates.STUMBLED
#	camera.set_target_position("FALL")
	anim_playback.travel("STUMBLE")
	camera.add_trauma(0.2)
	burn_sound.play()
	var wait: GDScriptFunctionState = yield(get_tree().create_timer(4), "timeout")
	_die()
	

func _on_CheckPoint_reached(body: CollisionObject):
	if body.get_instance_id() == self.get_instance_id():
		SPEED_FACTOR += LINEAR_SPEED_FACTOR_RATE

func on_Collected_Pill():
	$CollectedEffects/PillCollected.rotate_z(deg2rad(rand_range(-45, 45)))
	collect_anim_player.play("pill_collected")
	pill_count = pill_count + 1
	ui.set_pill_count(pill_count)
	
func on_PowerUp_Collected(power_up = "CAPSULE"):
	match power_up:
		"CAPSULE":
			collect_anim_player.play("capsule_collected")
			capsule_count = capsule_count + 1
			ui.set_capsules_count(capsule_count)

func _on_ScoreTimer_timeout():
	if state == PlayerStates.RUNNING:
		var player_origin = self.global_transform.origin
		var cur_position = Vector2(player_origin.x, player_origin.z)
		var last_position = Vector2(last_score_position.x, last_score_position.z)
		var position_direction = last_position.direction_to(cur_position)
		var vel_direction = Vector2(velocity.x, velocity.z).normalized()
#		print("Dot =  ", vel_direction.dot(position_direction))
		if position_direction.dot(vel_direction) >= -0.75:
			var distance_traveled = cur_position.distance_to(last_position)
			score_acc += distance_traveled * 0.5
			score_acc = round(score_acc)
			last_score_position = player_origin
		
		ui.set_score(score_acc)
		
func on_Enemy_Killed(score):
	score_acc += score
	ui.set_score(score_acc)
	
	
func _on_DifficultyTimer_timeout():
	if state == PlayerStates.RUNNING:
		SPEED_FACTOR *= LINEAR_SPEED_FACTOR_RATE
		JUMP_FRONT_ACC /= LINEAR_SPEED_FACTOR_RATE
		cur_speed_limit = MAX_SPEED * SPEED_FACTOR
