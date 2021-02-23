extends Spatial

export(NodePath) var follow_node

var target: Spatial
var fixed_distance: Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	if follow_node:
		target = get_node(follow_node)
		fixed_distance = self.global_transform.origin - target.global_transform.origin

func _physics_process(delta):
	if is_instance_valid(target):
		self.translation = target.global_transform.origin + fixed_distance
