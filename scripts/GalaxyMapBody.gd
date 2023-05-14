extends Button

@export var systemID : String

func _on_pressed():
	var system_scene_path = "res://starsystems/solarsystem_" + systemID + "/system.tscn"
	PlayerState.warping_in = true
	get_tree().change_scene_to_file(system_scene_path)
