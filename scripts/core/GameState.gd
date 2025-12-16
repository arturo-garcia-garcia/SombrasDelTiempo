# res://scripts/GameState.gd
class_name GameStateData
extends Node

var collected_relics: Dictionary = {}

func collect_relic(id: String) -> void:
	collected_relics[id] = true

func has_collected(id: String) -> bool:
	return collected_relics.has(id)

func get_collected_count() -> int:
	return collected_relics.size()

func save_game():
	var f = FileAccess.open("user://save.dat", FileAccess.WRITE)
	f.store_var(collected_relics)
	f.close()

func load_game():
	if FileAccess.file_exists("user://save.dat"):
		var f = FileAccess.open("user://save.dat", FileAccess.READ)
		collected_relics = f.get_var()
		f.close()
