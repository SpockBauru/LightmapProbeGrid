@tool
extends Node

@export var probes_x: SpinBox
@export var probes_y: SpinBox
@export var probes_z: SpinBox
@export var planned_probes: RichTextLabel

@export var generate_button: Button

@export var far_distance: SpinBox
@export var object_size: SpinBox

var root_node: Node
var probe_grid: LightmapProbeGrid


func _ready() -> void:
	root_node = EditorInterface.get_edited_scene_root()
	if EditorInterface.get_selection().get_selected_nodes().size() == 1:
		probe_grid = EditorInterface.get_selection().get_selected_nodes()[0] as LightmapProbeGrid
	else:
		return
	
	# connecting signals
	if not probe_grid.probes_changed.is_connected(_get_probes):
		probe_grid.probes_changed.connect(_get_probes)
	if not probe_grid.probes_changed.is_connected(planned_probes_text):
		probe_grid.probes_changed.connect(planned_probes_text)
	
	# initializing values
	far_distance.value = probe_grid.far_distance
	object_size.value = probe_grid.object_size
	_get_probes()
	planned_probes_text()
	planned_probes.tooltip_text = "Maximum is %s" % probe_grid.max_probes


func planned_probes_text() -> void:
	var total: int = probe_grid.planned_probes
	var current: int = probe_grid.current_probes
	var max_probes: int = probe_grid.max_probes
	
	if total <= max_probes:
		planned_probes.text = "Probes Planned/Current: " + str(total) + " / " + str(current)
		generate_button.disabled = false
	else:
		planned_probes.text = "[color=red]Planned Probes: %s [/color] \
			\nWarning: Max number of probes is %s" % [total, max_probes]
		generate_button.disabled = true


func _set_probes_number(_value: float) -> void:
	var number_of_probes: Vector3i = Vector3i.ONE
	number_of_probes.x = int(probes_x.value)
	number_of_probes.y = int(probes_y.value)
	number_of_probes.z = int(probes_z.value)
	probe_grid.probes_number = number_of_probes


func _on_generate_probes_pressed() -> void:
	probe_grid.generate_probes()


func _get_probes() -> void:
	var number: Vector3i = probe_grid.probes_number
	probes_x.value = number.x
	probes_y.value = number.y
	probes_z.value = number.z


func _on_cut_by_mask_pressed() -> void:
	probe_grid.cut_obstructed()


func _cut_far_probes():
	probe_grid.cut_far()


func _set_far_distance(value):
	probe_grid.far_distance = value


func _cut_inside():
	probe_grid.cut_inside()


func _set_object_size(value):
	probe_grid.object_size = value
