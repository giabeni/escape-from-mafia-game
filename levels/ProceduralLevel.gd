extends Spatial

export(NodePath) var PLAYER_NODE
export(Vector2) var SECTION_SIZE = Vector2(50, 50)
export(Array, PackedScene) var SECTIONS_ARRAY = []
export(float) var CURVE_PROB = 0.3

onready var sections: Spatial = $Sections

var rng = RandomNumberGenerator.new()
var player: Player
var last_section_origin: Vector3 = Vector3.ZERO
var last_axis: Vector3
var current_difficulty = 1

func _ready():
	rng.randomize()
	player = get_node(PLAYER_NODE)
	last_axis = _get_player_forward_axis()
	
	_generate_next_sections(5)
	

func _process(delta):
	var player_origin = Vector2(player.global_transform.origin.x, player.global_transform.origin.z)
	
	var linear_distance = Vector2(last_section_origin.x, last_section_origin.z).distance_to(player_origin)
	if linear_distance < SECTION_SIZE.length() * 3:
		print("-- Linear Distance = ", linear_distance)
		_generate_next_sections(3)
	# @TODO Remove previous sections

	
func _generate_next_sections(count):
	for i in range(0, count):
		print("GENERATING SECTION i = ", i)
		_generate_section()


func _generate_section():
	var forward_axis: Vector3 = last_axis
	print(">> Forward = ", forward_axis)
	
	var angle = 0
	if (randf() <= CURVE_PROB):
		angle = 90 if randf() > 0.5 else -90
		forward_axis = forward_axis.rotated(Vector3.UP, deg2rad(angle))
		last_axis = forward_axis
	# @TODO generate curves to both sides
		
	
	var origin: Vector3 = last_section_origin + forward_axis * Vector3(SECTION_SIZE.x, 0, SECTION_SIZE.y)
	print(">> Last origin = ", last_section_origin)
	print(">> Next origin = ", origin)
	var section = _get_random_section_by_difficulty(current_difficulty)
	section.request_ready()
	sections.add_child(section)
	section.global_transform.origin = origin
	section.rotation_degrees.y = angle
	
	last_section_origin = origin


func _get_random_section_by_difficulty(difficulty):
	var section_index = rng.randi_range(0, SECTIONS_ARRAY.size() - 1)
	print(">> Section index = ", section_index)
	var section: Section = SECTIONS_ARRAY[section_index].instance()
	# @TODO avoid uncompatible sections
	
	return section


func _get_player_forward_axis():
	return -player.global_transform.basis.z.normalized()

