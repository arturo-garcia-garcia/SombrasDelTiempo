# res://scripts/HUD.gd
extends Control

var total_relics: int = 0
@onready var relic_label: Label = $RelicCounterLabel
@onready var time_label: Label = $TimeIndicator

func set_total_relics(total: int):
	total_relics = total
	update_relics_from_gamestate()

func update_relics_from_gamestate():
	var collected = 0
	if Engine.has_singleton("GameState"):
		collected = GameState.get_collected_count()
	relic_label.text = "Relics: %d / %d" % [collected, total_relics]

func update_time_ui(new_state):
	if new_state == TimeManager.TimeState.PAST:
		time_label.text = "PAST"
	else:
		time_label.text = "PRESENT"
