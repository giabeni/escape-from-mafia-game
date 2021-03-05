extends Area

func _on_FallenArea_body_entered(body):
	if body.is_in_group("Player"):
		body._die()
