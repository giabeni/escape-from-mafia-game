extends KinematicBody

export(float) var MAX_SPEED = 10
export(float) var GRAVITY = 20
export(float) var FRONTAL_ACC = 8
export(float) var LATERAL_ACC = 15
export(float) var ANGULAR_ACC = 10
export(float) var JUMP_FORCE = 15

var direction = Vector3.ZERO
var velocity = Vector3.ZERO
var angle = 0


func _physics_process(delta):
	_get_input_direction()
	_get_jump()
	
	velocity.z = lerp(velocity.z, MAX_SPEED * direction.z, delta * FRONTAL_ACC)
	velocity.x = lerp(velocity.x, MAX_SPEED * direction.x, delta * LATERAL_ACC)
	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		
	_set_rotation(delta)
	
	move_and_slide(velocity.rotated(Vector3.UP, self.rotation.y), Vector3.UP)
	

func _get_input_direction():
	# Frontal direction
	if Input.is_action_just_pressed("move_forward"):
		direction.z = -1
	
	if not Input.is_action_pressed("rotate"):
		# Lateral direction
		if Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
			direction.x -= 1 
		elif Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"):
			direction.x += 1
		else:
			direction.x = 0
	else:
		# Lateral rotation
		if Input.is_action_just_pressed("move_left") and not Input.is_action_pressed("move_right"):
			angle += deg2rad(90)
		elif Input.is_action_just_pressed("move_right") and not Input.is_action_pressed("move_left"):
			angle -= deg2rad(90)
		
		
	
	direction.x = clamp(direction.x, -1, 1)
	direction.z = clamp(direction.z, -1, 0)

func _set_rotation(delta):
	self.rotation.y = lerp_angle(rotation.y, angle, delta * ANGULAR_ACC)

func _get_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_FORCE
