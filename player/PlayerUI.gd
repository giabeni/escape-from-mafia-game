extends Control

class_name UIPlayer

onready var score_text: RichTextLabel = $MarginContainer/VBoxContainer/Top/Score
onready var pill_text: RichTextLabel = $MarginContainer/VBoxContainer/Top/Pills

func _ready():
	set_score(0)
	set_pill_count(0)
	
func set_score(score):
	score_text.text = "Score: " + str(score)

func set_pill_count(pill_count):
	pill_text.text = "Pills: " + str(pill_count)
	if pill_count <= 0:
		pill_text.add_color_override("default_color", "#9c3013")
	else:
		pill_text.add_color_override("default_color", "#13a159")
		
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true
	elif Input.is_action_just_pressed("ui_cancel") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().paused = false
	
