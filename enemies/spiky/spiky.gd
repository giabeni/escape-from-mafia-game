extends RigidBody

export(float, 0, 1000) var MAX_HP = 20
export(float, 0, 1000) var DAMAGE = 50
export(float, 0, 10000) var SCORE = 100

onready var anim_player: AnimationPlayer = $AnimationPlayer
onready var hp_bar: HPBar3D = $HPBar3D

var hp = MAX_HP
var can_damage = true
var type = "spiky"

func _ready():
	randomize()
	
	# Randomize animations and timer
	anim_player.stop()
	var random_idle_timer = rand_range(0, 3)
	yield(get_tree().create_timer(random_idle_timer), "timeout")
	anim_player.play()
	$AttackTimer.start()
	
	$BreathSound.pitch_scale = rand_range(0.8, 1.2)
	$AttackSound.pitch_scale = rand_range(0.8, 1.2)
	$HurtSound.pitch_scale = rand_range(0.8, 1.2)

func _start_attack():
	anim_player.play("attack")
	
func _on_animation_finished(animation):
	if animation == "attack":
		anim_player.play("idle")
	elif animation == "hurt":
		anim_player.play("idle")


func _on_AttackTimer_timeout():
	_start_attack()


func _on_DamageArea_body_entered(body):
	if body.is_in_group("Player") and body.has_method("on_Touch_Enemy") and can_damage:
		body.on_Touch_Enemy(DAMAGE)
		can_damage = false
		$DamageFreeTimer.start()


func _on_DamageFreeTimer_timeout():
	can_damage = true
	
		
func _explode():
	$DamageArea.set_deferred("monitoring", false)
	can_damage = false
	$ExplodeParticles.emitting = true
	$ExplodeSound.play()
	$ScoreText.show()
	$Spiky.hide()
	hp_bar.hide()
	$CollisionShape.disabled = true
	yield(get_tree().create_timer(1), "timeout")
	call_deferred("queue_free")


func _on_Area_body_entered(body: Spatial):
	if body.is_in_group("Player") and body.has_method("on_Touch_Enemy"):
		body.on_Touch_Enemy()
		_explode()


func on_Pill_Hit(hit_damage, player: Player):
	$DamageArea.set_deferred("monitoring", false)
	can_damage = false
	hp_bar.show()
	anim_player.play("hurt")
	$AttackTimer.start()
	hp -= hit_damage
	hp_bar.set_current_hp(hp)
	if hp <= 0:
		_explode()
		if player and is_instance_valid(player):
			player.on_Enemy_Killed(SCORE)
