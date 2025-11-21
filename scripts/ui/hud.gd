extends Control

@onready var force_bar = $ForceBar

func update_force(current_force: float, max_force: float):
	if force_bar:
		force_bar.max_value = max_force
		force_bar.value = current_force
