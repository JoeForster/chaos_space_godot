extends Node

enum PLAYER_MODE { SHIP, MECH }

@export var current_mode = PLAYER_MODE.SHIP
@export var ship_scene : Resource
@export var mech_scene : Resource
@export var spawn_point : Node2D

var vehicle_pos : Vector2

func get_character_object():
	if current_mode == PLAYER_MODE.SHIP:
		return get_node("PlayerShip")
	elif current_mode == PLAYER_MODE.MECH:
		return get_node("PlayerMech")
	else:
		return null

func update_mode():
	var ship_node = get_node_or_null("PlayerShip")
	var mech_node = get_node_or_null("PlayerMech")
	
	if current_mode == PLAYER_MODE.SHIP:
		if mech_node != null:
			mech_node.queue_free()
		if ship_node == null:
			var scene_instance = ship_scene.instantiate()
			scene_instance.set_name("PlayerShip")
			scene_instance.position = vehicle_pos
			add_child(scene_instance)
	elif current_mode == PLAYER_MODE.MECH:
		if ship_node != null:
			ship_node.queue_free()
		if mech_node == null:
			var scene_instance = mech_scene.instantiate()
			scene_instance.set_name("PlayerMech")
			scene_instance.position = vehicle_pos
			add_child(scene_instance)

func _ready():
	vehicle_pos = spawn_point.position	
	update_mode()

func _process(delta):
	vehicle_pos = get_character_object().position
	
	# TODO proper level transition manager; background
	if Input.is_action_just_released("use"):
		# todo make this less shit
		if PlayerState.current_system:
			var current_scene = get_tree().current_scene.name
			if !current_scene.contains("solarsystem_"):
				get_tree().change_scene_to_file("res://scenes/"+PlayerState.current_system+".tscn")

	elif Input.is_action_just_released("ability"):
		if current_mode == PLAYER_MODE.SHIP:
			current_mode = PLAYER_MODE.MECH
		elif current_mode == PLAYER_MODE.MECH:
			current_mode = PLAYER_MODE.SHIP
		update_mode()
