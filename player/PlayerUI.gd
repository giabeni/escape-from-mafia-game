extends Control

class_name UIPlayer

onready var score_text: RichTextLabel = $MarginContainer/VBoxContainer/Top/Score
onready var pill_text: RichTextLabel = $MarginContainer/VBoxContainer/Top/Pills

func _ready():
	pass
	
func set_score(score):
	score_text.text = "Score: " + str(score)

func set_pill_count(pill_count):
	pill_text.text = "Pills: " + str(pill_count)
