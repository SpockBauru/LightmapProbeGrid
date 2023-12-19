extends CharacterBody3D

@export var SPEED: float= 5.0
@export var JUMP_VELOCITY: float = 4.5
@export var mouse_sensitivity: float = .002

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Show/Hide mouse in the game window
var mouse_visible : bool = false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	# Show/Hide mouse
	if Input.is_action_just_pressed("ui_cancel"):
		if mouse_visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		mouse_visible = not mouse_visible
	
	# Rotating character
	if event is InputEventMouseMotion and not mouse_visible:
		var mouseInput: InputEventMouseMotion = event
		rotation.y -= mouseInput.relative.x * mouse_sensitivity
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("player_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir: Vector2 = Input.get_vector("player_left", "player_right", "player_forward", "player_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
	# Getting around small bumps	
	for i: int in get_slide_collision_count():
		var collider: KinematicCollision3D = get_slide_collision(i)
		var normal: float = collider.get_normal().y
		if normal > 0.5 and normal < 0.8:
			velocity.y = 2
