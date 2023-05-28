extends CharacterBody2D

const SPEED = 100
const FALL_SPEED = 50
const FALL_TEST_MARGIN = 10

var moveDirection = 1
var gravityDirection = Vector2(0, 1)

# TODO hacky, could do better prediction based on speed (use physics step?)
func _update_fall_test():
	var p = position
	var projected_position_relative = Vector2.ZERO
	projected_position_relative.x = moveDirection * FALL_TEST_MARGIN
	projected_position_relative += gravityDirection * FALL_TEST_MARGIN
	$FallTest.position = projected_position_relative

func _ready():
	#$AnimatedSprite2D.play("idle")
	_update_fall_test()

func _process(delta):
	if is_on_floor():
		var will_be_on_floor = $FallTest.has_overlapping_bodies()
		if will_be_on_floor:
			velocity.y = 0
			velocity.x = moveDirection * SPEED
			move_and_slide()
		else:
			moveDirection *= -1
			
		#$AnimatedSprite2D.play("run")
	else:
		var hit_floor = move_and_collide(gravityDirection * FALL_SPEED * delta)
		if hit_floor:
			velocity.y = 0
			velocity.x = moveDirection * SPEED
			move_and_slide()
		
		#$AnimatedSprite2D.play("idle")
	
	
	#$AnimatedSprite2D.set_flip_h(moveDirection < 0)
	
	_update_fall_test()
