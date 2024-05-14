@tool
extends Node3D
class_name LightmapProbeGrid

signal size_changed
signal probes_changed

const max_probes: int = 1000

## Only selected layers will be seen by LightmapProbeGrid. Works like Camera3D Cull Mask.[br][br]
## NOTE: NOT compatible with LightmapProbeGrid v1.0
@export_flags_3d_render var visual_cull_mask: int = 1048575

@export var size: Vector3 = Vector3.ONE:
	set(value):
		# size cannot be zero or negative
		size = value.clamp(Vector3(1E-6, 1E-6, 1E-6), Vector3.INF)
		size_changed.emit()
	get: 
		return size

@onready var depth_shader: Shader = preload("Depth.gdshader")

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

var godot_version: int = Engine.get_version_info().hex


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
	
	# Distance between probes
	# step = size / (probes_number - 1)
	var step: Vector3 = size / Vector3(probes_number - Vector3i.ONE)
	
	# Starting relative positions
	var start_position: Vector3 = Vector3.ONE * size / 2.0
	var current_position: Vector3 = Vector3.ZERO
	
	# Defining Probes relative positions and names
	for x: float in probes_number.x:
		for y: float in probes_number.y:
			for z: float in probes_number.z:
				current_position = start_position - step * Vector3(x, y, z)
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


# Workaround to raycast without colliders. Consists in a camera with a filter in front that shows 
# the depth texture. The camera.far is the "ray" lenght and camera rotation is the "ray" orientation
# https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html#depth-texture
func add_GPU_raycaster(probe: Node3D) -> void:
	var root_node: Node = get_tree().edited_scene_root
	
	# SubViewport that will host the camera
	var sub_viewport: SubViewport = SubViewport.new()
	sub_viewport.name = "GPUraycast"
	sub_viewport.size = Vector2(2, 2)
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	sub_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	sub_viewport.handle_input_locally = false
	sub_viewport.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
	
	sub_viewport.positional_shadow_atlas_size = 0
	sub_viewport.positional_shadow_atlas_quad_0 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED
	sub_viewport.positional_shadow_atlas_quad_1 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED
	sub_viewport.positional_shadow_atlas_quad_2 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED
	sub_viewport.positional_shadow_atlas_quad_3 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED
	
	probe.add_child(sub_viewport)
	sub_viewport.set_owner(root_node)
	
	# Camera for the viewport
	var camera_3d: Camera3D = Camera3D.new()
	camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera_3d.size = 0.001
	camera_3d.near = 0.001
	camera_3d.far = 1.0
	sub_viewport.add_child(camera_3d)
	camera_3d.set_owner(root_node)
	camera_3d.position = probe.global_position
	camera_3d.rotation = Vector3.ZERO
	camera_3d.cull_mask = visual_cull_mask
	
	# Depth filter: A quad with a material that shows the Depth texture. This goes in front of the
	# camera
	var depth_material: ShaderMaterial = ShaderMaterial.new()
	depth_material.shader = depth_shader
	
	var depth_filter: MeshInstance3D = MeshInstance3D.new()
	var depth_mesh: QuadMesh = QuadMesh.new()
	depth_filter.mesh = depth_mesh
	depth_mesh.material = depth_material
	depth_mesh.size = Vector2.ONE * 0.001
	camera_3d.add_child(depth_filter)
	depth_filter.set_owner(root_node)
	depth_filter.position = Vector3(0, 0, -0.002)
	depth_filter.rotation = Vector3.ZERO


func generate_probes_raycasters(distance: float) -> void:
	for probe in get_children():
		add_GPU_raycaster(probe)


func remove_probes_raycasters() -> void:
	for probe in get_children():
		for child in probe.get_children():
			child.queue_free();


# The function look_at not always work. Exceptions are handled here
func rotate_camera(camera: Camera3D, to: Vector3) -> void:
	var from: Vector3 = camera.position
	# look_at don't work if the node and target have the same position. You cannot look at yourself
	if from == to:
		return
	
	# look_at don't work if the direction and rotation axix have same orientation. In this case,
	# change the rotation axis
	var direction: Vector3 = abs(to - from)
	var mag = (direction.normalized() - Vector3.UP).length()
	if mag > 0.001:
		camera.look_at(to)
	else:
		camera.look_at(to, Vector3.RIGHT)


# Shoot rays from the center to all the probes. If any object is detected so the probe is
# obstructed and will be cut
func cut_obstructed() -> void:
	await generate_probes_raycasters(far_distance)
	
	var probes_array: Array[LightmapProbe] = []
	var camera_array: Array[Camera3D] = []
	var subViewport_array: Array[SubViewport] = []
	var results_array: Array[float] = []
	
	# Populating arrays
	for probe: LightmapProbe in get_children():
		probes_array.append(probe)
		gizmo_lines.append_array([Vector3.ZERO, probe.position])
		var sub_viewport: SubViewport = probe.get_child(0)
		subViewport_array.append(sub_viewport)
		var camera: Camera3D = sub_viewport.get_child(0)
		camera_array.append(camera)
	
	# Rotating cameras and updating sub_viewports
	for i in range(camera_array.size()):
		var camera: Camera3D = camera_array[i]
		var probe_pos: Vector3 = probes_array[i].global_position
		var sub_viewport: SubViewport = subViewport_array[i]
		
		camera.position = position
		# The lenght of the "Ray"
		camera.far = (probe_pos - position).length()
		# The direction of the "Ray"
		rotate_camera(camera, probe_pos)
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# Getting the values
	await  RenderingServer.frame_post_draw
	for i in range(subViewport_array.size()):
		var sub_viewport = subViewport_array[i]
		var texture: Image = sub_viewport.get_texture().get_image()
		var color: Color = texture.get_pixel(0,0)
		var colorValue: float = color.r
		var result: float = colorValue
		results_array.append(result)
	
	# Cutting probes
	for i in range(subViewport_array.size()):
		var result: float = results_array[i]
		
		# On Godot 4.3+, the depth texture was inverted
		if godot_version >= 0x040300:
			result = 1.0 - result

		if result < 1.0:
			var probe = probes_array[i]
			probe.queue_free()
			current_probes -= 1
	
	set_probes_number()
	remove_probes_raycasters()


# Detect if the probe is far from any object. It will shoot rays on all 6 axis and 8 quadrants.
# If there aren't any objects the probe will be cut
func cut_far() -> void:
	await generate_probes_raycasters(far_distance)
	
	# 6 axis and 8 quadrants
	var directions: Array[Vector3] = [
		# 6 Axis
			Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(1, 0, 0), 
			Vector3(0, 0, -1), Vector3(0, -1, 0), Vector3(-1, 0, 0),
		# 8 Quadrants
			Vector3(1, 1, 1).normalized(), Vector3(1, 1, -1).normalized(), 
			Vector3(1, -1, 1).normalized(),  Vector3(1, -1, -1).normalized(),
			Vector3(-1, 1, 1).normalized(), Vector3(-1, 1, -1).normalized(), 
			Vector3(-1, -1, 1).normalized(),  Vector3(-1, -1, -1).normalized()
	]
	
	var probes_array: Array[LightmapProbe] = []
	var camera_array: Array[Camera3D] = []
	var subViewport_array: Array[SubViewport] = []
	var collisions_number: Array[int] = []
	
	# Populating arrays
	for probe: LightmapProbe in get_children():
		probes_array.append(probe)
		var sub_viewport: SubViewport = probe.get_child(0)
		subViewport_array.append(sub_viewport)
		var camera: Camera3D = sub_viewport.get_child(0)
		camera_array.append(camera)
	collisions_number.resize(camera_array.size())
	collisions_number.fill(0)
	
	# Getting data for all cameras on each direction
	for dir in directions:
		# Rotating all cameras to the same direction, and updating viewport
		for i in camera_array.size():
			var probe: LightmapProbe = probes_array[i]
			var sub_viewport: SubViewport = subViewport_array[i]
			var camera: Camera3D = camera_array[i]
			
			camera.position = probe.global_position
			# The lenght of the "Ray"
			camera.far = far_distance
			# The direction of the "Ray"
			rotate_camera(camera, probe.global_position + dir)
			sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			
			gizmo_lines.append_array([probe.position, probe.position + dir * far_distance])
		
		# Getting all values for the current direction
		await  RenderingServer.frame_post_draw
		for i in range(subViewport_array.size()):
			var sub_viewport = subViewport_array[i]
			var texture: Image = sub_viewport.get_texture().get_image()
			var color: Color = texture.get_pixel(0,0)
			var colorValue: float = color.r
			var result: float = colorValue
			
			# On Godot 4.3+, the depth texture was inverted
			if godot_version >= 0x040300:
				result = 1.0 - result
			
			if result < 1.0:
				collisions_number[i] += 1
	
	# Cut probes if there are no collisions
	for i in probes_array.size():
		if collisions_number[i] < 1:
			var probe = probes_array[i]
			probe.queue_free()
			current_probes -= 1
	
	set_probes_number()
	remove_probes_raycasters()


# Detect if probe is inside an object. It will shoot rays from all 6 axis to the probe. If at least
# 4 are obstructed, the probe will be cut
func cut_inside() -> void:
	await generate_probes_raycasters(far_distance)
	
	# 6 Axis
	var axis: Array[Vector3] = [
			Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(1, 0, 0), 
			Vector3(0, 0, -1), Vector3(0, -1, 0), Vector3(-1, 0, 0),
	]
	
	var probes_array: Array[LightmapProbe] = []
	var camera_array: Array[Camera3D] = []
	var subViewport_array: Array[SubViewport] = []
	var collisions_number: Array[int] = []
	
	# Populating arrays
	for probe: LightmapProbe in get_children():
		probes_array.append(probe)
		var sub_viewport: SubViewport = probe.get_child(0)
		subViewport_array.append(sub_viewport)
		var camera: Camera3D = sub_viewport.get_child(0)
		camera_array.append(camera)
	collisions_number.resize(camera_array.size())
	collisions_number.fill(0)
	
	# Getting data for all cameras on each axis
	for dir in axis:
		# For each direction, position all cameras to look from outside 
		# to each probe in object_size distance
		for i in camera_array.size():
			var probe: LightmapProbe = probes_array[i]
			var sub_viewport: SubViewport = subViewport_array[i]
			var camera: Camera3D = camera_array[i]
			
			camera.position = probe.global_position + dir * object_size
			# The lenght of the "Ray"
			camera.far = object_size
			# The direction of the "Ray"
			rotate_camera(camera, probe.global_position)
			sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			
			gizmo_lines.append_array([probe.position, probe.position + dir * object_size])
		
		# Getting all values for the current direction
		await  RenderingServer.frame_post_draw
		for i in range(subViewport_array.size()):
			var sub_viewport = subViewport_array[i]
			var texture: Image = sub_viewport.get_texture().get_image()
			var color: Color = texture.get_pixel(0,0)
			var colorValue: float = color.r
			var result: float = colorValue
			
			# On Godot 4.3+, the depth texture was inverted
			if godot_version >= 0x040300:
				result = 1.0 - result
			
			if result < 1.0:
				collisions_number[i] += 1
	
	# Cut probes if there are more than 4 collisions
	for i in probes_array.size():
		if collisions_number[i] > 3:
			var probe = probes_array[i]
			probe.queue_free()
			current_probes -= 1
	
	set_probes_number()
	remove_probes_raycasters()

