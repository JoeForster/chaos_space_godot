extends Node

enum PLAYER_MODE { SHIP, MECH }

@export var current_mode = PLAYER_MODE.SHIP
@export var ship_scene : Resource
@export var mech_scene : Resource
@export var spawn_point : Node2D
@export var hud_throttle : TextureProgressBar
@export var max_hp = 100

var vehicle_pos : Vector2
var hp = max_hp

const SHIP_NODE_NAME = "PlayerShip"
const MECH_NODE_NAME = "PlayerMech"

func get_character_object():
	if current_mode == PLAYER_MODE.SHIP:
		return get_node(SHIP_NODE_NAME)
	elif current_mode == PLAYER_MODE.MECH:
		return get_node(MECH_NODE_NAME)
	else:
		return null

func update_mode():
	var ship_node = get_node_or_null(SHIP_NODE_NAME)
	var mech_node = get_node_or_null(MECH_NODE_NAME)
	
	if current_mode == PLAYER_MODE.SHIP:
		if mech_node != null:
			mech_node.queue_free()
		if ship_node == null:
			var scene_instance = ship_scene.instantiate()
			scene_instance.set_name(SHIP_NODE_NAME)
			scene_instance.position = vehicle_pos
			add_child(scene_instance)
	elif current_mode == PLAYER_MODE.MECH:
		if ship_node != null:
			ship_node.queue_free()
		if mech_node == null:
			var scene_instance = mech_scene.instantiate()
			scene_instance.sePlay_name(MECH_NODE_NAME)
			scene_instance.position = vehicle_pos
			add_child(scene_instance)

func _ready():
	vehicle_pos = spawn_point.position	
	update_mode()
	
	PlayerState.hud_throttle = hud_throttle

func _process(_delta):
	var vehicle = get_character_object()
	if vehicle == null:
		return # destroyed?
	
	vehicle_pos = vehicle.position
	
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
		
func on_hit_by_projectile(damage):
	hp -= damage
	if hp <= 0:
		hp = 0
		queue_free() # TODO proper death/respawn/etc logic

