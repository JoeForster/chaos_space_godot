@tool

extends Area2D

@export var planetID : String
@export var planet_system_anim : SpriteFrames

# TODO combine with Planet.gd!
var landing = 0

func _enter_tree():
	# Do data-driven scene setup for this object in the solar system scene
	$AnimSprite2D.set_sprite_frames(planet_system_anim)
	$AnimSprite2D.play()

func _on_body_entered(body):
	if not Engine.is_editor_hint():
		if body.is_in_group("player"):
			landing = landing + 1

func _on_body_exited(body):
	if not Engine.is_editor_hint():
		if body.is_in_group("player"):
			landing = landing - 1
			assert(landing >= 0)

func _process(delta):
	if not Engine.is_editor_hint():
		# TODO: Not sure I like this being separate from controls in PlayerPhysics,
		# any way to centralise them? 
		# TODO: Need to make async and fix potential multi-overlap with a central manager.
		if Input.is_action_just_released("use"):
			if landing > 0:
				PlayerState.current_system = get_tree().current_scene.name
				PlayerState.system_pos = position
				PlayerState.system_pos_set = true
				var planet_scene_path = "res://planets/" + planetID + "/surface.tscn"
				get_tree().change_scene_to_file(planet_scene_path)
				
