extends Camera2D

@export var target : Node
@export var speed = 1000

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _physics_process(_delta):
	if target.is_class("Node2D"):
		position = target.position
	else:
		var player_vehicle = target.get_child(1)
		position = player_vehicle.position
