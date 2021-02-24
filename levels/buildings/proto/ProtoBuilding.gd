extends StaticBody

class_name Lateral

export(Array, SpatialMaterial) var WALLS_MATERIALS = []
export(Array, SpatialMaterial) var GLASS_MATERIALS = []

onready var mesh1: MeshInstance = $Mesh
onready var mesh2: MeshInstance = $Mesh2

export var x_offset: float = 0
export var y_offset: float = 0
export var section_origin: Vector3

func _ready():
	randomize()
	_set_random_materials()
	
	if section_origin:
		global_transform.origin = section_origin + Vector3(x_offset, y_offset, 0)

func _set_random_materials():
	if WALLS_MATERIALS.size() > 0:
		WALLS_MATERIALS.shuffle()
		mesh1.set_surface_material(0, WALLS_MATERIALS[0])
		mesh2.set_surface_material(0, WALLS_MATERIALS[0])
	
	if GLASS_MATERIALS.size() > 0:
		GLASS_MATERIALS.shuffle()
		mesh1.set_surface_material(1, GLASS_MATERIALS[0])
		mesh2.set_surface_material(1, GLASS_MATERIALS[0])
