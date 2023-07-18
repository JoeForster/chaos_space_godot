extends Camera2D

@export var target : Node
@export var speed = 1000

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _physics_process(_delta):
	# TODO better way of getting at player pos
	# (since the player node no longer holds position, the vehicle child does)
	var player_vehicle =target.get_child(1)
	if player_vehicle != null:
		position = player_vehicle.position
