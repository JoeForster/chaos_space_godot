extends CharacterBody2D

const SPEED = 500
const FALL_ACCEL = 980
const FALL_TEST_MARGIN = 10

var moveDirection = 1
var gravityDirection = Vector2(0, 1)
var fallSpeed = 0

# TODO hacky, could do better prediction based on speed (use physics step?)
func _update_fall_test():
	var projected_position_relative = Vector2.ZERO
	projected_position_relative.x = moveDirection * FALL_TEST_MARGIN
	projected_position_relative += gravityDirection * FALL_TEST_MARGIN
	$FallTest.position = projected_position_relative

func _ready():
	#$AnimatedSprite2D.play("idle")
	_update_fall_test()

func _process(delta):
	
	var on_floor = is_on_floor()
	
	if !on_floor:
		fallSpeed += FALL_ACCEL * delta
		var hit_floor = move_and_collide(gravityDirection * fallSpeed * delta)
		if hit_floor:
			velocity.y = 0
			on_floor = true
		
		#$AnimatedSprite2D.play("idle")
	
	
	if on_floor:	
		if Input.is_action_pressed("move_right"):
			$PlayerSprite2D.set_flip_h(false)
			velocity.x = SPEED
		elif Input.is_action_pressed("move_left"):
			$PlayerSprite2D.set_flip_h(true)
			velocity.x = -SPEED
		else:
			velocity.x = 0

		move_and_slide()
		#$AnimatedSprite2D.play("run")
	
	
	_update_fall_test()
