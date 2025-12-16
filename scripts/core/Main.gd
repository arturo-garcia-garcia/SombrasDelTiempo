# res://scripts/Main.gd
extends Node2D

@export var initial_level_path: String = "res://scenes/levels/Level1.tscn"
@export var level_paths: Array[String] = [
	"res://scenes/levels/Level_0.tscn",
	"res://scenes/levels/Level_1.tscn",
    "res://scenes/levels/Level_2.tscn"
]

var current_level_index: int = -1
var current_level: Node = null

# Asegúrate de que los nombres de los nodos en la escena coincidan con estos
@onready var level_container: Node2D = $LevelContainer
@onready var hud: Node = $CanvasHUD/HUD
@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer_Music
@onready var sfx_player: AudioStreamPlayer = $AudioStreamPlayer_SFX
@onready var ui_layer := $CanvasLayer_UI

func _ready() -> void:
	show_main_menu()
	# Conectar TimeManager si existe como Autoload / Singleton
	if Engine.has_singleton("TimeManager"):
		var tm = Engine.get_singleton("TimeManager")
		# Conecta la señal time_changed si existe
		if tm is Object and tm.has_signal("time_changed"):
			tm.connect("time_changed", Callable(self, "_on_time_changed"))
			# Llamada inicial para sincronizar UI
			# uso get() por si la propiedad no está exactamente como "state"
			if tm.has_method("get"):
				# intenta obtener la propiedad 'state' si existe
				if tm.has_meta("state") or tm.has_method("state"):
					_on_time_changed(tm.state)
				else:
					# fallback: intenta acceder directamente
					_on_time_changed(tm.get("state") if tm.has_method("get") else null)
			else:
				# simple fallback
				if tm.has("state"):
					_on_time_changed(tm.state)
	# Cargar nivel inicial
	if initial_level_path != "":
		var idx := level_paths.find(initial_level_path)
		if idx == -1:
			load_level_by_path(initial_level_path)
		else:
			load_level(idx)


func show_main_menu():
	var menu_scene = load("res://scenes/ui/main_menu.tscn")
	var menu = menu_scene.instantiate()
	ui_layer.add_child(menu)

# Carga un nivel por path (instancia y conecta señales)
func load_level_by_path(path: String) -> void:
	var packed := ResourceLoader.load(path)
	if not packed:
		push_error("Couldn't load level: %s" % path)
		return
	_unload_current_level()
	# Asegurarse de que 'packed' sea PackedScene antes de instanciar
	var packed_scene: PackedScene = packed as PackedScene
	if not packed_scene:
		push_error("Resource loaded is not a PackedScene: %s" % path)
		return

	# Instanciar con tipo explícito
	var instance: Node = packed_scene.instantiate() as Node
	if not instance:
		push_error("Failed to instantiate level: %s" % path)
		return
	current_level = instance
	level_container.add_child(current_level)
	# conectar señales del level si están definidas
	if current_level.has_signal("level_completed"):
		current_level.connect("level_completed", Callable(self, "_on_level_completed"))
	if current_level.has_signal("relic_collected"):
		current_level.connect("relic_collected", Callable(self, "_on_relic_collected"))
	# actualizar HUD con total de reliquias si el level expone ese método
	if current_level.has_method("get_total_relics") and hud and hud.has_method("set_total_relics"):
		# llamar y convertir a int de forma segura
		var raw_total = current_level.call("get_total_relics")
		var total: int = 0
		if typeof(raw_total) == TYPE_INT:
			total = raw_total
		elif typeof(raw_total) == TYPE_FLOAT:
			total = int(raw_total)
		elif typeof(raw_total) == TYPE_STRING:
			# intentar parsear texto a int si el level devolviera string
			total = int(str(raw_total))
		else:
			total = 0
		hud.call("set_total_relics", total)
	current_level_index = level_paths.find(path)
	if current_level_index == -1:
		current_level_index = -2 # nivel cargado por path no en list

# Carga por índice conocido
func load_level(index: int) -> void:
	if index < 0 or index >= level_paths.size():
		push_error("Level index out of range: %d" % index)
		return
	load_level_by_path(level_paths[index])
	current_level_index = index

func _unload_current_level() -> void:
	if current_level:
		current_level.queue_free()
		current_level = null

# Señal: nivel completado -> cargar siguiente o mostrar final
func _on_level_completed() -> void:
	if current_level_index + 1 < level_paths.size():
		load_level(current_level_index + 1)
	else:
		show_game_complete()

# Señal: reliquia recogida (pasa el id)
func _on_relic_collected(relic_id: String) -> void:
	if Engine.has_singleton("GameState"):
		var gs = Engine.get_singleton("GameState")
		if gs and gs.has_method("collect_relic"):
			gs.call("collect_relic", relic_id)
	# actualizar HUD si expone método
	if hud and hud.has_method("update_relics_from_gamestate"):
		hud.call("update_relics_from_gamestate")

# Cuando cambia el tiempo global
func _on_time_changed(new_state) -> void:
	if hud and hud.has_method("update_time_ui"):
		hud.call("update_time_ui", new_state)
	if sfx_player:
		# reproduce sfx si está configurado
		if sfx_player.stream:
			sfx_player.play()

# Placeholder: reemplaza con pantalla de final o UI
func show_game_complete() -> void:
	# Simple behavior: pausa el juego y muestra un print.
	get_tree().paused = true
	print("Game Complete! (implement show_game_complete with UI)")
	# Si tienes un nodo UI para "GameComplete", aquí lo activarías:
	# $CanvasLayer_UI/GameComplete.visible = true
