extends RigidBody

export(float, 0, 1000) var MAX_HP = 20
export(float, 0, 1000) var DAMAGE = 10

onready var anim_player: AnimationPlayer = $AnimationPlayer

var hp = MAX_HP
var can_damage = true
var type = "spiky"

func _start_attack():
	anim_player.play("attack")
	anim_player.connect("animation_finished", self, "_on_attack_finished")
	
func _on_attack_finished(animation):
	if animation == "attack":
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
	$ExplodeParticles.emitting = true
	$ExplodeSound.play()
	$Spiky.hide()
	$DamageArea.set_deferred("monitoring", false)
	$CollisionShape.disabled = true
	yield(get_tree().create_timer(1), "timeout")
	call_deferred("queue_free")


func _on_Area_body_entered(body: Spatial):
	if body.is_in_group("Player") and body.has_method("on_Touch_Enemy"):
		body.on_Touch_Enemy()
		_explode()


func on_Pill_Hit(hit_damage = 10):
	$ScoreText.show()
	anim_player.play("idle")
	$AttackTimer.start()
	hp -= hit_damage
	if hp <= 0:
		_explode()
