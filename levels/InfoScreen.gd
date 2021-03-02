extends Control


onready var anim_player: AnimationPlayer = $AnimationPlayer
onready var difficulty_bar: ColorRect = $VBoxContainer/Botton/DifficultyBar
onready var difficulty_titile: RichTextLabel = $VBoxContainer/Botton/DifficultyBar/DiificultyTitle

func _ready():
	pass # Replace with function body.


func show_difficulty_bar(difficulty):
	difficulty_titile.text = "Dificuldade " + str(difficulty) + "!"
	anim_player.play("show")
