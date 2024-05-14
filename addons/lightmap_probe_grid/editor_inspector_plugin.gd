extends EditorInspectorPlugin

var ui_control: PackedScene = preload("controls_scene.tscn")
var ui: Control = null

func _can_handle(object: Object) -> bool:
	if object is LightmapProbeGrid:
		return true
	else:
		return false

func _parse_category(_object: Object, category: String) -> void:
	if category.begins_with("lightmap_probe_grid"):
		if not is_instance_valid(ui):
			ui = ui_control.instantiate()
			add_property_editor("LighmapProbeGrid", ui)
