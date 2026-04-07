extends "res://scripts/enemies/enemy.gd"

# Knight-specific parameters
@export var attack_range: float = 60.0
@export var attack_cooldown_time: float = 1.5
@export var knight_damage: int = 2
@export var patrol_distance: float = 120.0
@export var vertical_attack_tolerance: float = 50.0

var attack_cooldown: float = 0.0
var patrol_start_position: Vector2
var patrol_direction: int = -1
var is_attacking: bool = false
var wall_turn_timer: float = 0.0
const WALL_TURN_DURATION: float = 0.6

func _ready() -> void:
	super._ready()
	patrol_start_position = global_position
	chase_speed = 70.0
	speed = 40.0
	max_health = 5
	current_health = max_health

	if not anim_sprite.frame_changed.is_connected(_on_animated_sprite_2d_frame_changed):
		anim_sprite.frame_changed.connect(_on_animated_sprite_2d_frame_changed)

func update_enemy_logic(delta: float) -> void:
	if wall_turn_timer > 0:
		wall_turn_timer -= delta

	if player and wall_turn_timer <= 0:
		var direction_to_player = sign(player.global_position.x - global_position.x)
		if direction_to_player != 0:
			enemy_direction = direction_to_player
			anim_sprite.flip_h = direction_to_player < 0

	if is_attacking:
		velocity.x = move_toward(velocity.x, 0, speed * 10 * delta)
		return

	if attack_cooldown > 0:
		attack_cooldown -= delta

	if not player:
		patrol()
		return

	if is_chasing and player:
		hunt_player(delta)

func is_wall_ahead() -> bool:
	var space_state = get_world_2d().direct_space_state
	var origin = global_position + Vector2(0, -20)
	var target = origin + Vector2(enemy_direction * 20, 0)
	var query = PhysicsRayQueryParameters2D.create(origin, target, 1)
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)
	return not result.is_empty()

func hunt_player(_delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)

	if (is_on_wall() or is_wall_ahead()) and wall_turn_timer <= 0:
		reverse_direction()
		wall_turn_timer = WALL_TURN_DURATION

	var current_speed = chase_speed
	if distance_to_player < 150:
		current_speed *= 1.2

	velocity.x = enemy_direction * current_speed

	if is_on_floor():
		anim_sprite.play("run")

	if is_player_in_attack_range():
		perform_attack()

func is_player_in_attack_range() -> bool:
	if not player or attack_cooldown > 0:
		return false
	var x_distance = abs(global_position.x - player.global_position.x)
	var y_distance = abs(global_position.y - player.global_position.y)
	return x_distance < attack_range and y_distance < vertical_attack_tolerance

func perform_attack() -> void:
	if attack_cooldown <= 0:
		is_attacking = true
		velocity.x = 0
		velocity.y = 0
		anim_sprite.play("attack")
		await anim_sprite.animation_finished
		is_attacking = false
		attack_cooldown = attack_cooldown_time

func damage_player() -> void:
	if player and player.has_method("take_damage"):
		player.take_damage(knight_damage)

func patrol() -> void:
	if should_reverse_direction() or is_wall_ahead():
		reverse_direction()
	else:
		var distance_from_start = global_position.x - patrol_start_position.x
		if (distance_from_start > patrol_distance and patrol_direction > 0) or (distance_from_start < -patrol_distance and patrol_direction < 0):
			reverse_direction()

	velocity.x = patrol_direction * speed * 0.8
	if is_on_floor():
		anim_sprite.play("run")

func reverse_direction() -> void:
	enemy_direction *= -1
	patrol_direction *= -1
	anim_sprite.flip_h = enemy_direction > 0

func handle_jump() -> void:
	pass

func _on_animated_sprite_2d_frame_changed() -> void:
	if anim_sprite.animation == "attack" and anim_sprite.frame == 4:
		if player:
			var x_dist = abs(global_position.x - player.global_position.x)
			var y_dist = abs(global_position.y - player.global_position.y)
			if x_dist <= (attack_range + 20) and y_dist <= (vertical_attack_tolerance + 20):
				damage_player()
