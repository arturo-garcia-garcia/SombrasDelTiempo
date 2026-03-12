extends CharacterBody2D

@export var speed: float = 50.0
@export var chase_speed: float = 80.0
@export var max_health: int = 3
@export var gravity: float = 980.0
@export var shadow_walk_speed: float = 120.0
@export var shadow_walk_duration: float = 3.0
@export var shadow_walk_cooldown: float = 8.0
@export var jump_velocity: float = 300.0
@export var shadow_jump_multiplier: float = 1.4
@export var ledge_check_distance: float = 32.0

var current_health: int
var is_chasing: bool = false
var player: Node2D = null
var is_dead: bool = false
var is_taking_damage: bool = false

var is_shadow_walking: bool = false
var shadow_walk_time_left: float = 0.0
var can_shadow_walk: bool = true
var shadow_walk_cooldown_timer: float = 0.0
var jumps_left: int = 1
var enemy_direction: int = 1

@onready var anim_sprite = $AnimatedSprite2D
@onready var ledge_detector = $LedgeDetector if has_node("LedgeDetector") else null

func _ready() -> void:
	current_health = max_health
	jumps_left = 1
	anim_sprite.play("idle")
	add_to_group("enemies")
	
	# Set up collision layers for enemy
	# Layer 1: World/Tiles (collision)
	# Layer 2: Enemies (enemy belongs to)
	# Layer 3: Player (no collision)
	set_collision_layer_value(1, false)  # Not world layer
	set_collision_layer_value(2, true)   # Enemy layer
	set_collision_layer_value(3, false)  # Not player layer
	
	# Masks: What layers to collide with
	set_collision_mask_value(1, true)   # Collide with world/tiles
	set_collision_mask_value(2, false)  # Don't collide with other enemies
	set_collision_mask_value(3, true)   # Collide with player
	
	# Set up hitbox for detecting player attacks
	if has_node("Hitbox"):
		var hitbox = $Hitbox
		hitbox.collision_layer = 4  # Enemy hitbox layer
		hitbox.collision_mask = 16  # Detect player attacks on Layer 16
		hitbox.monitoring = true
		# Connect the area_entered signal if it exists
		if not hitbox.area_entered.is_connected(_on_hitbox_area_entered):
			hitbox.area_entered.connect(_on_hitbox_area_entered)
	
	# Also set up main body to detect player attacks
	set_collision_layer_value(2, true)  # Enemy body layer
	# 16 is $2^4$, which corresponds to Layer 5 in the Godot Inspector
	set_collision_mask_value(5, true)
	
	# Set up player detection area
	if has_node("PlayerDetection"):
		var detection = $PlayerDetection
		detection.collision_layer = 0
		detection.collision_mask = 4 # Detect Layer 3 (Player layer)
		if not detection.body_entered.is_connected(_on_player_detection_body_entered):
			detection.body_entered.connect(_on_player_detection_body_entered)
		if not detection.body_exited.is_connected(_on_player_detection_body_exited):
			detection.body_exited.connect(_on_player_detection_body_exited)

func _physics_process(delta: float) -> void:
	if is_dead or is_taking_damage:
		return

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jumps_left = 1

	# Update shadow walk cooldown
	if shadow_walk_cooldown_timer > 0:
		shadow_walk_cooldown_timer -= delta
		if shadow_walk_cooldown_timer <= 0:
			can_shadow_walk = true

	# Handle main enemy logic
	update_enemy_logic(delta)

	# Handle jumping
	handle_jump()

	move_and_slide()

# Called when an attack hits this enemy
func take_damage(amount: int) -> void:
	if is_dead: return
	
	current_health -= amount
	is_taking_damage = true
	velocity.x = 0 # Stop moving when hit
	
	if current_health <= 0:
		die()
	else:
		anim_sprite.play("hurt") # Make sure you map a "hurt" animation
		await anim_sprite.animation_finished
		is_taking_damage = false

func die() -> void:
	is_dead = true
	$CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	anim_sprite.play("dead") # Make sure you map a "dead" animation
	await anim_sprite.animation_finished
	queue_free()

# Connect this to a PlayerDetection Area2D's body_entered signal
func _on_player_detection_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		is_chasing = true

# Connect this to a PlayerDetection Area2D's body_exited signal
func _on_player_detection_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
		is_chasing = false

func chase_player():
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * chase_speed
	enemy_direction = direction
	
	# Flip sprite based on direction
	if direction != 0:
		anim_sprite.flip_h = direction < 0
	
	if is_on_floor():
		anim_sprite.play("run")

func should_activate_shadow_walk() -> bool:
	if not player:
		return false
	
	var distance_to_player = global_position.distance_to(player.global_position)
	# Activate shadow walk when player is at medium distance
	return distance_to_player > 100 and distance_to_player < 300

func start_shadow_walk():
	is_shadow_walking = true
	shadow_walk_time_left = shadow_walk_duration
	can_shadow_walk = false
	shadow_walk_cooldown_timer = shadow_walk_cooldown
	anim_sprite.modulate = Color(0.3, 0.3, 0.8, 0.7)
	set_collision_mask_value(3, false) # Don't collide with player during shadow walk

func update_shadow_walk(delta):
	shadow_walk_time_left -= delta
	if shadow_walk_time_left <= 0:
		stop_shadow_walk()
	else:
		if player:
			var direction = sign(player.global_position.x - global_position.x)
			velocity.x = direction * shadow_walk_speed
			enemy_direction = direction
			
			if direction != 0:
				anim_sprite.flip_h = direction < 0
			
			if is_on_floor():
				anim_sprite.play("shadow_walk")
			else:
				anim_sprite.play("shadow_fall")
		else:
			velocity.x = move_toward(velocity.x, 0, shadow_walk_speed)
			if is_on_floor():
				anim_sprite.play("shadow_idle")

func stop_shadow_walk():
	is_shadow_walking = false
	anim_sprite.modulate = Color.WHITE
	set_collision_mask_value(3, true) # Restore collision with player
	if is_on_floor():
		anim_sprite.play("idle")

func handle_jump():
	if jumps_left > 0 and velocity.y >= 0.0:
		var should_jump = false
		
		if is_shadow_walking and player:
			# Shadow jump - more aggressive
			var distance_to_player = global_position.distance_to(player.global_position)
			var player_y_diff = player.global_position.y - global_position.y
			
			# Jump if player is above or at medium distance
			should_jump = player_y_diff < -50 or (distance_to_player > 150 and randf() < 0.3)
		elif is_chasing and player:
			# Regular jump - more cautious
			var player_y_diff = player.global_position.y - global_position.y
			should_jump = player_y_diff < -80 and randf() < 0.2
		
		if should_jump:
			var jump_power = jump_velocity
			if is_shadow_walking:
				jump_power *= shadow_jump_multiplier
				jumps_left += 1 # Extra jump in shadow form
			
			velocity.y -= jump_power
			jumps_left -= 1
			
			if is_shadow_walking:
				anim_sprite.play("shadow_jump")
			else:
				anim_sprite.play("jump")

func shadow_attack():
	if is_shadow_walking and player:
		# Enhanced attack behavior in shadow form
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player < 80:
			anim_sprite.play("shadow_attack")
			# Damage would be handled by collision/hitbox
			return true
	return false

func update_enemy_logic(delta: float):
	# This function is intended to be overridden by child classes like MinorShadow.
	# Default behavior for basic enemies:
	if is_shadow_walking:
		update_shadow_walk(delta)
	else:
		if is_chasing and player:
			if can_shadow_walk and should_activate_shadow_walk():
				start_shadow_walk()
			else:
				chase_player()
		else:
			# Idle behavior
			velocity.x = move_toward(velocity.x, 0, speed)
			if is_on_floor():
				anim_sprite.play("idle")

func _on_hitbox_area_entered(area: Area2D):
	# Handle damage from player attacks
	if area.get_parent().is_in_group("player_attack"):
		var damage = 1
		if area.has_method("get_damage"):
			damage = area.get_damage()
		take_damage(damage)

# Wall and ledge detection functions
func is_hitting_wall() -> bool:
	return is_on_wall()

func is_near_ledge() -> bool:
	if not is_on_floor():
		return false
	
	# Check for ledge in front of enemy
	var check_pos = global_position
	check_pos.x += ledge_check_distance * enemy_direction
	
	# Use raycast if available, otherwise simple distance check
	if ledge_detector:
		ledge_detector.target_position = Vector2(ledge_check_distance * enemy_direction, ledge_check_distance)
		ledge_detector.force_raycast_update()
		return not ledge_detector.is_colliding()
	
	# Fallback: check if there's ground ahead
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(check_pos, check_pos + Vector2(0, 10), 1)
	var result = space_state.intersect_ray(query)
	return result.is_empty()

func should_reverse_direction() -> bool:
	return is_hitting_wall() or is_near_ledge()

func reverse_direction():
	enemy_direction *= -1
