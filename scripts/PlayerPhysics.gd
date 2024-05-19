extends RigidBody2D

enum INPUT_TYPE { KINEMATIC, HORIZONTAL_DIRECTIONAL, HORIZONTAL_THROTTLE, TOP_DOWN }

@export var input_type = INPUT_TYPE.HORIZONTAL_THROTTLE
@export var throttle_per_sec = 1.0
@export var thrust_change_per_sec = 1000
@export var directional_min_lift = 1.0
@export var lift_thrust_proportion = 0.3
@export var lift_gravity_scaler = 0.5
@export var max_speed = 800
@export var max_thrust = 1000
@export var max_lift_thrust = 700
@export var max_thrust_y = 500
@export var max_torque = 1000
@export var fixed_rotation_rate = 2.0
@export var brake_damp = 0.995
@export var max_pitch_angle = deg_to_rad(60)

var input_throttle = lift_thrust_proportion
var current_thrust = 0.0
var input_directional = Vector2.ZERO
var input_look = Vector2.RIGHT
var braking = false
var default_linear_damp : float
var hack_rotation = 0
var world_bounds : CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready():
	world_bounds = get_node("../../World/WorldBounds")
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
	var thrust_local = Vector2.ZERO
	thrust_local.x = input_directional.x * max_thrust
	thrust_local.y = -input_directional.y * max_thrust_y

	# Apply "lift" by scaling gravity against thrust
	var cur_thrust_amount = thrust_local.length()
	var lift_value = lerpf(directional_min_lift, 1.0, cur_thrust_amount/max_thrust)
	var new_gravity_scale = 1.0 - lift_value
	set_gravity_scale(new_gravity_scale)

	if thrust_local.length() > 0:
		if is_lock_rotation_enabled():
			var global_thrust = thrust_local#.rotated(hack_rotation)
			apply_central_force(global_thrust)
		else:
			var global_thrust = transform.basis_xform(thrust_local)
			apply_central_force(global_thrust)

	#apply_torque(thrust_local.y * max_torque)
	var target_rotation = 0#clampf(asin(input_directional.y), -max_pitch_angle, max_pitch_angle)

	if facing_right:
		target_rotation = -target_rotation
	var cur_rotation = hack_rotation
	var new_rotation = cur_rotation

	if target_rotation > new_rotation:
		new_rotation += fixed_rotation_rate * delta
		if new_rotation > target_rotation:
			new_rotation = target_rotation
	elif target_rotation < new_rotation:
		new_rotation -= fixed_rotation_rate * delta
		if new_rotation < target_rotation:
			new_rotation = target_rotation
	#print("gravity: %f target_rotation: %f rotation: %f -> %f" % [gravity_scale, target_rotation, cur_rotation, new_rotation])
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
	
	# increment thrust gradually to target thrust based on our throttle input
	var thrust_local = Vector2.ZERO
	
	# First see if we're overriding thrust based on being out-of-bounds
	var global_thrust = Vector2.ZERO
	if world_bounds != null:
		var world_bounds_rect = world_bounds.shape.get_rect()
		world_bounds_rect.position += world_bounds.position
		
		if position.y < world_bounds_rect.position.y:
			global_thrust.y = 1
		# TODO delete probably, this is done by a wall for now
		##elif position.y > world_bounds_rect.end.y:
		#	global_thrust.y = -1
		
		##if position.x > world_bounds_rect.end.x:
		##	global_thrust.x = -1
		##elif position.x < world_bounds_rect.position.x:
		##	global_thrust.x = 1
	
	if global_thrust != Vector2.ZERO:
		global_thrust = global_thrust.normalized() * max_thrust
	else:
		# Thrust not being overridden, so take input
		var target_thrust = input_throttle * max_thrust

		if current_thrust < target_thrust:
			current_thrust = min(current_thrust + thrust_change_per_sec*delta, target_thrust)
		elif current_thrust > target_thrust:
			current_thrust = max(current_thrust - thrust_change_per_sec*delta, target_thrust)

		print("thrust: ", current_thrust)

		thrust_local.x = current_thrust
		if !facing_right:
			thrust_local.x *= -1

		# Apply "lift" by scaling gravity against thrust
		# TODO try doing by speed instead
		var cur_thrust_amount = thrust_local.length()
		var cur_thrust_proportion = cur_thrust_amount / max_thrust
		assert(cur_thrust_proportion >= 0.0)
		assert(cur_thrust_proportion <= 1.0)
		var new_gravity_scale = 1.0 - min(1.0, cur_thrust_proportion / lift_thrust_proportion)
		new_gravity_scale *= lift_gravity_scaler
		set_gravity_scale(new_gravity_scale)	
	
		if thrust_local.length() > 0:
			if is_lock_rotation_enabled():
				global_thrust = thrust_local.rotated(hack_rotation)
			else:
				global_thrust = transform.basis_xform(thrust_local)

	# Finally we can apply the thrust force if we had any
	if global_thrust != Vector2.ZERO:
		apply_central_force(global_thrust)

	# Now do rotation (fixed for now)
	#apply_torque(thrust_local.y * max_torque)
	var target_rotation = clampf(asin(input_directional.y), -max_pitch_angle, max_pitch_angle)
	if facing_right:
		target_rotation = -target_rotation
	var cur_rotation = hack_rotation
	var new_rotation = cur_rotation

	if target_rotation > new_rotation:
		new_rotation += fixed_rotation_rate * delta
		if new_rotation > target_rotation:
			new_rotation = target_rotation
	elif target_rotation < new_rotation:
		new_rotation -= fixed_rotation_rate * delta
		if new_rotation < target_rotation:
			new_rotation = target_rotation
	#print("gravity: %f target_rotation: %f rotation: %f -> %f" % [gravity_scale, target_rotation, cur_rotation, new_rotation])
	#print("throttle: %f" % [input_throttle])
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
	
	#var bodies = get_colliding_bodies()
	#print("Player colliding with %d bodies" % [bodies.size()])
	
	var facing_right_sign = 1 if !$PlayerSprite2D.is_flipped_h() else -1
	$ShipCollision.scale.x = facing_right_sign
	
	
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
	
	input_look = Vector2.ZERO
	input_look.x += Input.get_action_strength("look_right")
	input_look.x -= Input.get_action_strength("look_left")
	input_look.y += Input.get_action_strength("look_up")
	input_look.y -= Input.get_action_strength("look_down")

	# Process throttle input and logic, which depends on the input mode.

	var throttle_delta = delta * throttle_per_sec
	if input_type == INPUT_TYPE.HORIZONTAL_THROTTLE || input_type == INPUT_TYPE.TOP_DOWN:
		if Input.is_action_pressed("throttle_up"):
			input_throttle = min(1.0, input_throttle + throttle_delta)
		if Input.is_action_pressed("throttle_down"):
			input_throttle = max(0.0, input_throttle - throttle_delta)
			braking = (input_throttle == 0.0)
		else:
			braking = false
	elif input_type == INPUT_TYPE.HORIZONTAL_DIRECTIONAL:
		var facing_right_sign = 1 if !$PlayerSprite2D.is_flipped_h() else -1
		var throttle_rate_signed = input_directional.x * facing_right_sign
		if throttle_rate_signed > 0:
			input_throttle = min(1.0, input_throttle + throttle_rate_signed * throttle_delta)
		else:
			input_throttle = max(0.0, input_throttle - throttle_delta)
		braking = false
		

	if PlayerState.hud_throttle != null:
		PlayerState.hud_throttle.value = input_throttle

	# TODO proper level transition manager; background
	if Input.is_action_just_released("use"):
		# todo make this less shit
		var current_scene = get_tree().current_scene.name
		if !current_scene.contains("solarsystem_"):
			get_tree().change_scene_to_file("res://scenes/"+PlayerState.current_system+".tscn")
			
	
	# TODO switch activated node between the rigidbody and character thingy	
	#if Input.is_action_just_released("ability"):
