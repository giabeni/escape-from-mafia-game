extends Control

class_name UIPlayer

onready var score_text: RichTextLabel = $MarginContainer/VBoxContainer/Top/Score
onready var pill_text: RichTextLabel = $MarginContainer/VBoxContainer/Top/Pills
onready var capsules_text: RichTextLabel = $MarginContainer/VBoxContainer/Top/Capsules

export(Color) var empty_color = "#9c3013"
export(Color) var pills_color = "#5fcf78"
export(Color) var capsules_color = "#3cd7f6"

func _ready():
	set_score(0)
	set_pill_count(0)
	set_capsules_count(0)
	
func set_score(score):
	score_text.text = "Score: " + str(score)

func set_pill_count(pill_count):
	pill_text.text = "Pills: " + str(pill_count)
	if pill_count <= 0:
		pill_text.add_color_override("default_color", empty_color)
	else:
		pill_text.add_color_override("default_color", pills_color)

func set_capsules_count(capsule_count):
	capsules_text.text = "Capsules: " + str(capsule_count)
	if capsule_count <= 0:
		capsules_text.add_color_override("default_color", empty_color)
	else:
		capsules_text.add_color_override("default_color", capsules_color)
		
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true
	elif Input.is_action_just_pressed("ui_cancel") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().paused = false
	
