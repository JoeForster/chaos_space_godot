extends Node2D

@export var spawned_scene : Resource

func spawn():
	var scene_instance = spawned_scene.instantiate()
	scene_instance.position = position
	add_sibling(scene_instance)

func _process(_delta):
	pass

func _on_body_entered(body):
	if body.is_in_group("player"):
		spawn() # TODO call deferred
	# TODO spawn timer
