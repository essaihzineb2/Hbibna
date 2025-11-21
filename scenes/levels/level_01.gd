extends Node3D

@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var player = $player

var total_enemies: int = 0
var enemies_killed: int = 0

func _ready() -> void:
	if background_music:
		var music_path = "res://scenes/sounds/classic.wav"
		if ResourceLoader.exists(music_path):
			background_music.stream = load(music_path)
			background_music.play()
			print("Background music loaded and playing: ", music_path)
		else:
			print("Background music file not found at: ", music_path)
			
	# Count enemies and connect signals
	var enemies = get_tree().get_nodes_in_group("enemy")
	total_enemies = enemies.size()
	print("Total enemies: ", total_enemies)
	
	for enemy in enemies:
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(_on_enemy_died)

func _on_enemy_died():
	enemies_killed += 1
	print("Enemies killed: ", enemies_killed, "/", total_enemies)
	
	if enemies_killed >= total_enemies:
		_win_game()

func _win_game():
	print("YOU WIN!")
	if player and player.hud:
		player.hud.show_win()

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_0):
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
