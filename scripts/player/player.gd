extends CharacterBody3D

# --- Movement ---
@export var walk_speed: float = 2.0
@export var run_speed: float = 4.0
@export var jump_force: float = 4.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var input_x: float = 0.0

# --- Health / Energy ---
@export var max_health: float = 100.0
@export var max_energy: float = 100.0
@export var energy_regen_rate: float = 5.0      # regen par seconde
@export var run_energy_cost: float = 8.0        # par seconde quand tu cours

var health: float
var energy: float

# --- Combat ---
@export var attack_damage: int = 10
@export var attack_cost: float = 15.0
@export var attack_cooldown: float = 0.4

var can_attack: bool = true
var is_attacking: bool = false
var attacked_enemies: Array = []  # Track enemies already hit this attack

# --- Nodes ---
@onready var sprite: AnimatedSprite3D = $Sprite3D
@onready var attack_area: Area3D = $AttackArea
@onready var attack_sound: AudioStreamPlayer = $AttackSound
@onready var hud = $CanvasLayer/HUD


func _ready() -> void:
	add_to_group("player")  # Important for enemy detection
	health = max_health
	energy = max_energy
	
	# Connect area signals for better attack detection
	if attack_area:
		attack_area.monitoring = false
		attack_area.body_entered.connect(_on_attack_area_body_entered)

	# Load and assign attack sound
	if attack_sound:
		var sound_path = "res://scenes/sounds/knock.wav"
		if ResourceLoader.exists(sound_path):
			attack_sound.stream = load(sound_path)
			print("Attack sound loaded: ", sound_path)
		else:
			print("Attack sound file not found at: ", sound_path)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_get_input()
	_handle_attack_input()
	_move_player(delta)
	_update_animation()
	_update_energy(delta)
	move_and_slide()


# ------------------ MOVEMENT ------------------

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta


func _get_input() -> void:
	input_x = Input.get_axis("move_left", "move_right")


func _move_player(delta: float) -> void:
	var speed: float = walk_speed

	# run only if enough energy
	if Input.is_action_pressed("run") and energy > 5.0:
		speed = run_speed
		energy -= run_energy_cost * delta

	velocity.x = input_x * speed
	velocity.z = 0.0  # 2.5D : pas de mouvement en Z

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force


# ------------------ ATTACK ------------------

func _handle_attack_input() -> void:
	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking and energy >= attack_cost:
		_attack()


func _attack() -> void:
	print("Player attacking!")
	can_attack = false
	is_attacking = true
	energy -= attack_cost
	attacked_enemies.clear()  # Reset hit list for new attack

	# Activer la hitbox
	attack_area.monitoring = true

	# Jouer l'animation Attack
	if sprite.sprite_frames.has_animation("Attack"):
		sprite.play("Attack")
		
	# Play attack sound
	if attack_sound and attack_sound.stream:
		attack_sound.play()
	elif attack_sound:
		print("Attack sound node found but no stream assigned.")

	# Check for enemies already in range
	_check_and_damage_enemies()

	# Wait a bit to allow attack to connect during animation
	await get_tree().create_timer(0.1).timeout
	_check_and_damage_enemies()

	# Total attack duration
	await get_tree().create_timer(attack_cooldown - 0.1).timeout
	
	# Cleanup
	attack_area.monitoring = false
	is_attacking = false
	can_attack = true
	attacked_enemies.clear()
	print("Player attack finished")


func _check_and_damage_enemies() -> void:
	"""Check for enemies in attack range and damage them"""
	if not attack_area:
		return
		
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			# Don't hit the same enemy twice in one attack
			if body not in attacked_enemies:
				print("Hitting enemy: ", body.name)
				body.take_damage(attack_damage)
				attacked_enemies.append(body)


func _on_attack_area_body_entered(body: Node3D) -> void:
	"""Damage enemies that enter attack area while attacking"""
	if is_attacking and body.is_in_group("enemy") and body.has_method("take_damage"):
		if body not in attacked_enemies:
			print("Enemy entered attack range: ", body.name)
			body.take_damage(attack_damage)
			attacked_enemies.append(body)


# ------------------ ANIMATIONS ------------------

func _update_animation() -> void:
	# Ne pas override pendant l'attaque
	if is_attacking:
		return

	# Air (jump)
	if not is_on_floor():
		if sprite.sprite_frames.has_animation("Jump"):
			sprite.play("Jump")
		return

	# Sol
	if input_x != 0.0:
		sprite.flip_h = input_x < 0.0
		if Input.is_action_pressed("run") and energy > 5.0 and sprite.sprite_frames.has_animation("Run"):
			sprite.play("Run")
		elif sprite.sprite_frames.has_animation("Walk"):
			sprite.play("Walk")
	else:
		if sprite.sprite_frames.has_animation("Idle"):
			sprite.play("Idle")


# ------------------ ENERGY / HEALTH ------------------

func _update_energy(delta: float) -> void:
	# Regen lente quand tu ne cours pas et n'attaques pas
	if not Input.is_action_pressed("run") and not is_attacking:
		energy += energy_regen_rate * delta
		if energy > max_energy:
			energy = max_energy

	if energy < 0.0:
		energy = 0.0

	if hud:
		hud.update_force(energy, max_energy)


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return

	print("Player taking damage: ", amount)
	health -= amount
	print("Player health now: ", health)
	
	if health <= 0.0:
		health = 0.0
		_die()
	else:
		# Si tu as une anim "Hurt"
		if sprite.sprite_frames.has_animation("Hurt"):
			sprite.play("Hurt")


func _die() -> void:
	print("Player dying")
	velocity = Vector3.ZERO
	set_physics_process(false)
	
	# Tu peux mettre une anim "Death" ici
	if sprite.sprite_frames.has_animation("Death"):
		sprite.play("Death")
		await sprite.animation_finished
	queue_free()


# ------------------ UTILITY ------------------

func get_health() -> float:
	return health

func get_energy() -> float:
	return energy
