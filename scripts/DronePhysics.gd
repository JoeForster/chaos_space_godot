extends RigidBody2D

@export var thrust = 100
@export var turnRate = 100
@export var target : Node
@export var projectile_scene : Resource
@export var projectile_offset = 100
@export var projectile_shoot_cooldown = 1.0
@export var projectile_speed = 800.0

enum DroneState
{
	SHOOT
}

var state = DroneState.SHOOT
var shoot_timer = projectile_shoot_cooldown

func spawn_projectile(to_target : Vector2):
	assert(to_target.is_normalized())
	var scene_instance : RigidBody2D = projectile_scene.instantiate()
	var offset_rotated = to_target * projectile_offset
	scene_instance.position = position + offset_rotated
	scene_instance.linear_velocity = to_target * projectile_speed
	scene_instance.rotation = Vector2.UP.angle_to(to_target)
	add_sibling(scene_instance)


func _physics_process(_delta):
	# TODO better way of getting at player pos
	# (since the player node no longer holds position, the vehicle child does)
	var global_thrust = Vector2.ZERO
	if target:
		var player_vehicle = target.get_child(1)
		if player_vehicle:
			var to_target = player_vehicle.position - position
			if !to_target.is_zero_approx():
				global_thrust = to_target.normalized()
		
	global_thrust *= thrust

	apply_force(global_thrust)

func _update_shoot(delta):
	if target == null:
		return; # Nothing to shoot

	shoot_timer -= delta
	if shoot_timer <= 0:
		var player_vehicle = target.get_child(1)

		if player_vehicle:
			var to_target : Vector2 = player_vehicle.position - position
			spawn_projectile(to_target.normalized())

		shoot_timer = projectile_shoot_cooldown

func _process(delta):
	if state == DroneState.SHOOT:
		_update_shoot(delta)
