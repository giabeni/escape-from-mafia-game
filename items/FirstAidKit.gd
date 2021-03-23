extends Area

var collected = false

func _on_FirstAidKit_body_entered(body: Spatial):
	if not collected and body.is_in_group("Player") and body.has_method("on_PowerUp_Collected"):
		collected = true
		$FirstAidKit.hide()
		body.on_PowerUp_Collected("FIRST_AID_KIT", 50)
		$CollectSound.play()


func _on_CollectSound_finished():
	call_deferred("queue_free")
