extends CharacterBody2D


@export var speed = 600

var pos:Vector2
var rota:float
var dir: Vector2 = Vector2.RIGHT
var action = false

func _ready():
	global_position=pos
	global_rotation=rota
	
func _physics_process(delta):
	if dir == Vector2.LEFT:
		$AnimatedSprite2D.flip_h = true
	if dir == Vector2.RIGHT:
		$AnimatedSprite2D.flip_h = false
	velocity = dir * speed
	if action:
		$AnimatedSprite2D.play("shot")
	move_and_slide()


func _on_life_timeout() -> void:
	$AnimatedSprite2D.play("banish")
	await $AnimatedSprite2D.animation_finished
	queue_free() 


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("HIT!!!")
	$AnimatedSprite2D.play("banish")
	await $AnimatedSprite2D.animation_finished
	queue_free() 
