extends RigidBody2D

enum INPUT_TYPE { KINEMATIC, HORIZONTAL, THROTTLE, TOP_DOWN }

@export var input_type = INPUT_TYPE.THROTTLE
@export var throttle_per_sec = 1.0
@export var max_speed = 400
@export var max_thrust = 500
@export var max_torque = 1000
@export var world_bounds : CollisionShape2D
@export var brake_damp = 0.995

var input_throttle = 0.0
var input_directional = Vector2.ZERO
var braking = false
var default_linear_damp : float
var move

# Called when the node enters the scene tree for the first time.
func _ready():
	default_linear_damp = linear_damp

func _physics_process_kinematic(delta):
	var velocity = input_directional

	if velocity.length() > 0:
		velocity = velocity.normalized() * max_speed

	position += velocity * delta
	
func _physics_process_horizontal(delta):
	# TODO we want to limit the angle somehow to prevent flipping, but this
	# breaks the torque effect once beyond the angle
	#if get_rotation_degrees() > 45:
	#	set_rotation_degrees(45)
	#if rotation_degrees < -45:
	#	set_rotation_degrees(-45)	
	
	var thrust_local = input_directional


	if thrust_local.length() > 0:
		var thrust_local_norm = thrust_local.normalized()
		var global_thrust = transform.basis_xform(thrust_local_norm * max_thrust)
		apply_force(global_thrust)
		#apply_force(thrust_local * max_thrust)
		$PlayerSprite2D.set_flip_h(thrust_local_norm.x < 0)

	var facing_right = $PlayerSprite2D.is_flipped_h()
	
	# Rotate towards horizontal
	var rotation = get_rotation()
	var rotation_threshold = max(0.01, abs(get_angular_velocity()) * delta * 2)
	print(rotation_threshold)
	if abs(rotation) < rotation_threshold:
		set_angular_velocity(0)
	elif rotation > 0:
		print("torque up!")
		apply_torque(-thrust_local.x * max_torque)
	else:
		print("torque down!")
		apply_torque(-thrust_local.x * -max_torque)

# TODO rename to be clear this is side-on
func _physics_process_throttle(delta):
	var facing_right = $PlayerSprite2D.is_flipped_h()
	var thrust_local = (Vector2.RIGHT if facing_right else Vector2.LEFT) * input_throttle
	thrust_local *= max_thrust
	
	if thrust_local.length() > 0:
		var global_thrust = transform.basis_xform(thrust_local)
		apply_force(global_thrust)
		
	apply_torque(input_directional.y * max_torque)

func _physics_process_top_down(delta):
	var thrust_local = Vector2.RIGHT * input_throttle * max_thrust
	
	if thrust_local.length() > 0:
		var global_thrust = transform.basis_xform(thrust_local)
		apply_force(global_thrust)

	linear_damp = brake_damp if braking else default_linear_damp
		
	apply_torque(input_directional.x * max_torque)

func _keep_in_bounds():
	if world_bounds != null:
		var worldBoundsShape = world_bounds.shape.get_rect().abs()
		position.x = clamp(position.x, worldBoundsShape.position.x, worldBoundsShape.end.x)
		position.y = clamp(position.y, worldBoundsShape.position.y, worldBoundsShape.end.y)

# Called every physics update
func _physics_process(delta):
		
	#print("POS IS NOW %f, %f" % [position.x, position.y])
	
	if input_type == INPUT_TYPE.KINEMATIC:
		_physics_process_kinematic(delta)
	elif input_type == INPUT_TYPE.HORIZONTAL:
		_physics_process_horizontal(delta)
	elif input_type == INPUT_TYPE.THROTTLE:
		_physics_process_throttle(delta)
	elif input_type == INPUT_TYPE.TOP_DOWN:
		_physics_process_top_down(delta)
	
	linear_velocity.limit_length(max_speed)
	
func _integrate_forces(state):
	# On returning from a planet or galaxy map, place the ship in the correct warp/planet position
	# TODO is there a less hacky way to do this? Probably create/spawn the ship on scene change rather than moving.
	var current_scene = get_tree().current_scene.name
	if current_scene.contains("solarsystem_"):
		var spawn_pos = null
		if PlayerState.system_pos_set:
			spawn_pos = PlayerState.system_pos
			PlayerState.system_pos_set = false
			
		if PlayerState.warping_in:
			var warp_point = get_node("../WarpPoint")
			if warp_point != null:
				spawn_pos = warp_point.position				

			PlayerState.warping_in = false
			
		if spawn_pos != null:
			var t = state.get_transform()
			t.origin.x = spawn_pos.x
			t.origin.y = spawn_pos.y
			state.set_transform(t)

func _process(delta):
	# Logical update: take inputs and process
	input_directional = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		input_directional.x += 1
	if Input.is_action_pressed("move_left"):
		input_directional.x -= 1
	if Input.is_action_pressed("move_down"):
		input_directional.y += 1
	if Input.is_action_pressed("move_up"):
		input_directional.y -= 1
	if Input.is_action_pressed("throttle_up"):
		input_throttle = min(1.0, input_throttle + delta * throttle_per_sec)
	if Input.is_action_pressed("throttle_down"):
		input_throttle = max(0.0, input_throttle - delta * throttle_per_sec)
		braking = (input_throttle == 0.0)
	else:
		braking = false

	# TODO proper level transition manager; background
	if Input.is_action_just_released("use"):
		# todo make this less shit
		var current_scene = get_tree().current_scene.name
		if !current_scene.contains("solarsystem_"):
			get_tree().change_scene_to_file("res://scenes/"+PlayerState.current_system+".tscn")
			
	
	# TODO switch activated node between the rigidbody and character thingy	
	#if Input.is_action_just_released("ability"):
			
