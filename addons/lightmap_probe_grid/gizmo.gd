# my_custom_gizmo_plugin.gd
extends EditorNode3DGizmoPlugin

const handles_axis: PackedVector3Array = [
	Vector3(1, 0, 0),
	Vector3(0, 1, 0),
	Vector3(0, 0, 1),
	Vector3(-1, 0, 0),
	Vector3(0, -1, 0),
	Vector3(0, 0, -1)
]

const box_lines: PackedVector3Array = [
	# plane -x
	Vector3(-1, -1, -1), Vector3(-1, -1, 1),
	Vector3(-1, -1, 1), Vector3(-1, 1, 1),
	Vector3(-1, 1, 1), Vector3(-1, 1, -1),
	Vector3(-1, 1, -1), Vector3(-1, -1, -1),
	# plane +x
	Vector3(1, -1, -1), Vector3(1, -1, 1),
	Vector3(1, -1, 1), Vector3(1, 1, 1),
	Vector3(1, 1, 1), Vector3(1, 1, -1),
	Vector3(1, 1, -1), Vector3(1, -1, -1),
	# connecting plane x with -x
	Vector3(1, -1, -1), Vector3(-1, -1, -1),
	Vector3(1, -1, 1), Vector3(-1, -1, 1),
	Vector3(1, 1, -1), Vector3(-1, 1, -1),
	Vector3(1, 1, 1), Vector3(-1, 1, 1),
]

var icon: Texture2D = preload("lightmap_probe_grid_icon.svg")

var timer: Timer = Timer.new()
var is_awayting: bool = false


func _get_gizmo_name() -> String:
	return "LightmapProbeGrid"


func _init() -> void:
	create_material("main_material", Color(0,0,0))
	create_material("tool_material", Color(1, 0.9, 0))
	create_handle_material("handles_material")
	create_icon_material("icon_material", icon)


func _has_gizmo(node: Node3D) -> bool:
	if node is LightmapProbeGrid:
		if not node.size_changed.is_connected(node.update_gizmos):
			node.size_changed.connect(node.update_gizmos)
		if not node.probes_changed.is_connected(node.update_gizmos):
			node.probes_changed.connect(node.update_gizmos)
		return true
	else:
		return false


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var box: LightmapProbeGrid = gizmo.get_node_3d() as LightmapProbeGrid
	var size: Vector3 = box.size
	
	var icon_gizmo: Material = get_material("icon_material")
	gizmo.add_unscaled_billboard(icon_gizmo, 0.05)
	
	# Setting box lines
	var lines: PackedVector3Array = []
	for pos: Vector3 in box_lines:
		var scaled: Vector3 = 0.5 * pos * size
		lines.append(scaled)
	gizmo.add_lines(lines, get_material("main_material", gizmo))
	
	# Setting handles
	var handles: PackedVector3Array = []
	for pos: Vector3 in handles_axis:
		var scaled: Vector3 = 0.5 * pos * size
		handles.append(scaled)
	gizmo.add_handles(handles, get_material("handles_material", gizmo), [])
	
	# Setting extra tool lines from main script
	var tool_lines: PackedVector3Array = box.gizmo_lines
	if not tool_lines.is_empty():
		gizmo.add_lines(tool_lines, get_material("tool_material", gizmo))
		clear_tool_await(box)


# Wait 3 seconds before clear the main script gizmos. If called twice the timer is reset
func clear_tool_await(box: LightmapProbeGrid):
	if not is_instance_valid(timer):
		timer = Timer.new()
	# Add timer to the scene
	if not is_instance_valid(timer.get_parent()):
		var root_node = EditorInterface.get_edited_scene_root()
		root_node.add_child(timer)
		timer.name = "lightmap_probe_grid_timer"
	
	timer.wait_time = 3.0
	timer.start()
	
	if is_awayting:
		return
	
	is_awayting = true
	await timer.timeout
	is_awayting = false
	
	timer.stop
	box.gizmo_lines.clear()
	box.update_gizmos()


# Based on github.com/godotengine/godot/blob/master/editor/plugins/gizmos/gizmo_3d_helper.cpp
# please, make it available to GDScript plugin developers...
func _set_handle(gizmo: EditorNode3DGizmo, index: int, _sec: bool, camera: Camera3D, point: Vector2) -> void:
	var box: LightmapProbeGrid = gizmo.get_node_3d() as LightmapProbeGrid
	var axis: Vector3 = handles_axis[index]
	var axis_index: int = axis.abs().max_axis_index()
	
	var inverse: Transform3D = box.global_transform.affine_inverse()
	var ray_from: Vector3 = camera.project_ray_origin(point)
	var ray_to: Vector3 = camera.project_ray_normal(point)
	var camera_position: Vector3 = inverse * ray_from 
	var camera_to_mouse: Vector3 = inverse * (ray_from + ray_to * 5000)
	
	var segment1: Vector3 = axis * 5000
	var segment2: Vector3 = axis * -5000
	
	var intersection: PackedVector3Array = Geometry3D.get_closest_points_between_segments(segment2, 
			segment1, camera_position, camera_to_mouse)
	
	# Distance between the center and the handle (without scale)
	var distance: float = intersection[0][axis_index]
	# multiply axis signal to cancel distance signal
	distance *= axis[axis_index]
	
	var old_distance: float = 0.5 * box.size[axis_index]
	
	# Defining new size and positions
	var new_size: float = distance + old_distance
	
	# Translate halfway through the size difference
	var translate: Vector3 = 0.5 * (distance - old_distance) * axis
	
	# Updating size and position
	box.size[axis_index] = new_size
	box.translate(translate)
	
	# Update Gizmo
	box.update_gizmos()


func _get_handle_name(_gizmo: EditorNode3DGizmo, _handle_id: int, _sec: bool) -> String:
	return "Probe Grid Size"


func _get_handle_value(gizmo: EditorNode3DGizmo, _id: int, _sec: bool) -> Vector3:
	var box: LightmapProbeGrid = gizmo.get_node_3d() as LightmapProbeGrid
	return box.size
