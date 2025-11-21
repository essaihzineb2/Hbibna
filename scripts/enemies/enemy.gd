extends CharacterBody3D

# --- Enemy Settings ---
@export var patrol_speed: float = 1.5
@export var chase_speed: float = 3.5
@export var patrol_distance: float = 3.0
@export var attack_range: float = 0.7
@export var attack_damage: float = 10
@export var attack_cooldown: float = 0.7
@export var max_health: float = 30

# --- Internal Variables ---
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var start_pos: Vector3
var direction: int = 1

var chasing: bool = false
var player: Node = null

var can_attack: bool = true
var is_attacking: bool = false
var is_hurt: bool = false
var is_dead: bool = false

signal enemy_died

var health: float
var last_direction_change: float = 0.0
var direction_change_cooldown: float = 0.5

@onready var sprite: AnimatedSprite3D = $Sprite3D
@onready var detection_area: Area3D = $DetectionArea
@onready var health_label: Label3D = $HealthLabel


func _ready():
	start_pos = global_position
	health = max_health
	
	# Add enemy to group so player can detect it
	add_to_group("enemy")

	sprite.play("Walk")
	update_health_display()

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)


func _physics_process(delta):
	velocity.y -= gravity * delta
	last_direction_change += delta

	# Don't do anything if dead or hurt
	if is_dead or is_hurt:
		move_and_slide()
		return

	if is_attacking:
		velocity.x = 0  # Stop movement during attack
		move_and_slide()
		return

	if chasing and player and is_instance_valid(player):
		_chase_behavior()
	else:
		_patrol_behavior()

	sprite.scale.x = -1 if direction < 0 else 1

	move_and_slide()


# -------------------------------------------------------
# PATROL
# -------------------------------------------------------
func _patrol_behavior():
	velocity.x = direction * patrol_speed
	if sprite.animation != "Walk" and not is_attacking and not is_hurt:
		sprite.play("Walk")

	var dist = abs(global_position.x - start_pos.x)
	if dist >= patrol_distance and last_direction_change >= direction_change_cooldown:
		direction *= -1
		last_direction_change = 0.0


# -------------------------------------------------------
# CHASE
# -------------------------------------------------------
func _chase_behavior():
	if not player or not is_instance_valid(player):
		chasing = false
		player = null
		return
	
	var dir = sign(player.global_position.x - global_position.x)

	if dir != direction and last_direction_change >= direction_change_cooldown:
		direction = dir
		last_direction_change = 0.0

	# Use simple X distance for side-scroller
	var horizontal_distance = abs(player.global_position.x - global_position.x)

	if horizontal_distance <= attack_range and can_attack and not is_attacking:
		_attack()
	else:
		# Keep moving toward player if not attacking
		velocity.x = chase_speed * direction
		if sprite.animation != "Walk" and not is_attacking and not is_hurt:
			sprite.play("Walk")


# -------------------------------------------------------
# ATTACK
# -------------------------------------------------------
func _attack():
	if not can_attack or is_attacking or is_hurt or is_dead:
		return

	print("Starting attack sequence")
	can_attack = false
	is_attacking = true

	velocity.x = 0
	sprite.play("Attack")

	# Wait for animation to finish
	await sprite.animation_finished
	
	if is_dead:  # Check if enemy died during attack animation
		return
		
	print("Attack animation finished")

	# Apply damage if player is still in range
	if player and is_instance_valid(player):
		var horizontal_distance = abs(player.global_position.x - global_position.x)
		if horizontal_distance <= attack_range * 1.2:  # Slightly larger range for damage
			if player.has_method("take_damage"):
				print("Dealing damage to player")
				player.take_damage(attack_damage)
		else:
			print("Player moved out of range, no damage dealt")

	# Reset attacking flag BEFORE cooldown timer
	is_attacking = false
	print("Attack sequence complete, starting cooldown")

	# Start cooldown timer
	await get_tree().create_timer(attack_cooldown).timeout
	
	if not is_dead:  # Only allow attacking again if not dead
		can_attack = true
		print("Can attack again")


# -------------------------------------------------------
# TAKE DAMAGE
# -------------------------------------------------------
func take_damage(amount: float):
	if is_dead:
		return

	print("Enemy taking damage: ", amount)
	health -= amount
	update_health_display()
	print("Enemy health now: ", health)

	if health > 0:
		is_hurt = true
		sprite.play("Hurt")
		# Add a small knockback when hurt
		velocity.x = -direction * 2.0
		
		# Wait for hurt animation to finish
		await sprite.animation_finished
		is_hurt = false
		
		# Resume previous behavior after hurt
		if chasing and player:
			sprite.play("Walk")
	else:
		_die()


func update_health_display():
	if health_label:
		health_label.text = str(int(health))  # Use int() for cleaner display


func _die():
	if is_dead:
		return
		
	print("Enemy dying")
	is_dead = true
	is_attacking = false
	is_hurt = false
	
	velocity = Vector3.ZERO
	chasing = false
	player = null
	
	emit_signal("enemy_died")
	
	sprite.play("Death")
	set_physics_process(false)  # Stop all physics processing
	
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	
	await sprite.animation_finished
	queue_free()


# -------------------------------------------------------
# DETECTION SIGNALS
# -------------------------------------------------------
func _on_detection_area_body_entered(body):
	if body.is_in_group("player") and not is_dead:
		player = body
		chasing = true
		print("Player detected, starting chase")


func _on_detection_area_body_exited(body):
	if body == player and not is_dead:
		# Check actual distance before stopping chase
		if player and is_instance_valid(player):
			var distance = abs(player.global_position.x - global_position.x)
			# Only stop chasing if player is far enough AND not currently attacking
			if distance > patrol_distance * 2 and not is_attacking:
				chasing = false
				player = null
				print("Player lost, returning to patrol")
		else:
			chasing = false
			player = null
