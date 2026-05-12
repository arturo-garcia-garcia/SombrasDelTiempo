extends CharacterBody2D

@export var speed = 600

var pos:Vector2
var rota:float
var dir:float
var action = false

func _ready():
	global_position=pos
	global_rotation=rota
	
func _physics_process(delta):
	velocity=Vector2(speed,0).rotated(dir)
	if action:
		$AnimatedSprite2D.play("throw")
	move_and_slide()


func _on_life_timeout() -> void:
	velocity=Vector2(-speed,0).rotated(dir)
	$AnimatedSprite2D.play("return")
	await $AnimatedSprite2D.animation_finished
	queue_free() 


func _on_area_2d_body_entered(body: Node2D):
	print("HIT!!!")
	queue_free() 
	
