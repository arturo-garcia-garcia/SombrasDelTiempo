# res://scripts/TimeManager.gd
class_name TimeManagerData
extends Node

enum TimeState { PRESENT, PAST }
var state: int = TimeState.PRESENT
signal time_changed(new_state)

func toggle_time():
	state = TimeState.PAST if state == TimeState.PRESENT else TimeState.PRESENT
	emit_signal("time_changed", state)

# Velocidad actual del tiempo
var time_scale: float = 1.0:
	set(value):
		time_scale = value
		Engine.time_scale = value

# Estados del tiempo
enum TimeMode { NORMAL, PAUSED, FAST_FORWARD, REWIND }
var mode: TimeMode = TimeMode.NORMAL

func _ready():
	Engine.time_scale = 1.0

func _process(delta):
	_check_input()

func _check_input():
	# Toggle normal / paused
	if Input.is_action_just_pressed("time_toggle"):
		if mode == TimeMode.PAUSED:
			set_normal()
		else:
			set_paused()

# Fast forward
	if Input.is_action_pressed("time_fast_forward"):
		set_fast_forward()

	# Rewind
	if Input.is_action_pressed("time_rewind"):
		set_rewind()

# Reset to normal when keys released
	if Input.is_action_just_released("time_fast_forward") or \
	Input.is_action_just_released("time_rewind"):
		set_normal()

# === Time mode methods ===

func set_normal():
	mode = TimeMode.NORMAL
	time_scale = 1.0

func set_paused():
	mode = TimeMode.PAUSED
	time_scale = 0.0

func set_fast_forward():
	mode = TimeMode.FAST_FORWARD
	time_scale = 3.0   # 3x time speed

func set_rewind():
	mode = TimeMode.REWIND
	time_scale = -2.0  # 2x backwards
