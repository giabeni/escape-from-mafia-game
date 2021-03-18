extends Control

class_name UIPlayer

onready var score_text: RichTextLabel = $MarginContainer/VBoxContainer/Top/Score
onready var pills_counter: Control = $MarginContainer/VBoxContainer/Bottom/HSplitContainer/Right/PillCounter/BgPill
onready var pill_text: Label = $MarginContainer/VBoxContainer/Bottom/HSplitContainer/Right/PillCounter/BgPill/PillsLabel
onready var capsules_counter: Control = $MarginContainer/VBoxContainer/Bottom/HSplitContainer/Right/CapsulesCounter/BGCapsules
onready var capsules_text: Label = $MarginContainer/VBoxContainer/Bottom/HSplitContainer/Right/CapsulesCounter/BGCapsules/CapsulesLabel
onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/Bottom/HSplitContainer/Left/HP/HPProgressBar

export(Color) var empty_color = "#f93636"
export(Color) var pills_color = "#5fcf78"
export(Color) var capsules_color = "#3cd7f6"

var next_hp_value = null

func _ready():
	set_score(0)
	set_pill_count(0)
	set_capsules_count(0)
	
func set_max_hp(hp):
	hp_bar.max_value = hp
	
func set_hp(hp):
	next_hp_value = hp
	if hp < hp_bar.value:
		$AnimationPlayer.play("damage")
	
func set_score(score):
	score_text.text = "Score: " + str(score)

func set_pill_count(pill_count):
	pill_text.text = str(pill_count)
	if pill_count <= 0:
		pills_counter.modulate = empty_color
	else:
		pills_counter.modulate = "#ffffff"

func set_capsules_count(capsule_count):
	capsules_text.text = str(capsule_count)
	if capsule_count <= 0:
		capsules_counter.modulate = empty_color
	else:
		capsules_counter.modulate = "#ffffff"
		
func play_anim(anim):
	$AnimationPlayer.play(anim)
		
func _process(delta):
	
	if next_hp_value != null and next_hp_value != hp_bar.value:
		hp_bar.value = lerp(hp_bar.value, next_hp_value, delta * 10)
	
	if Input.is_action_just_pressed("ui_cancel") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true
	elif Input.is_action_just_pressed("ui_cancel") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().paused = false
	
