extends RigidBody

export(Array, NodePath) var SPOTS_PATHS: Array = []
export(float, 0, 10000) var SCORE = 50
export(float, 0, 100) var SPEED = 10
export(float, 0, 100) var ACC = 2
export(float, 0, 100) var ANGULAR_ACC = 4
export(float, 0, 10) var SPOT_DETECT_MARGIN = 2
export(float, 0, 1000) var DAMAGE = 33.34

var spots = []
var current_spot_index: int = -1
var next_spot_index: int = -1
var current_spot: Vector3 = Vector3()
var next_spot: Vector3 = Vector3()
var velocity = Vector3.ZERO
var type = "balloon"

onready var explosion: Particles = $ExplodeParticles
onready var score_text: Spatial = $ScoreText


func _ready():
	if SPOTS_PATHS.size() >= 2 or spots.size() >= 2:
		for i in range(0, SPOTS_PATHS.size()):
#			print("Path = ", SPOTS_PATHS[i])
			spots.push_back(get_node(SPOTS_PATHS[i]).global_transform.origin)
		current_spot_index = 0
		next_spot_index = 1
#		print("ENEMY SPOTS = ", spots)
	
	randomize()
	$FlySound.pitch_scale = rand_range(0.5, 1.5)
		
func _physics_process(delta):
	
	if current_spot_index == -1 or next_spot_index == -1:
		return
	
	# Set spots postions
#	print ("Current spot = ", current_spot_index)
#	print ("Next spot = ", next_spot_index)
	current_spot = spots[current_spot_index]
	next_spot = spots[next_spot_index]
	
	# Move to next spot
	var direction =  (next_spot - transform.origin).normalized()
	velocity = velocity.linear_interpolate(direction * SPEED, delta * ACC)
	
#	if (velocity.normalized().dot($Mesh.transform.basis.y) < 0.9):
#	$Mesh.look_at($Mesh.transform.origin + velocity.normalized(), $Mesh.global_transform.basis.y)
	$Mesh.rotation.y = Vector2(-velocity.z, -velocity.x).angle()
	$Mesh.rotation = $Mesh.rotation.linear_interpolate(Vector3(-Vector2(-velocity.z, -velocity.y).angle(), Vector2(-velocity.z, -velocity.x).angle(), $Mesh.rotation.z ), delta)
#	$Mesh.rotation.z = deg2rad(180)
	
	translate_object_local(velocity * delta)
#	move_and_slide(velocity, Vector3.UP, false, 20, deg2rad(90), true)
	
	
#	# Fixed Rotation
#	$Mesh.rotate_y(deg2rad(ANGULAR_ACC))
	
	# Check if spot has reached and set new target
	var distance_to_next_spot = next_spot.distance_to(transform.origin)
	
#	print(get_instance_id(), "   => Distance to next spot = ", distance_to_next_spot)
#	print("Cur spot = ", current_spot_index, "    enxt spot = ", next_spot_index)
	if distance_to_next_spot < SPOT_DETECT_MARGIN:
		current_spot_index = current_spot_index + 1
		next_spot_index = next_spot_index + 1
		
		if next_spot_index >= spots.size():
			next_spot_index = 0

		if current_spot_index >= spots.size():
			current_spot_index = 0

func set_spots(spots_nodes: Array):
	for spot in spots_nodes:
		spots.push_back(spot.transform.origin)
	
	current_spot_index = 0
	next_spot_index = 1
	
func _explode():
	explosion.emitting = true
	$ExplodeSound.pitch_scale = rand_range(0.8, 1.2)
	$DieSound.pitch_scale = rand_range(0.8, 1.2)
	$ExplodeSound.play()
	$DieSound.play()
	$Mesh.hide()
	$Area.monitoring = false
	$CollisionShape.disabled = true
	yield(get_tree().create_timer(1), "timeout")
	call_deferred("queue_free")

func _on_Area_body_entered(body: Spatial):
	if body.is_in_group("Player") and body.has_method("on_Touch_Enemy"):
		body.on_Touch_Enemy(DAMAGE)
		_explode()

func on_Pill_Hit(damage, player):
	score_text.show()
	_explode()
	if player and is_instance_valid(player):
		player.on_Enemy_Killed(SCORE)
