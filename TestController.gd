extends Spatial

func _process(delta):
#	var input_vector = Vector2.ZERO
#	input_vector.x = Input.get_action_strength("look_right") - Input.get_action_strength("look_right")
#	input_vector.y = Input.get_action_strength("look_up") - Input.get_action_strength("look_down")
#	input_vector = input_vector.normalized()
#
#	if (input_vector != Vector2.ZERO):
#		print(input_vector)
	pass
	
func _input(event):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	input_vector.y = Input.get_action_strength("look_up") - Input.get_action_strength("look_down")
	input_vector = input_vector.normalized()
	
	if (input_vector != Vector2.ZERO):
		print(input_vector)
	
	if event.is_action("jump"):
		print("jump")
	
	if event.is_action("roll"):
		print("roll")
		
	if event.is_action("throw"):
		print("throw")
		
	if event.is_action("reset_aim"):
		print("reset_aim")
