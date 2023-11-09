@tool
extends EditorPlugin

var dock_res := preload("res://addons/auto_vertex_painter/ui/auto_vertex_painter_dock.tscn")
var window_res:=preload("res://addons/auto_vertex_painter/ui/auto_vertex_painter_window.tscn")
var dock
var window

func _enter_tree():
	dock = dock_res.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,dock)
	get_editor_interface().get_selection().connect("selection_changed",Callable(self,"selection_changed"))
	dock.v_paint_button.connect("pressed",Callable(self,"v_paint_pressed"))
	window = window_res.instantiate()
	add_child(window)

func _exit_tree():
	remove_control_from_docks(dock)
	dock.queue_free()
	window.queue_free()
	
	
func v_paint_pressed():
	window.visible = false
	window.visible = true
	
	
func selection_changed():
	var s = get_editor_interface().get_selection().get_selected_nodes()
	if s.size() == 1:
		if s[0] is MeshInstance3D:
			if s[0].mesh:
				dock.visible = true
				window.filesystem = get_editor_interface().get_resource_filesystem()
				window.set_current_mesh(s[0])
				return
	window.set_current_mesh(null)
	dock.visible = false

