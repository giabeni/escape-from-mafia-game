extends RigidBody

export(float, 0, 100) var ANGULAR_ACC = 2
export(float, 0, 10000) var DAMAGE = 10

onready var pickup_area: Area = $PickupArea
onready var timer: Timer = $Timer
onready var collect_sound: AudioStreamPlayer = $CollectedSound
onready var trail_particles: Particles = $TrailParticles
onready var trail_timer: Timer = $TrailTimer

enum PillStates {
	IDLE,
	THROWN,
	COLLECTED
}

var state = PillStates.IDLE
var next_impulse = Vector3.ZERO
var player: Player
var is_thrown = false

func _ready():
	_set_params()


func _physics_process(delta):
	_set_params()
	_animate(delta)
	_check_collisions()
	
	if state == PillStates.THROWN and next_impulse != Vector3.ZERO:
		set_as_toplevel(true)
		self.apply_impulse(Vector3.ZERO, next_impulse)
		contact_monitor = true
#		axis_lock_angular_z = true
		is_thrown = true
		trail_timer.start()
		timer.start()
		next_impulse = Vector3.ZERO
		
	if trail_timer.is_stopped() and linear_velocity.length() <= 25:
		trail_particles.emitting = false

func _set_params():
	match state:
		PillStates.IDLE:
			self.collision_layer = 4 # Pill
			self.set_collision_mask_bit(0, false) # General
			self.set_collision_mask_bit(1, false) # Player
			self.set_collision_mask_bit(2, false) # Enemies
			pickup_area.set_collision_mask_bit(1, true) # Player
			pickup_area.set_collision_mask_bit(2, false) # Enemies
		PillStates.THROWN:
			self.collision_layer = 4 # Pill
			self.set_collision_mask_bit(0, is_thrown) # General
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
	continuous_cd = true
	yield(get_tree().create_timer(0.15), "timeout")
	trail_particles.emitting = true
	state = PillStates.THROWN
#	global_transform.origin = origin
	next_impulse = impulse
#	print("Next impulse = ", impulse)

func _check_collisions():
	
	match state:
		PillStates.IDLE:
			return
				
		PillStates.THROWN: 
			if contact_monitor:
				var colliders = get_colliding_bodies()
		
				if colliders.size() > 0 and not (colliders[0] as Spatial).is_in_group("Player"):
					$TrailParticles.emitting = false


func _on_collected():
	state = PillStates.COLLECTED
	hide()
	collect_sound.pitch_scale = rand_range(1.5, 5)
	collect_sound.play()
	yield(get_tree().create_timer(0.3), "timeout")
	self.call_deferred("queue_free")

func _on_hit():
#	print("on hit")
	self.call_deferred("queue_free")

func _on_PickupArea_body_entered(body):
	if state == PillStates.IDLE:
		if (body as Spatial).is_in_group("Player") and body.has_method("on_Collected_Pill"):
			pickup_area.set_deferred("monitoring", false)
			body.on_Collected_Pill()
			_on_collected()

	elif state == PillStates.THROWN:
		if (body as Spatial).is_in_group("Enemies") and body.has_method("on_Pill_Hit"):
			var point = body.global_transform.origin
			pickup_area.set_deferred("monitoring", true)
			body.on_Pill_Hit(DAMAGE, player)
			_on_hit()


func _on_Timer_timeout():
	self.call_deferred("queue_free")
