extends Spatial

export(NodePath) var PLAYER_NODE
export(Vector2) var SECTION_SIZE = Vector2(50, 50)
export(Array, PackedScene) var SECTIONS_ARRAY = []
export(float) var CURVE_PROB = 0.3
export(float, 0.1, 100) var GENERATION_TRIGGER_DISTANCE_FACTOR = 5
export(int, 1, 100) var MIN_ACTIVE_SECTIONS = 5
export(int, 1, 100) var BATCH_SIZE = 5

enum States {
	START,
	RUNNING,
	PAUSED,
	DYING,
}

onready var sections: Spatial = $Sections

var state = States.START
var rng = RandomNumberGenerator.new()
var player: Player
var last_section_origin: Vector3 = Vector3.ZERO
var last_axis: Vector3 = Vector3.FORWARD
var last_angle = 0
var current_difficulty = 1
var sections_queue = []

func _ready():
	rng.randomize()
	player = get_node(PLAYER_NODE)
	last_axis = _get_player_forward_axis()
	
	_generate_next_sections(5, last_axis, last_angle)
	

func _process(delta):
	
	_update_state()

	var player_origin = Vector2(player.global_transform.origin.x, player.global_transform.origin.z)
	
	var linear_distance = Vector2(last_section_origin.x, last_section_origin.z).distance_to(player_origin)
	if linear_distance < SECTION_SIZE.length() * GENERATION_TRIGGER_DISTANCE_FACTOR:
		print("-- Linear Distance = ", linear_distance)
		var forward_axis: Vector3 = last_axis
		var angle = last_angle
		if (randf() <= CURVE_PROB):
			var new_angle = 90 if randf() > 0.5 else -90
			forward_axis = forward_axis.rotated(Vector3.UP, deg2rad(new_angle))
			last_axis = forward_axis
			last_angle = angle + new_angle
			print("----- Attempting to generate sections :   axis = ", forward_axis, "   angle =  ", angle)
		call_deferred("_generate_next_sections", 3, forward_axis, last_angle)

func _update_state():
	if state == States.START:
		if abs(player.velocity.z) > 0:
			state = States.RUNNING
			player.game_running = true
	
func _generate_next_sections(count, forward_axis, angle):
	print("\n*** NEXT BATCH = ", count, "   | ACTIVE SECTIONS = ", sections_queue.size(), " ***")
	print("> Forwad = ", forward_axis, " | Angle = ", angle)
	
	# Check if new origin would overlap previous sections
	for i in range(1, count + 1):
		var next_origin: Vector3 = last_section_origin + forward_axis * Vector3(SECTION_SIZE.x, 0, SECTION_SIZE.y) * i
		for s in range(0, sections_queue.size() - count):
			var section: Section = sections_queue[s]
			var distance_to_section =  next_origin.distance_to(section.global_transform.origin)
			print("========> Checking i and section", i, "  ", section.name, " |  Distance = ", distance_to_section)
			if distance_to_section <= SECTION_SIZE.length():
				print("!!!! RETRYING GENERATE SECTIONS !!!!")
				return false
			
	for i in range(0, count):
		print("GENERATING SECTION i = ", i)
		_generate_section(forward_axis, angle)
		
	return true


func _generate_section(forward_axis, angle):
	
	var origin: Vector3 = last_section_origin + forward_axis * Vector3(SECTION_SIZE.x, 0, SECTION_SIZE.y)
	
	print(">> Last origin = ", last_section_origin)
	print(">> Next origin = ", origin)
	var section = _get_random_section_by_difficulty(current_difficulty)
	
	# Remove previous sections
	if sections_queue.size() >= MIN_ACTIVE_SECTIONS:
		var section_to_delete: Section = sections_queue.pop_front()
		if is_instance_valid(section_to_delete):
			var distance_to_player = section_to_delete.global_transform.origin.distance_to(player.global_transform.origin)
			if distance_to_player > SECTION_SIZE.length() * GENERATION_TRIGGER_DISTANCE_FACTOR:
				section_to_delete.call_deferred("queue_free")
	
	section.request_ready()
	sections.call_deferred("add_child", section)
	sections_queue.push_back(section)
	section.global_transform.origin = origin
	last_section_origin = origin
	
	# Add 0 o 180 degreess to randomize flipping
	var flip_angle = 0 if randf() < 0.5 else 180
	
	section.rotation_degrees.y = angle + flip_angle
	


func _get_random_section_by_difficulty(difficulty):
	var section_index = rng.randi_range(0, SECTIONS_ARRAY.size() - 1)
	print(">> Section index = ", section_index)
	var section: Section = SECTIONS_ARRAY[section_index].instance()
	# @TODO avoid uncompatible sections
	
	return section


func _get_player_forward_axis():
	return -player.global_transform.basis.z.normalized()

