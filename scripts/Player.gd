extends RigidBody2D

@export var use_thrust = true
@export var speed = 400 # How fast the player will move (pixels/sec).
@export var max_thrust = 500
@export var max_torque = 700
@export var world_bounds : CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _update_kinematic(delta):
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed

	position += velocity * delta
	
func _update_thrust(delta):
	
	var thrust_local = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		thrust_local.x += 1
	if Input.is_action_pressed("move_left"):
		thrust_local.x -= 1
	if Input.is_action_pressed("move_down"):
		thrust_local.y += 1
	if Input.is_action_pressed("move_up"):
		thrust_local.y -= 1

	if thrust_local.length() > 0:
		var thrust_local_norm = thrust_local.normalized()
		var global_thrust = transform.basis_xform(thrust_local_norm * max_thrust)
		apply_force(global_thrust)
	
		# Rotate towards horizontal
		if thrust_local_norm.y == 0:
			if global_thrust.y > 0:
				apply_torque(-thrust_local.x * max_torque)
			else:
				apply_torque(-thrust_local.x * -max_torque)

		$PlayerSprite2D.set_flip_h(thrust_local_norm.x < 0)
		
	
		
func _keep_in_bounds():
	var worldBoundsShape = world_bounds.shape.get_rect().abs()
	position.x = clamp(position.x, worldBoundsShape.position.x, worldBoundsShape.end.x)
	position.y = clamp(position.y, worldBoundsShape.position.y, worldBoundsShape.end.y)

# Called every physics update
func _physics_process(delta):
	# HACK TEST - this isn't too great as it causes it to penetrate obstacles
	if rotation_degrees > 45:
		rotation_degrees = 45
	if rotation_degrees < -45:
		rotation_degrees = -45
	_update_thrust(delta)
	
