extends RigidBody

export(float, 0, 100) var ANGULAR_ACC = 2

onready var pickup_area: Area = $PickupArea
onready var timer: Timer = $Timer

enum PillStates {
	IDLE,
	THROWN
}

var state = PillStates.IDLE
var next_impulse = Vector3.ZERO
var player: Player

func _ready():
	_set_params()


func _physics_process(delta):
	_set_params()
	_animate(delta)
	_check_collisions()
	
	if state == PillStates.THROWN and next_impulse != Vector3.ZERO:
		set_as_toplevel(true)
		self.apply_impulse(Vector3.ZERO, next_impulse)
		timer.start()
		next_impulse = Vector3.ZERO

func _set_params():
	match state:
		PillStates.IDLE:
			self.collision_layer = 4 # Pill
			self.set_collision_mask_bit(0, true) # General
			self.set_collision_mask_bit(1, false) # Player
			self.set_collision_mask_bit(2, false) # Enemies
			pickup_area.set_collision_mask_bit(1, true) # Player
			pickup_area.set_collision_mask_bit(2, false) # Enemies
		PillStates.THROWN:
			self.collision_layer = 4 # Pill
			self.set_collision_mask_bit(0, true) # General
			self.set_collision_mask_bit(1, false) # Player
			self.set_collision_mask_bit(2, true) # Enemies
			pickup_area.set_collision_mask_bit(1, false) # Player
			pickup_area.set_collision_mask_bit(2, true) # Enemies
			

func _animate(delta):
	match state:
		PillStates.IDLE:
			rotate_x(deg2rad(ANGULAR_ACC))
			rotate_y(deg2rad(ANGULAR_ACC))
			rotate_z(deg2rad(ANGULAR_ACC))
		PillStates.THROWN:
			pass
#			self.angular_velocity.y += delta * ANGULAR_ACC
			
func set_player(node):
	player = node

func throw(impulse, origin):
	yield(get_tree().create_timer(0.3), "timeout")
	state = PillStates.THROWN
#	global_transform.origin = origin
	next_impulse = impulse
#	print("Next impulse = ", impulse)

func _check_collisions():
	
	match state:
		PillStates.IDLE:
			return
				
		PillStates.THROWN:
			pass


func _on_collected():
#	print("on collected")
	self.call_deferred("queue_free")

func _on_hit():
#	print("on hit")
	self.call_deferred("queue_free")

func _on_PickupArea_body_entered(body):
	if state == PillStates.IDLE:
		if (body as Spatial).is_in_group("Player") and body.has_method("on_Collected_Pill"):
			pickup_area.monitoring = false
			body.on_Collected_Pill()
			_on_collected()

	elif state == PillStates.THROWN:
		if (body as Spatial).is_in_group("Enemies") and body.has_method("on_Pill_Hit"):
			var point = body.global_transform.origin
			pickup_area.monitoring = false
			body.on_Pill_Hit()
			print("Player = ", player)
			if player and is_instance_valid(player):
				player.on_Enemy_Killed()
			_on_hit()


func _on_Timer_timeout():
	self.call_deferred("queue_free")
