extends Spatial

export(NodePath) var player_node = null

var player: Spatial

func _ready():
	if player_node != null:
		player = get_node(player_node)

func _process(delta):
	if is_instance_valid(player):
#		self.global_transform.origin.x = player.global_transform.origin.x
		self.global_transform.origin.z = player.global_transform.origin.z
