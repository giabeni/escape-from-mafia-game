extends RigidBody

export(float, 0, 100) var ANGULAR_ACC = 2
export(float, 0, 10000) var DAMAGE = 50

onready var pickup_area: Area = $PickableArea
onready var explosion_timer: Timer = $ExplosionTimer
onready var default_timer: Timer = $DefaultTimer
onready var explosion: Particles = $Explosion
onready var body: MeshInstance = $Capsula
onready var explosion_area: Area = $ExplosionArea
onready var collect_sound: AudioStreamPlayer = $CollectSound

enum PillStates {
	IDLE,
	THROWN,
	COLLECTED
}

var state = PillStates.IDLE
var next_impulse = Vector3.ZERO
var player: Player
var is_thrown = false
var exploded = false

func _ready():
	_set_params()


func _physics_process(delta):
	_set_params()
	_animate(delta)
	
	if state == PillStates.THROWN and next_impulse != Vector3.ZERO:
		set_as_toplevel(true)
		self.apply_impulse(Vector3.ZERO, next_impulse)
		is_thrown = true
		next_impulse = Vector3.ZERO
		default_timer.start()
		
	
	if is_thrown and not exploded:
		_check_for_collisions()
	
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
	yield(get_tree().create_timer(0.3), "timeout")
	state = PillStates.THROWN
#	global_transform.origin = origin
	next_impulse = impulse
#	print("Next impulse = ", impulse)

func _check_for_collisions():
	var colliders = get_colliding_bodies()
	
	if colliders.size() > 0 and not (colliders[0] as Spatial).is_in_group("Player"):
		_explode()

func _explode():
	if is_thrown:
		print("BOOOM")
		exploded = true
		explosion_area.scale = Vector3(1, 1, 1)
		linear_velocity = Vector3.ZERO
		$ExplosionArea/CSGSphere.show()
		explosion.emitting = true
		$ExplosionSound.play()
		body.hide()
	#	explosion_area.set_deferred("monitoring", true)
		explosion_timer.start()
	

func _on_collected():
	state = PillStates.COLLECTED
	self.hide()
	collect_sound.play()
	yield(get_tree().create_timer(1.2), "timeout")
	self.call_deferred("queue_free")

func _on_hit():
#	print("on hit")
	_explode()

func _on_PickupArea_body_entered(body):
	if state == PillStates.IDLE:
		if (body as Spatial).is_in_group("Player") and body.has_method("on_PowerUp_Collected"):
			pickup_area.set_deferred("monitoring", false)
			body.on_PowerUp_Collected("CAPSULE")
			_on_collected()

	elif state == PillStates.THROWN:
		if (body as Spatial).is_in_group("Enemies") and body.has_method("on_Pill_Hit"):
			var point = body.global_transform.origin
			pickup_area.set_deferred("monitoring", false)
			body.on_Pill_Hit(DAMAGE, player)
			_on_hit()

func _on_Timer_timeout():
	print("FREEEEE")
	self.call_deferred("queue_free")
	$Explosion.set_layer_mask_bit(2, false)
	$Explosion.hide()
	$Explosion.emitting = false
	$ExplosionArea.hide()
	


func _on_ExplosionArea_body_entered(body):
	if exploded and (body as Spatial).is_in_group("Enemies") and body.has_method("on_Pill_Hit"):
			var point = body.global_transform.origin
			pickup_area.set_deferred("monitoring", false)
			body.on_Pill_Hit(DAMAGE, player)
			_on_hit()
		
