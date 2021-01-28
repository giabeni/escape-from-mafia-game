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


var direction = Vector3.ZERO
var velocity = Vector3.ZERO
var angle = 0
var gimbal: Spatial
var mouse_motion: Vector2 = Vector2.ZERO
var speed_factor: float = 1

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	gimbal = get_node(AIM_GIMBAL)

func _physics_process(delta):
	_get_input_direction()
	_get_jump()
	_aim(delta)

	velocity.z = lerp(velocity.z, MAX_SPEED * speed_factor * direction.z, delta * FRONTAL_ACC)
	velocity.x = lerp(velocity.x, MAX_SPEED * speed_factor * direction.x, delta * LATERAL_ACC)
	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		
	_set_rotation(delta)
	
	move_and_slide(velocity.rotated(Vector3.UP, self.rotation.y), Vector3.UP)
	
	if Input.is_action_just_pressed("ui_cancel") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif Input.is_action_just_pressed("ui_cancel") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


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
	if Input.is_action_just_pressed("roll") and not is_on_floor():
		velocity.y = -JUMP_FORCE


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_motion = event.relative
	
func _aim(delta):
	gimbal.rotate_y(deg2rad(-mouse_motion.x) * delta * MOUSE_SENSITIVITY)
	gimbal.rotation_degrees.y = clamp(gimbal.rotation_degrees.y, -AIM_LIMIT, AIM_LIMIT)
	mouse_motion = Vector2()


func _on_CheckPoint_reached(body: CollisionObject):
	if body.get_instance_id() == self.get_instance_id():
		speed_factor += LINEAR_SPEED_FACTOR_RATE
