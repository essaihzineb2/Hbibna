extends Node3D

@onready var background_music: AudioStreamPlayer = $BackgroundMusic

func _ready() -> void:
	if background_music:
		var music_path = "res://scenes/sounds/classic.wav"
		if ResourceLoader.exists(music_path):
			background_music.stream = load(music_path)
			background_music.play()
			print("Background music loaded and playing: ", music_path)
		else:
			print("Background music file not found at: ", music_path)
