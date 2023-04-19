extends Area2D

@export var planetID : String

var landing = 0

##
func _on_body_entered(body):
	if body.is_in_group("PlayerShip"):
		landing = landing + 1


func _on_body_exited(body):
	if body.is_in_group("PlayerShip"):
		landing = landing - 1
		assert(landing >= 0)

func _process(delta):
	# TODO: Not sure I like this being separate from controls in PlayerPhysics,
	# any way to centralise them? 
	# TODO: Need to make async and fix potential multi-overlap with a central manager.
	if Input.is_action_just_released("use"):
		if landing > 0:
			var planet_scene_path = "res://scenes/planets/" + planetID + ".tscn"
			get_tree().change_scene_to_file(planet_scene_path)

