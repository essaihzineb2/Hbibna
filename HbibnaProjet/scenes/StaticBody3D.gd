extends StaticBody3D

@onready var light = $OmniLight3D

func _ready():
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.2, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 1.0)
	mat.emission_energy_multiplier = 2.5
	$MeshInstance3D.material_override = mat

	light.light_color = Color(1.0, 0.2, 1.0)
	light.omni_range = 5.0
	light.energy = 3.0
