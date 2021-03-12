extends Camera


export var decay = 1  # How quickly the shaking stops [0, 1].
export var max_offset = Vector2(5, 2)  # Maximum hor/ver shake in pixels.
export var max_roll = 0.06  # Maximum rotation in radians (use sparingly).

export(NodePath) var DEFAULT_POSITION_NODE
export(NodePath) var JUMP_POSITION_NODE
export(NodePath) var AIM_POSITION_NODE
export(NodePath) var FALL_POSITION_NODE


export(float) var DEFAULT_CROSSHAIR_RADIUS = 12
export(float) var JUMP_CROSSHAIR_RADIUS = 50
export(float) var AIM_CROSSHAIR_RADIUS = 6
export(float) var FALL_CROSSHAIR_RADIUS = 100

export(float) var ACC = 3
export(float) var ANGULAR_ACC = 2.5

var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

var default_position: Position3D
var jump_position: Position3D
var aim_position: Position3D
var fall_position: Position3D

var target_position = null
var current_position_name = "DEFAULT"
var current_crosshair_radius = 8

var velocity = Vector3.ZERO

func _ready():
	randomize()
		
	if DEFAULT_POSITION_NODE:
		default_position = get_node(DEFAULT_POSITION_NODE)
		
	if JUMP_POSITION_NODE:
		jump_position = get_node(JUMP_POSITION_NODE)
		
	if AIM_POSITION_NODE:
		aim_position = get_node(AIM_POSITION_NODE)
		
	if FALL_POSITION_NODE:
		fall_position = get_node(FALL_POSITION_NODE)
	
	target_position = default_position	
	
func _physics_process(delta):
	if trauma:
		trauma = max(trauma - decay * delta, 0)
#		shake()
	
	if target_position != null and global_transform.origin.distance_to(target_position.global_transform.origin) > 0:
		var acc_factor = 1 if current_position_name != "AIM" else 1.5
		if current_position_name == "FALL":
			acc_factor = 0.3
		rotation = rotation.linear_interpolate(target_position.rotation, delta * ANGULAR_ACC * acc_factor)
		rotation.z = 0
		translation = translation.linear_interpolate(target_position.translation, delta * ACC * acc_factor)
	else:
		target_position = null
		
	
	match current_position_name:
		"DEFAULT":
			_set_crosshair_radius(DEFAULT_CROSSHAIR_RADIUS, delta)
		"JUMP":
			_set_crosshair_radius(JUMP_CROSSHAIR_RADIUS, delta)
		"AIM":
			_set_crosshair_radius(AIM_CROSSHAIR_RADIUS, delta)
		"FALL":
			_set_crosshair_radius(FALL_CROSSHAIR_RADIUS, delta)
			
	_set_crosshair_color($RayCast.get_aim_color())


func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)

func shake():
	var amount = pow(trauma, trauma_power)
	rotation.z = max_roll * amount * rand_range(-1, 1)
	h_offset = max_offset.x * amount * rand_range(-1, 1)
	v_offset = max_offset.y * amount * rand_range(-1, 1)
	
	
func set_target_position(position_name = "LAST"):
	if position_name == "LAST":
		return
		
	match position_name:
		"DEFAULT":
			target_position = default_position
		"JUMP":
			target_position = jump_position
		"AIM":
			target_position = aim_position
		"FALL":
			target_position = fall_position

	current_position_name = position_name
	

func _set_crosshair_radius(radius: float, delta):
	
	current_crosshair_radius = lerp(current_crosshair_radius, radius, delta * 2)
	
	$ShootingUI/Crosshair/Node2D/LineTop.position.y = -current_crosshair_radius
	$ShootingUI/Crosshair/Node2D/LineBottom.position.y = current_crosshair_radius
	$ShootingUI/Crosshair/Node2D/LineLeft.position.x = -current_crosshair_radius
	$ShootingUI/Crosshair/Node2D/LineRight.position.x = current_crosshair_radius

func _set_crosshair_color(color: Color):
	$ShootingUI/Crosshair.modulate = color
	$ShootingUI/Crosshair/Node2D/Light2D.color = color
	if color == Color("e2ff0000"):
		$ShootingUI/Crosshair/Node2D/Light2D.energy = 3
	else:
		$ShootingUI/Crosshair/Node2D/Light2D.energy = 2
