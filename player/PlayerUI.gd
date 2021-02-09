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
		
