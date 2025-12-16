extends CharacterBody2D


const SPEED = 150.0
const JUMP_VELOCITY = 380.0

var is_attacking = false
var is_down = false
var jumps_left: int = 0
const Total_jumps: int = 2
@onready var boomerang_path = preload("res://scenes/player/boomerang.tscn")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		if velocity.y > 0:
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
		$AnimatedSprite2D.flip_h = false
	elif direction == -1:
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

func throw():
	var boomerang=boomerang_path.instantiate()
	boomerang.dir=rotation
	boomerang.pos=$Boom.global_position
	boomerang.rota=global_rotation
	boomerang.action = true
	get_parent().add_child.call_deferred(boomerang)
