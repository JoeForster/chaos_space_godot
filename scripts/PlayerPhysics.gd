extends RigidBody2D

enum INPUT_TYPE { KINEMATIC, HORIZONTAL_DIRECTIONAL, HORIZONTAL_THROTTLE, TOP_DOWN }

@export var input_type = INPUT_TYPE.HORIZONTAL_THROTTLE
@export var throttle_per_sec = 1.0
@export var max_speed = 400
@export var max_thrust = 500
@export var max_torque = 1000
@export var fixed_rotation_rate = 2.0
@export var world_bounds : CollisionShape2D
@export var brake_damp = 0.995

var input_throttle = 0.0
var input_directional = Vector2.ZERO
var braking = false
var default_linear_damp : float
var hack_rotation = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	default_linear_damp = linear_damp

func _physics_process_kinematic(delta):
	var velocity = input_directional

	if velocity.length() > 0:
		velocity = velocity.normalized() * max_speed

	position += velocity * delta
	
func _physics_process_horizontal_directional(delta):
	# TODO: tidy up once we figure out the best mode for this
	set_lock_rotation_enabled(true)
	
	if input_directional.x > 0:
		$PlayerSprite2D.set_flip_h(false)
	elif input_directional.x < 0:
		$PlayerSprite2D.set_flip_h(true)
	
	var facing_right = !$PlayerSprite2D.is_flipped_h()
	var thrust_local = (Vector2.RIGHT if facing_right else Vector2.LEFT) * input_throttle
	thrust_local *= max_thrust
	
	if thrust_local.length() > 0:
		if is_lock_rotation_enabled():
			var global_thrust = thrust_local.rotated(hack_rotation)
			apply_central_force(global_thrust)
		else:
			var global_thrust = transform.basis_xform(thrust_local)
			apply_central_force(global_thrust)

	#apply_torque(thrust_local.y * max_torque)
	var target_rotation = asin(input_directional.y)
	if facing_right:
		target_rotation = -target_rotation
	var cur_rotation = hack_rotation
	var new_rotation = cur_rotation


	var torque_tolerance = 1.0
	if target_rotation > new_rotation:
		new_rotation += fixed_rotation_rate * delta
		if new_rotation > target_rotation:
			new_rotation = target_rotation
	elif target_rotation < new_rotation:
		new_rotation -= fixed_rotation_rate * delta
		if new_rotation < target_rotation:
			new_rotation = target_rotation
	print("target_rotation: %f rotation: %f -> %f" % [target_rotation, cur_rotation, new_rotation])
	set_rotation(new_rotation)
	hack_rotation = new_rotation

func _physics_process_horizontal_throttle(delta):
	# TODO: tidy up once we figure out the best mode for this
	set_lock_rotation_enabled(true)
	
	if input_directional.x > 0:
		$PlayerSprite2D.set_flip_h(false)
	elif input_directional.x < 0:
		$PlayerSprite2D.set_flip_h(true)
	
	var facing_right = !$PlayerSprite2D.is_flipped_h()
	var thrust_local = (Vector2.RIGHT if facing_right else Vector2.LEFT) * input_throttle
	thrust_local *= max_thrust
	
	if thrust_local.length() > 0:
		if is_lock_rotation_enabled():
			var global_thrust = thrust_local.rotated(hack_rotation)
			apply_central_force(global_thrust)
		else:
			var global_thrust = transform.basis_xform(thrust_local)
			apply_central_force(global_thrust)

	#apply_torque(thrust_local.y * max_torque)
	var target_rotation = asin(input_directional.y)
	if facing_right:
		target_rotation = -target_rotation
	var cur_rotation = hack_rotation
	var new_rotation = cur_rotation


	var torque_tolerance = 1.0
	if target_rotation > new_rotation:
		new_rotation += fixed_rotation_rate * delta
		if new_rotation > target_rotation:
			new_rotation = target_rotation
	elif target_rotation < new_rotation:
		new_rotation -= fixed_rotation_rate * delta
		if new_rotation < target_rotation:
			new_rotation = target_rotation
	print("target_rotation: %f rotation: %f -> %f" % [target_rotation, cur_rotation, new_rotation])
	set_rotation(new_rotation)
	hack_rotation = new_rotation

func _physics_process_top_down(delta):
	
	set_lock_rotation_enabled(false)

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
	elif input_type == INPUT_TYPE.HORIZONTAL_DIRECTIONAL:
		_physics_process_horizontal_directional(delta)
	elif input_type == INPUT_TYPE.HORIZONTAL_THROTTLE:
		_physics_process_horizontal_throttle(delta)
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
	input_directional.x += Input.get_action_strength("move_right")
	input_directional.x -= Input.get_action_strength("move_left")
	input_directional.y += Input.get_action_strength("move_up")
	input_directional.y -= Input.get_action_strength("move_down")

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
			
