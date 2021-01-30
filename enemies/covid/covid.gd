extends KinematicBody

export(Array, NodePath) var SPOTS_PATHS: Array = []
export(float, 0, 100) var SPEED = 1
export(float, 0, 100) var ACC = 0.5
export(float, 0, 100) var ANGULAR_ACC = 2

var spots = []
var current_spot_index: int = -1
var next_spot_index: int = -1
var current_spot: Vector3 = Vector3()
var next_spot: Vector3 = Vector3()

var velocity = Vector3.ZERO

func _ready():
	if SPOTS_PATHS.size() >= 2:
		for i in range(0, SPOTS_PATHS.size()):
			spots.push_back(get_node(SPOTS_PATHS[i]).global_transform.origin)
		current_spot_index = 0
		next_spot_index = 1
		
func _physics_process(delta):
	
	if current_spot_index == -1 or next_spot_index == -1:
		return
	
	# Set spots postions
	current_spot = spots[current_spot_index]
	next_spot = spots[next_spot_index]
	
	# Move to next spot
	var direction = current_spot.direction_to(next_spot) * delta * 50
	velocity = velocity.linear_interpolate(direction * SPEED, delta * ACC)
	move_and_slide(velocity, Vector3.UP)
	
	# Fixed Rotation
	rotate_y(deg2rad(ANGULAR_ACC))
	
	# Check if spot has reached and set new target
	if next_spot.distance_to(global_transform.origin) < 1:
		current_spot_index = current_spot_index + 1
		next_spot_index = next_spot_index + 1
		
		if next_spot_index >= spots.size():
			next_spot_index = 0

		if current_spot_index >= spots.size():
			current_spot_index = 0
	

func _on_Area_body_entered(body: Spatial):
	if body.is_in_group("Player") and body.has_method("on_Touch_Enemy"):
		body.on_Touch_Enemy()
