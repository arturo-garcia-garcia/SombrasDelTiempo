extends CharacterBody2D

@export var speed = 600
@export var damage = 1

var pos:Vector2
var rota:float
var dir: Vector2 = Vector2.RIGHT
var action = false

func _ready():
	global_position=pos
	global_rotation=rota
	add_to_group("player_attack")
	
	# Set up collision layers for player attack
	if has_node("Area2D"):
		var area = $Area2D
		area.collision_layer = 16  # Player attack layer
		area.collision_mask = 2   # Detect enemy Layer 2
	
func _physics_process(delta):
	if dir == Vector2.LEFT:
		$AnimatedSprite2D.flip_h = true
	if dir == Vector2.RIGHT:
		$AnimatedSprite2D.flip_h = false
	velocity = dir * speed
	if action:
		$AnimatedSprite2D.play("shot")
	move_and_slide()

func get_damage():
	return damage

func _on_life_timeout() -> void:
	$AnimatedSprite2D.play("banish")
	await $AnimatedSprite2D.animation_finished
	queue_free() 

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Check if we hit an enemy
	if body.is_in_group("enemies") or body.has_method("take_damage"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
	$AnimatedSprite2D.play("banish")
	await $AnimatedSprite2D.animation_finished
	queue_free() 
