extends Area

enum PlayerStates {
	IDLE,
	RUNNING,
	FALLING,
	STUMBLED,
	FALLEN,
}

func _on_FallenArea_body_entered(body):
	if body.is_in_group("Player"):
		if not body.falling:
			var wait: GDScriptFunctionState = yield(get_tree().create_timer(2), "timeout")
		body._die()
