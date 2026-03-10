extends "res://scripts/enemies/enemy.gd"

# MinorShadow specific behaviors
@export var shadow_walk_chance: float = 0.6
@export var attack_range: float = 80.0
@export var shadow_damage: int = 2
@export var attack_cooldown_time: float = 1.2
@export var hunt_speed: float = 120.0
@export var vertical_attack_tolerance: float = 60.0  # Max Y difference for attacks

var attack_cooldown: float = 0.0
@export var patrol_distance: float = 150.0
var patrol_start_position: Vector2
var patrol_direction: int = 1
var is_hunting: bool = false
var last_known_player_position: Vector2
var is_attacking: bool = false

func _ready() -> void:
	super._ready()
	# Override default values for MinorShadow
	shadow_walk_speed = 160.0
	shadow_walk_duration = 3.0
	shadow_walk_cooldown = 5.0
	jump_velocity = 320.0
	shadow_jump_multiplier = 1.6
	patrol_start_position = global_position
	chase_speed = hunt_speed
	
	# Connect frame_changed signal for damage timing
	if not anim_sprite.frame_changed.is_connected(_on_animated_sprite_2d_frame_changed):
		anim_sprite.frame_changed.connect(_on_animated_sprite_2d_frame_changed)
		print("Frame signal connected for MinorShadow")

func update_enemy_logic(delta: float):
	# 1. ABSOLUTE HIGHEST PRIORITY: Always face the player
	if player:
		var direction_to_player = sign(player.global_position.x - global_position.x)
		if direction_to_player != 0:
			enemy_direction = direction_to_player
			
			# Invert the logic here to fix the backwards facing issue
			if direction_to_player > 0:
				anim_sprite.flip_h = true  # Player is to the left
			else:
				anim_sprite.flip_h = false # Player is to the right
			
	# 2. NOW handle the attack state lock
	if is_attacking:
		# Ensure the enemy comes to a complete stop instantly
		velocity.x = move_toward(velocity.x, 0, speed * 10 * delta)
		return
		
	# 3. Update cooldowns
	if attack_cooldown > 0:
		attack_cooldown -= delta

	# Stay idle until player is detected
	if not player:
		velocity.x = 0
		if is_on_floor():
			anim_sprite.play("idle")
		return

	# Active hunting behavior only when player is detected
	if player and is_chasing:
		hunt_player(delta)
	elif not player:
		patrol()

# Active hunting AI
func hunt_player(delta: float):
	var distance_to_player = global_position.distance_to(player.global_position)
	last_known_player_position = player.global_position
	
	# Strategic shadow walk usage
	if can_shadow_walk and should_use_shadow_walk_hunt(distance_to_player):
		start_shadow_walk()
		return
	
	# Regular chase with aggressive movement
	if is_shadow_walking:
		shadow_hunt_movement()
	else:
		regular_hunt_movement(distance_to_player)
	
	# Attack when in proper range (both X and Y)
	if is_player_in_attack_range():
		perform_attack()

# Check if player is actually in attack range (considering both X and Y)
func is_player_in_attack_range() -> bool:
	if not player or attack_cooldown > 0:
		return false
	
	var x_distance = abs(global_position.x - player.global_position.x)
	var y_distance = abs(global_position.y - player.global_position.y)
	
	# Check if player is within horizontal range and vertical tolerance
	return x_distance < attack_range and y_distance < vertical_attack_tolerance

func should_use_shadow_walk_hunt(distance: float) -> bool:
	# Use shadow walk more aggressively for hunting
	return distance > 120 and distance < 400 and randf() < shadow_walk_chance

func shadow_hunt_movement():
	# Shadow walk hunting - aggressive and unpredictable
	if player:
		var direction = sign(player.global_position.x - global_position.x)
		
		# More aggressive movement in shadow form
		velocity.x = direction * shadow_walk_speed
		
		# Occasional teleport-like movement
		if randf() < 0.02:  # 2% chance per frame
			# Teleport closer to player
			var teleport_distance = min(150.0, global_position.distance_to(player.global_position) * 0.5)
			var teleport_direction = (player.global_position - global_position).normalized()
			global_position += teleport_direction * teleport_distance
		
		if is_on_floor():
			anim_sprite.play("shadow_walk")

func regular_hunt_movement(distance: float):
	# Aggressive chase movement
	if player:
		var direction = sign(player.global_position.x - global_position.x)
		
		# Check for wall collision while hunting
		if is_on_wall():
			velocity.x = 0
			if is_on_floor():
				anim_sprite.play("idle")
			return
		
		# Speed up when closer
		var current_speed = hunt_speed
		if distance < 200:
			current_speed *= 1.3
		
		velocity.x = direction * current_speed
		
		if is_on_floor():
			anim_sprite.play("run")

func perform_attack():
	if attack_cooldown <= 0:
		is_attacking = true
		velocity.x = 0
		velocity.y = 0  # Stop vertical momentum too
		if is_shadow_walking:
			anim_sprite.play("shadow_attack")
		else:
			anim_sprite.play("attack")

		await anim_sprite.animation_finished
		is_attacking = false
		attack_cooldown = attack_cooldown_time

func shadow_damage_player():
	# Enhanced damage in shadow form
	if player and player.has_method("take_damage"):
		var damage = shadow_damage * 1.5  # 50% more damage in shadow form
		player.take_damage(damage)

func damage_player():
	# Regular damage
	if player and player.has_method("take_damage"):
		player.take_damage(shadow_damage)

# Enhanced defensive behavior
func take_damage(amount: int) -> void:
	super.take_damage(amount)
	
	# Defensive shadow walk when damaged
	if not is_shadow_walking and can_shadow_walk and current_health > 0:
		# 70% chance to use shadow walk defensively
		if randf() < 0.7:
			start_shadow_walk()
			# Move away from player briefly
			if player:
				var direction = -sign(player.global_position.x - global_position.x)
				velocity.x = direction * shadow_walk_speed * 1.2
		else:
			# Interrupt shadow walk if active
			if is_shadow_walking:
				stop_shadow_walk()
				shadow_walk_cooldown_timer = shadow_walk_cooldown * 1.5

# Override reverse_direction to fix patrol wall-sticking
func reverse_direction():
	enemy_direction *= -1
	patrol_direction *= -1

# Enhanced patrol with search behavior
func patrol():
	# Check for walls and ledges, reverse direction if needed
	if should_reverse_direction():
		reverse_direction()
	
	var distance_from_start = global_position.x - patrol_start_position.x
	
	# Change direction if reached patrol limit (fixed momentum check)
	if (distance_from_start > patrol_distance and patrol_direction > 0) or (distance_from_start < -patrol_distance and patrol_direction < 0):
		reverse_direction()
	
	velocity.x = patrol_direction * speed * 0.8  # Slower patrol speed
	
	if is_on_floor():
		anim_sprite.play("run")
	
	# Occasionally use shadow walk during patrol (searching behavior)
	if can_shadow_walk and randf() < 0.002:  # Fixed: realistic chance over time
		start_shadow_walk()

# Override shadow walk activation for hunting
func should_activate_shadow_walk() -> bool:
	return false  # We handle this in hunt_player()

# Override parent jump logic to prevent MinorShadow from jumping
func handle_jump():
	pass

func _on_animated_sprite_2d_frame_changed():
	# The scythe swings on frame 4
	if (anim_sprite.animation == "attack" or anim_sprite.animation == "shadow_attack") and anim_sprite.frame == 4:
		if player:
			var x_dist = abs(global_position.x - player.global_position.x)
			var y_dist = abs(global_position.y - player.global_position.y)

			# Give a +20 pixel grace area for the attack range
			if x_dist <= (attack_range + 20) and y_dist <= (vertical_attack_tolerance + 20):
				if anim_sprite.animation == "shadow_attack":
					shadow_damage_player()
				else:
					damage_player()
