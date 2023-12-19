extends CharacterBody3D

@export var character: Node3D
@export var animation_tree: AnimationTree
@export var camera: Node3D
@export var speed: float= 3
@export var jump_velocity: float = 5
@export var mouse_sensitivity: float = .002

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Show/Hide mouse in the game window
var mouse_visible : bool = false

var is_jumping: bool = false


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
	
	# Rotating camera
	if event is InputEventMouseMotion and not mouse_visible:
		var mouseInput: InputEventMouseMotion = event
		camera.rotation.y -= mouseInput.relative.x * mouse_sensitivity
		camera.rotation.x -= mouseInput.relative.y * mouse_sensitivity
		
		# Limiting camera rotation
		camera.rotation.x = clamp(camera.rotation.x, -PI/3, PI/3)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	# Reset animation state
	animation_tree["parameters/conditions/is_idle"] = false
	animation_tree["parameters/conditions/is_running"] = false
	animation_tree["parameters/conditions/is_jumping"] = false
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		animation_tree["parameters/conditions/is_jumping"] = true
		move_and_slide()
		return
	
	# Handle jump
	if Input.is_action_just_pressed("player_jump") and is_on_floor():
		velocity.y = jump_velocity
		animation_tree["parameters/conditions/is_jumping"] = true
		return
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir: Vector2 = Input.get_vector("player_left", "player_right", "player_forward", "player_backward")
	
	# Face the camera direction when player make a input
	var camera_direction : Vector3 = camera.global_transform.basis.z
	var forward: Vector3 = Vector3(camera_direction.x, 0, camera_direction.z).normalized()
	var sideways: Vector3 = camera_direction.cross(Vector3.UP).normalized()
	# Apply input direction
	forward *= input_dir.y
	sideways *= input_dir.x
	var direction: Vector3 = (forward - sideways).normalized()
	
	if input_dir:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		animation_tree["parameters/conditions/is_running"] = true
		
		# Rotate character to the direction
		var rotation_y: float =  -direction.signed_angle_to(Vector3.FORWARD, Vector3.UP)
		character.rotation.y = rotation_y - global_rotation.y
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		animation_tree["parameters/conditions/is_idle"] = true
	
	move_and_slide()
	
	
	# If is stuck in wall
	if abs(velocity) < Vector3(0.001, 0.001, 0.001):
		animation_tree["parameters/conditions/is_idle"] = true
		animation_tree["parameters/conditions/is_running"] = false
		animation_tree["parameters/conditions/is_jumping"] = false

