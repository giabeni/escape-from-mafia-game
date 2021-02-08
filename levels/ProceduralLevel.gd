extends Spatial

export(NodePath) var PLAYER_NODE
export(Vector2) var SECTION_SIZE = Vector2(50, 50)
export(Array, PackedScene) var SECTIONS_ARRAY = []
export(Array, PackedScene) var ENEMIES_ARRAY = []
export(Array, SpatialMaterial) var BUILDING_MATERIALS = []
export(float, 0, 1) var CURVE_PROB = 0.3
export(float, 0, 1) var ENEMY_PROB = 1
export(float, 0, 1) var HEIGHT_OFFSET_PROB = 0.4
export(float, 1, 2) var DIFFICULTY_INCREASE_FACTOR = 1.025
export(float, 0.1, 100) var GENERATION_TRIGGER_DISTANCE_FACTOR = 5
export(int, 1, 100) var MIN_ACTIVE_SECTIONS = 5
export(int, 1, 100) var BATCH_SIZE = 5
export(float, 0, 100) var MAX_HEIGHT_OFFSET = 7.5
export(float, 0, 100) var DISTANCE_FACTOR = 2

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
var sections_by_difficulty = {
	"1": [],
	"2": [],
	"3": [],
	"4": [],
	"5": [],
	"6": [],
	"7": [],
	"8": [],
	"9": [],
	"10": [],
}
var sections_queue = []
var start_screen_exited = false
var section_id = 0
var difficulty = 0.75
var last_height_offset = 0
var initial_speed = 15

func _ready():
	rng.randomize()
	player = get_node(PLAYER_NODE)
	initial_speed = player.MAX_SPEED
	last_axis = _get_player_forward_axis()
	
	for section_scene in SECTIONS_ARRAY:
		var section: Section = section_scene.instance()
		for i in range(1, 10):
			if section.DIFFICULTY <= i:
				sections_by_difficulty[str(i)].push_back(section_scene)
		section.queue_free()
	
	_generate_next_sections(5, last_axis, last_angle)
	

func _process(delta):
	
	if not start_screen_exited:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	
	_update_state()

	var player_origin = Vector2(player.global_transform.origin.x, player.global_transform.origin.z)
	
	var linear_distance = Vector2(last_section_origin.x, last_section_origin.z).distance_to(player_origin)
	if linear_distance < SECTION_SIZE.length() * GENERATION_TRIGGER_DISTANCE_FACTOR:
#		print("-- Linear Distance = ", linear_distance)
		var forward_axis: Vector3 = last_axis
		var angle = last_angle
		
		# If should be a curve
		if randf() <= CURVE_PROB:
			var new_angle = 90 if randf() > 0.5 else -90
			forward_axis = forward_axis.rotated(Vector3.UP, deg2rad(new_angle))
			last_axis = forward_axis
			last_angle = angle + new_angle
#			print("----- Attempting to generate sections :   axis = ", forward_axis, "   angle =  ", angle)
		_generate_next_sections(3, forward_axis, last_angle)

func _update_state():
	if state == States.START and start_screen_exited:
		if abs(player.velocity.z) > 0:
			state = States.RUNNING
			player.game_running = true
	
func _generate_next_sections(count, forward_axis, angle):
#	print("\n*** NEXT BATCH = ", count, "   | ACTIVE SECTIONS = ", sections_queue.size(), " ***")
#	print("> Forwad = ", forward_axis, " | Angle = ", angle)
	
	# Check if new origin would overlap previous sections
	for i in range(1, count + 1):
		var next_origin: Vector3 = last_section_origin + forward_axis * Vector3(SECTION_SIZE.x, 0, SECTION_SIZE.y) * i
		for s in range(0, sections_queue.size() - count):
			var section: Section = sections_queue[s]
			var distance_to_section =  next_origin.distance_to(section.global_transform.origin)
#			print("========> Checking i and section", i, "  ", section.name, " |  Distance = ", distance_to_section)
			if distance_to_section <= SECTION_SIZE.length():
#				print("!!!! RETRYING GENERATE SECTIONS !!!!")
				return false
			
	for i in range(0, count):
#		print("GENERATING SECTION i = ", i)
		_generate_section(forward_axis, angle)
		
	return true


func _generate_section(forward_axis: Vector3, angle):
	
	var origin: Vector3 = last_section_origin + forward_axis * Vector3(SECTION_SIZE.x, 0, SECTION_SIZE.y)
	
	# Adds offset to compensate speed
	var horizontal_offset = ((player.get_horizontal_speed() / initial_speed) - 1) * DISTANCE_FACTOR
	origin = origin + forward_axis.normalized() * Vector3(horizontal_offset, 0, horizontal_offset)
	
#	print(">> Last origin = ", last_section_origin)
#	print(">> Next origin = ", origin)
	var section: Section = _get_random_section_by_difficulty(ceil(difficulty))
	
	# Remove previous sections
	if sections_queue.size() >= MIN_ACTIVE_SECTIONS:
		var section_to_delete: Section = sections_queue[0]
		if is_instance_valid(section_to_delete):
			var distance_to_player = section_to_delete.global_transform.origin.distance_to(player.global_transform.origin)
#			print("DISTANCE FROM REMOVING SECTION = ", distance_to_player, "COMPARTE TO = ", SECTION_SIZE.length() * GENERATION_TRIGGER_DISTANCE_FACTOR)
			if distance_to_player > SECTION_SIZE.length() * GENERATION_TRIGGER_DISTANCE_FACTOR * 0.75:
				sections_queue.remove(0)
				section_to_delete.call_deferred("queue_free")
	
#	section.request_ready()
	sections_queue.push_back(section)
	section.global_transform.origin = origin
	last_section_origin = origin
	
	# Set rotation based on section possibilities
	var random_angle_index = rng.randi_range(0, section.ALLOWED_ANGLES.size() - 1)
	var random_angle = section.ALLOWED_ANGLES[random_angle_index]
	section.rotation_degrees.y = random_angle
	
	# Set random offset in y
	var height_offset = _get_random_height_offset(difficulty)
	section.translation.y = height_offset
	
	# Add random enemy if is suitable
	if randf() <= ENEMY_PROB:
		var enemy_scene = _get_random_enemy()
		section.set_enemy(enemy_scene)
		
	sections.call_deferred("add_child", section)
	
	# Adds random materials
	if BUILDING_MATERIALS.size() > 0:
		section.call_deferred("set_surface_material", 0, _get_random_material())
		section.call_deferred("set_surface_material", 1, _get_random_material())
		section.call_deferred("set_surface_material", 2, _get_random_material())
	
func _get_random_enemy():
	var enemy_index = rng.randi_range(0, ENEMIES_ARRAY.size() - 1)
	return ENEMIES_ARRAY[enemy_index]


func _get_random_section_by_difficulty(difficulty):
	randomize()

	var allowed_sections = sections_by_difficulty[str(difficulty)]
	var section_index = rng.randi_range(0, allowed_sections.size() - 1)
#	print(">> Section index = ", section_index)
	var section = allowed_sections[section_index].instance()
	section_id = section_id + 1
	section.name = "Section " + str(section_id)
	# @TODO avoid uncompatible sections
	
	return section
	
func _get_random_height_offset(difficulty):
	var max_height = clamp(difficulty * MAX_HEIGHT_OFFSET * 0.75, 0, 1)
	
	var height_offset = rng.randf_range(-max_height, max_height) + last_height_offset
	
	if randf() < HEIGHT_OFFSET_PROB:
		last_height_offset = height_offset
		return height_offset
	else:
		return last_height_offset
		
func _get_random_material():
	BUILDING_MATERIALS.shuffle()
	return BUILDING_MATERIALS[0]

func _get_player_forward_axis():
	return -player.global_transform.basis.z.normalized()



func _on_Button_pressed():
	start_screen_exited = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Screen.hide()


func _on_DifficultyTimer_timeout():
	if start_screen_exited:
		CURVE_PROB = CURVE_PROB * DIFFICULTY_INCREASE_FACTOR
		ENEMY_PROB = ENEMY_PROB * DIFFICULTY_INCREASE_FACTOR
		HEIGHT_OFFSET_PROB = HEIGHT_OFFSET_PROB * DIFFICULTY_INCREASE_FACTOR
		difficulty = difficulty * DIFFICULTY_INCREASE_FACTOR
#		print("Difficulty increased to = ", difficulty)
