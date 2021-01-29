extends Control

class_name UIPlayer

onready var score_text: RichTextLabel = $MarginContainer/VBoxContainer/Top/Score

func _ready():
	pass
	
func set_score(score):
	score_text.text = "Score: " + str(score)
