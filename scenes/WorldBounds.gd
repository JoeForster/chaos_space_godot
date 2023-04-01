extends CollisionShape2D

@export var playerCamera : Camera2D

# Called when the node enters the scene tree for the first time.
func _ready():
	var worldBoundsShape = shape.get_rect().abs()
	playerCamera.limit_bottom = worldBoundsShape.end.y + position.y
	playerCamera.limit_left = worldBoundsShape.position.x + position.x
	playerCamera.limit_right = worldBoundsShape.end.x + position.x
	playerCamera.limit_top = worldBoundsShape.position.y + position.y
