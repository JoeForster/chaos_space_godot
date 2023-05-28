extends RigidBody2D

@export var thrust = 100
@export var turnRate = 100

func _physics_process(delta):
	var global_thrust = transform.basis_xform(Vector2.RIGHT) * thrust
	apply_force(global_thrust)
	apply_torque(turnRate)
