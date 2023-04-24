extends Button

@export var systemID : String

func _on_pressed():
	var system_scene_path = "res://scenes/solarsystem_" + systemID + ".tscn"
	get_tree().change_scene_to_file(system_scene_path)
