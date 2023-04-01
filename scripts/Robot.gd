extends CharacterBody2D

const SPEED = 100
const FALL_SPEED = 50
const FALL_TEST_MARGIN = 10

var moveDirection = 1
var gravityDirection = Vector2(0, 1)

func _update_fall_test():
	var p = position
	var projected_position = Vector2.ZERO
	var collision_rect = $MainCollisionShape.get_shape().get_rect().size
	projected_position.x += moveDirection * (collision_rect.x + FALL_TEST_MARGIN)
	projected_position += gravityDirection * collision_rect.y
	$FallTest.position = projected_position

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play("idle")
	_update_fall_test()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_on_floor():
		var will_be_on_floor = $FallTest.has_overlapping_bodies()
		if will_be_on_floor:
			velocity.y = 0
			velocity.x = moveDirection * SPEED
			move_and_slide()
		else:
			moveDirection *= -1
			
		$AnimatedSprite2D.play("run")
	else:
		var hit_floor = move_and_collide(gravityDirection * FALL_SPEED * delta)
		if hit_floor:
			velocity.y = 0
			velocity.x = moveDirection * SPEED
			move_and_slide()
		
		$AnimatedSprite2D.play("idle")
	
	
	$AnimatedSprite2D.set_flip_h(moveDirection < 0)
	
	_update_fall_test()
