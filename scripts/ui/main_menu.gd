extends Control

func _ready():
	# Connect the button's pressed signal to the function
	# Assuming the button is named "StartButton" and is a direct child
	var start_button = $StartButton
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	else:
		print("StartButton not found!")

	var title_label = $TitleLabel
	if title_label:
		var tween = create_tween().set_loops()
		tween.tween_property(title_label, "scale", Vector2(1.1, 1.1), 1.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE)

func _on_start_button_pressed():
	# Change the scene to the main level
	get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")
