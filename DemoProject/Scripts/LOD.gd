extends Node3D

@export var mesh: Node3D
@export var billboard: Node3D
@export var billboard_distance: float = 100.0
@export var cull_distance: float = 500.0

var camera: Camera3D
var distance: float


func _ready() -> void:
	camera = get_viewport().get_camera_3d()


func _process(_delta: float) -> void:
	distance = camera.global_position.distance_to(position)
	
	if distance > cull_distance:
		mesh.visible = false
		billboard.visible = false
		return
	
	if (distance > billboard_distance):
		mesh.visible = false
		billboard.visible = true
	else:
		mesh.visible = true
		billboard.visible = false
