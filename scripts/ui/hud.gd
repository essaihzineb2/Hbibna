extends Control

@onready var force_bar = $ForceBar
@onready var health_bar = $HealthBar

func update_force(current_force: float, max_force: float):
	if force_bar:
		force_bar.max_value = max_force
		force_bar.value = current_force

func update_health(current_health: float, max_health: float):
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func show_game_over():
	var game_over_panel = $GameOverPanel
	if game_over_panel:
		game_over_panel.visible = true
		
		var restart_btn = game_over_panel.get_node("RestartButton")
		if restart_btn:
			if not restart_btn.pressed.is_connected(_on_restart_pressed):
				restart_btn.pressed.connect(_on_restart_pressed)

func show_win():
	var win_panel = $WinPanel
	if win_panel:
		win_panel.visible = true
		
		var restart_btn = win_panel.get_node("RestartButton")
		if restart_btn:
			if not restart_btn.pressed.is_connected(_on_restart_pressed):
				restart_btn.pressed.connect(_on_restart_pressed)

func _on_restart_pressed():
	# Reload the current scene
	get_tree().reload_current_scene()
