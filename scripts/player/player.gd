extends CharacterBody2D


const SPEED = 150.0
const JUMP_VELOCITY = 380.0

var is_attacking = false
var is_down = false
var jumps_left: int = 0
var p_direction: int = 1
const Total_jumps: int = 2
@onready var boomerang_path = preload("res://scenes/player/boomerang.tscn")
@onready var shot_path = preload("res://scenes/player/sword_shot.tscn")

# Player health system
@export var max_health: int = 5
var current_health: int

func _ready():
	current_health = max_health
	
	# Set up collision layers for player
	# Layer 1: World/Tiles (collision)
	# Layer 2: Enemies (collision)
	# Layer 3: Player (player belongs to)
	set_collision_layer_value(1, false)  # Not world layer
	set_collision_layer_value(2, false)  # Not enemy layer
	set_collision_layer_value(3, true)   # Player layer
	
	# Masks: What layers to collide with
	set_collision_mask_value(1, true)   # Collide with world/tiles
	set_collision_mask_value(2, true)   # Collide with enemies
	set_collision_mask_value(3, false)  # Don't collide with other players

func take_damage(amount: int) -> void:
	if is_attacking:  # Can't be damaged while attacking
		return
	
	current_health -= amount
	print("Player took damage: ", amount, " | Health: ", current_health, "/", max_health)
	
	# Visual feedback
	if current_health > 0:
		$AnimatedSprite2D.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		$AnimatedSprite2D.modulate = Color.WHITE
	else:
		# Player death - restart game
		print("Player died! Restarting game...")
		$AnimatedSprite2D.modulate = Color.RED
		await get_tree().create_timer(1.0).timeout
		get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		if velocity.y > 0 and not is_attacking:
			$AnimatedSprite2D.play("fall")
	else:
		jumps_left = Total_jumps
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		if is_on_floor() and not is_attacking:
			if is_down:
				$AnimatedSprite2D.play("slide")
			else:
				$AnimatedSprite2D.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor() and not is_attacking and not is_down:
			$AnimatedSprite2D.play("idle")
	
	if direction == 1:
		p_direction = 1
		$AnimatedSprite2D.flip_h = false
	elif direction == -1:
		p_direction = -1
		$AnimatedSprite2D.flip_h = true

	# Handle jump.
	if jumps_left > 0 and velocity.y >= 0.0:
		if Input.is_action_just_pressed("jump"):
			velocity.y -= JUMP_VELOCITY
			jumps_left -= 1
			$AnimatedSprite2D.play("jump")

	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		$AnimatedSprite2D.play("special")
		await $AnimatedSprite2D.animation_finished
		shot()
		#throw()
		is_attacking = false

	if Input.is_action_just_pressed("interact") and is_on_floor():
		is_attacking = true
		$AnimatedSprite2D.play("attack")
		await $AnimatedSprite2D.animation_finished
		is_attacking = false
		
	if Input.is_action_pressed("down") and is_on_floor() and not is_attacking:
		is_down = true
		$AnimatedSprite2D.play("down")
		if velocity.x != 0:
			$AnimatedSprite2D.play("slide")
	elif is_down:
		is_down = false
		
	move_and_slide()

func shot():
	var sword_shot=shot_path.instantiate()
	var direction = Vector2.RIGHT
	if p_direction == -1:
		direction = Vector2.LEFT
	print(direction)
	sword_shot.dir=direction
	sword_shot.pos=$Boom.global_position
	sword_shot.rota=global_rotation
	sword_shot.action = true
	get_parent().add_child.call_deferred(sword_shot)

func throw():
	var boomerang=boomerang_path.instantiate()
	boomerang.dir=rotation
	boomerang.pos=$Boom.global_position
	boomerang.rota=global_rotation
	boomerang.action = true
	get_parent().add_child.call_deferred(boomerang)
