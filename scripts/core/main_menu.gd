extends Control

@onready var anim := $AnimationPlayer
@onready var btn_play := $VBoxContainer/Iniciar
@onready var btn_settings := $VBoxContainer/Opciones
@onready var btn_exit := $VBoxContainer/Salir

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.play("fade_in")
	btn_play.pressed.connect(_on_iniciar_pressed)
	btn_settings.pressed.connect(_on_opciones_pressed)
	btn_exit.pressed.connect(_on_salir_pressed)

func _on_iniciar_pressed() -> void:
	anim.play("fade_out")
	await anim.animation_finished
	# Llamamos a Main para cargar el primer nivel.
	get_tree().root.get_node("Main").load_level_by_path("res://scenes/levels/level_0.tscn")
	queue_free() # cerramos el menú

func _on_opciones_pressed() -> void:
	print("Abrir Opciones...") # Replace with function body.

func _on_salir_pressed() -> void:
	get_tree().quit()
