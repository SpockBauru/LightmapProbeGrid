@tool
extends EditorPlugin

var custom_node: Script = preload("lightmap_probe_grid.gd")
var icon: Texture2D = preload("lightmap_probe_grid_icon.svg")

var inspector_script: Script = preload("editor_inspector_plugin.gd")
var inspector_plugin: EditorInspectorPlugin = inspector_script.new()

var gizmo_script: Script = preload("gizmo.gd")
var gizmo_plugin: EditorNode3DGizmoPlugin = gizmo_script.new()

func _get_plugin_name() -> String:
	return "LightmapProbeGrid"

func _enter_tree() -> void:
	add_custom_type("LightmapProbeGrid", "Node3D", custom_node, icon)
	add_inspector_plugin(inspector_plugin)
	add_node_3d_gizmo_plugin(gizmo_plugin)


func _exit_tree() -> void:
	remove_custom_type("LightmapProbeGrid")
	remove_inspector_plugin(inspector_plugin)
	remove_node_3d_gizmo_plugin(gizmo_plugin)
