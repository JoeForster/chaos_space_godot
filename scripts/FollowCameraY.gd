extends Node2D

@export var to_follow : Camera2D

func _process(delta):
	if to_follow != null:
		global_position.y = to_follow.get_screen_center_position().y
