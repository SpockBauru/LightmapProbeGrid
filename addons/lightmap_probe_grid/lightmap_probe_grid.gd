@tool
extends Node3D
class_name LightmapProbeGrid

signal size_changed
signal probes_changed

const max_probes: int = 1000

@export_flags_3d_physics var collision_mask: int = 1

@export var size: Vector3 = Vector3.ONE:
	set(value):
		# size cannot be zero or negative
		size = value.clamp(Vector3(1E-6, 1E-6, 1E-6), Vector3.INF)
		size_changed.emit()
	get: 
		return size

var probes_number: Vector3i = Vector3i(2, 2, 2):
	set(value):
		probes_number = value
		set_probes_number()
	get: 
		return probes_number

var planned_probes: int = 8
var current_probes: int = 8

var old_size: Vector3 = Vector3.ONE
var old_scale: Vector3 = Vector3.ONE
var warned: bool = false

var far_distance: float = 1
var object_size: float = 1

var gizmo_lines: PackedVector3Array = []


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	
	properties.append({
		"name": "probes_number",
		"type": TYPE_VECTOR3I,
		"usage": PROPERTY_USAGE_STORAGE
	})
	
	properties.append({
		"name": "far_distance",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_STORAGE
	})
	
	properties.append({
		"name": "object_size",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_STORAGE
	})
	
	return properties


func _enter_tree() -> void:
	if get_child_count() < 1:
		generate_probes()


func _ready() -> void:
	size_changed.connect(scale_probes)
	set_notify_local_transform(true)
	old_size = size
	old_scale = scale
	current_probes = get_child_count()


# Keep local scale fixed. Reflect in "size" if the user try to scale
func _notification(what: int) -> void:
	if (what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED) and not scale.is_equal_approx(Vector3.ONE):
		if not warned:
			printerr("LightmapProbeGrid: Resetting Scale, please use the handles (red dots) or ",
					"the property \"Size\" in LightmapProbeGridsection")
			warned = true
		
		if(scale.x <= 0):
			scale = Vector3.ONE
			return
		
		# TODO take a look on this workaround
		var scale_diff: Vector3 = abs(scale - Vector3.ONE)
		var size_sign: Vector3 = sign(scale - old_scale)
		size += size_sign * scale_diff / 10.0
		
		old_scale = scale
		scale = Vector3.ONE


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if planned_probes > max_probes:
		var text: String = "LightmapProbeGrid: The maximum number of Probes must be " + \
				str(max_probes) + ". Please consider add more instances of LightmapProbeGrid"
		warnings.append(text)
		printerr(text)
	
	# Returning an empty array means "no warning".
	return warnings


func set_probes_number() -> void:
	planned_probes = probes_number.x * probes_number.y * probes_number.z
	update_configuration_warnings()
	probes_changed.emit()


func scale_probes() -> void:
	var new_size: Vector3 = size / old_size
	
	# Scaling all probes
	for probe: Node3D in get_children():
		probe.position *= new_size
	
	old_size = size


func generate_probes() -> void:
	# check number of probes
	if planned_probes > max_probes:
		return
	
	# Clear all previews probes
	for i: int in get_child_count():
		get_child(i).queue_free()
		# Wait for the last one to be cleaned
		if i == get_child_count() -1:
			await get_child(i).tree_exited
	
	# Defining probe arrays
	var probes_positions: Array[Vector3] = []
	var probes_names: Array[String] = []
	
	var probes_x: float = probes_number.x
	var probes_y: float = probes_number.y
	var probes_z: float = probes_number.z
	
	# Distance between probes
	var step_x: float = size.x / (probes_x - 1)
	var step_y: float = size.y / (probes_y - 1)
	var step_z: float = size.z / (probes_z - 1)
	
	# Starting positions
	var start_position: Vector3 = Vector3.ONE * size / 2.0
	var current_position: Vector3 = Vector3.ZERO
	
	# Defining Probes positions and names
	for x: float in probes_x:
		for y: float in probes_y:
			for z: float in probes_z:
				current_position.x = start_position.x - step_x * x
				current_position.y = start_position.y - step_y * y
				current_position.z = start_position.z - step_z * z
				probes_positions.append(current_position)
				probes_names.append("LightmapProbe %.f, %.f, %.f" % [x, y, z])
	
	# Generating probes
	var root_node: Node = get_tree().edited_scene_root
	
	for i: int in range(probes_positions.size()):
		var probe: LightmapProbe = LightmapProbe.new()
		probe.position = probes_positions[i]
		probe.name = probes_names[i]
		add_child(probe)
		probe.set_owner(root_node)
	
	current_probes = probes_number.x * probes_number.y * probes_number.z
	set_probes_number()


# Shoot rays from the center to all the probes. If any object is detected so the probe is
# obstructed and will be cut
func cut_obstructed() -> void:	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(position, position, collision_mask, [self])
	
	for probe: Node3D in get_children():
		query.to = position + probe.position
		var result = space_state.intersect_ray(query)
		
		if not result.is_empty():
			probe.queue_free()
			current_probes -= 1
		
		gizmo_lines.append_array([Vector3.ZERO, probe.position])
	
	set_probes_number()


# Detect if the probe is far from any object. It will shoot rays on all 6 axis and 8 quadrants.
# If there aren't any objects the probe will be cut
func cut_far():
	var objects: Array[int] = []
	
	for probe: Node3D in get_children():
		objects.clear()
		objects = test_six_axis(probe, far_distance, true)
		
		if objects.size() < 1:
			probe.queue_free()
			current_probes -= 1
	
	set_probes_number()


# Detect if probe is inside an object. It will shoot rays on all 6 axis and if at least 4 are in 
# the same object so the probe is inside and will be cut
func cut_inside():
	var objects: Array[int] = []
	var object_id: int = -1
	var count: int = 0
	
	# Test the 6 axis of each probe and count the number of times the same object is hit
	for probe: Node3D in get_children():
		objects.clear()
		objects = test_six_axis(probe, object_size, false)
		
		object_id = -1
		count = 0
		for i: int in range(objects.size()):
			if object_id == -1: 
				object_id = objects[i]
			if objects[i] == object_id:
				count += 1
		
		# Test only 4 sides instead of 6, because is normal to have objects without 2 sides
		# like pillars
		if count >= 4:
			probe.queue_free()
			current_probes -= 1
	
	set_probes_number()


## Test all 6 axis and 8 quadrants (optional) of a position and return the id's of objects collided
func test_six_axis(object: Node3D, distance: float, test_quadrants: bool) -> Array[int]:
	# 6 Axis
	var axis: Array[Vector3] = [
			Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(1, 0, 0), 
			Vector3(0, 0, -1), Vector3(0, -1, 0), Vector3(-1, 0, 0)
	]
	
	# 8 Quadrants
	var quadrants: Array[Vector3] = [
			Vector3(1, 1, 1).normalized(), Vector3(1, 1, -1).normalized(), 
			Vector3(1, -1, 1).normalized(),  Vector3(1, -1, -1).normalized(),
			Vector3(-1, 1, 1).normalized(), Vector3(-1, 1, -1).normalized(), 
			Vector3(-1, -1, 1).normalized(),  Vector3(-1, -1, -1).normalized()
	]
	
	var axis_and_quadrants: Array[Vector3] = axis
	if test_quadrants == true:
		axis_and_quadrants.append_array(quadrants)
	
	# Initialize space and query
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	# Initializing with dummy positions
	var query := PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.ONE, collision_mask, [self])
	query.hit_from_inside = true
	query.hit_back_faces = true
	
	# objects id returned by this function
	var objects: Array[int] = []
	
	# Raycasting each axis and quadrant (optional)
	for pos: Vector3 in axis_and_quadrants:
		query.from = object.global_position
		query.to = object.global_position + pos * distance
		var result = space_state.intersect_ray(query)
		
		if not result.is_empty():
			objects.append(result["collider_id"])
		else:
			# Making the other way around, because hit_back_faces don't always work
			query.from = object.global_position + pos * distance
			query.to = object.global_position
			result = space_state.intersect_ray(query)
			if not result.is_empty():
				objects.append(result["collider_id"])
		
		gizmo_lines.append_array([object.position, object.position + pos * distance])
	
	return objects
