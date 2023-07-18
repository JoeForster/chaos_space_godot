extends RigidBody2D

@export var lifetime = 1.0
@export var damage = 50

var despawn_timer = lifetime

func _process(delta):
	despawn_timer -= delta
	if despawn_timer <= 0:
		queue_free()


func _on_body_entered(body):
	if body.is_in_group("player"):
		var player_object = body.get_parent()
		player_object.on_hit_by_projectile(damage)
		queue_free()

