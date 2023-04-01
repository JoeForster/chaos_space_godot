extends Camera2D

@export var target : Node2D
@export var speed = 1000

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _physics_process(delta):
	position = target.position
