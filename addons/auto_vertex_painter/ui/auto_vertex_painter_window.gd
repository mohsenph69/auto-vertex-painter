@tool
extends Window


@onready var current_mesh_lable:=$VBoxContainer/HBoxContainer2/current_mesh
@onready var color_a:=$VBoxContainer/HBoxContainer/colorA
@onready var color_b:=$VBoxContainer/HBoxContainer/colorB
@onready var surface_index:=$VBoxContainer/HBoxContainer/SpinBox
@onready var buffer_type:=$VBoxContainer/HBoxContainer3/OptionButton
@onready var end_point:=$VBoxContainer/HBoxContainer5/LineEdit
@onready var intepolation:=$VBoxContainer/HBoxContainer4/interpolation
@onready var from_pos:=$VBoxContainer/HBoxContainer4/from_pos
@onready var _global:=$VBoxContainer/HBoxContainer3/global

@onready var nn_x:=$VBoxContainer/HBoxContainer6/x
@onready var nn_y:=$VBoxContainer/HBoxContainer6/y
@onready var nn_z:=$VBoxContainer/HBoxContainer6/z
@onready var end_angle:=$VBoxContainer/HBoxContainer7/end_angle
@onready var angle_interpolate:=$VBoxContainer/HBoxContainer7/angle_interpolate

var arr_indices ={
	"ARRAY_COLOR":Mesh.ARRAY_COLOR,
	"ARRAY_CUSTOM0":Mesh.ARRAY_CUSTOM0,
	"ARRAY_CUSTOM1":Mesh.ARRAY_CUSTOM1,
	"ARRAY_CUSTOM2":Mesh.ARRAY_CUSTOM2,
	"ARRAY_CUSTOM3":Mesh.ARRAY_CUSTOM3,
}


var filesystem:EditorFileSystem
var current_mesh:MeshInstance3D = null

func _ready():
	visible = false
	buffer_type.clear()
	var keys = arr_indices.keys()
	for k in keys:
		buffer_type.add_item(k)

func _on_close_requested():
	visible = false


func set_current_mesh(input:MeshInstance3D)->void:
	current_mesh = input
	if current_mesh:
		current_mesh_lable.text = "Current Mesh: " + current_mesh.name
	else:
		current_mesh_lable.text = "Current Mesh: NULL"

func _on_fill_color_btn_pressed():
	if not current_mesh:
		printerr("No Valid data for this Surface")
		return
	var data = current_mesh.mesh.surface_get_arrays(surface_index.value)
	if data.size() == 0:
		printerr("No Valid data for this Surface")
		return
	var verts_size:int = data[Mesh.ARRAY_VERTEX].size()
	var colors:PackedColorArray
	var col:Color = color_a.color
	for i in range(0,verts_size):
		colors.push_back(col)
	make_mesh(data,colors)



func _on_interpolate_btn_pressed():
	if not current_mesh:
		printerr("Current Mesh is NULL")
		return
	var data = current_mesh.mesh.surface_get_arrays(surface_index.value)
	if data.size() == 0:
		printerr("No Valid data for this Surface")
		return
	var aabb = current_mesh.mesh.get_aabb()
	if _global.button_pressed:
		aabb = current_mesh.global_transform * aabb
	var point_a:float
	var from_str:String = from_pos.get_item_text(from_pos.selected)
	var s:float
	
	if from_str == "bottom2top":
		point_a = aabb.position.y
		s = aabb.size.y
	elif from_str == "top2bottom":
		point_a = aabb.end.y
		s = aabb.size.y
	elif from_str == "left2right":
		point_a = aabb.position.x
		s = aabb.size.x
	elif from_str == "right2left":
		point_a = aabb.end.x
		s = aabb.size.x
	elif from_str == "front2back":
		point_a = aabb.end.z
		s = aabb.size.z
	elif from_str == "back2front":
		point_a = aabb.position.z
		s = aabb.size.z
	else:
		printerr("Not find start point")
	var total:float
	var e = end_point.text.to_float()
	total = e*s
	
	var verts:PackedVector3Array = data[Mesh.ARRAY_VERTEX]
	if _global.button_pressed:
		verts = verts.duplicate()
		for i in range(0,verts.size()):
			verts[i] = current_mesh.global_transform * verts[i]
	var colors:PackedColorArray
	var interpolation_type:String = intepolation.get_item_text(intepolation.get_selected_id())
	## Making colors
	for vert in verts:
		var point_b:float
		if from_str=="bottom2top" or from_str=="top2bottom":
			point_b = vert.y
		if from_str=="left2right" or from_str=="right2left":
			point_b = vert.x
		if from_str=="front2back" or from_str=="back2front":
			point_b = vert.z
		var ratio:float = abs(point_b - point_a)/total
		var col:Color
		if interpolation_type == "smoothstep":
			col.r = smoothstep(color_a.color.r,color_b.color.r,ratio)
			col.g = smoothstep(color_a.color.g,color_b.color.g,ratio)
			col.b = smoothstep(color_a.color.b,color_b.color.b,ratio)
			col.a = smoothstep(color_a.color.a,color_b.color.a,ratio)
		elif interpolation_type == "linear":
			col = lerp(color_a.color,color_b.color,ratio)
		elif interpolation_type == "step":
			if ratio < total:
				col = color_a.color
			else:
				col = color_b.color
		colors.push_back(col)
	make_mesh(data,colors)


func _on_normal_btn_pressed():
	if not current_mesh:
		printerr("Current Mesh is NULL")
		return
	var data = current_mesh.mesh.surface_get_arrays(surface_index.value)
	if data.size() == 0:
		printerr("No Valid data for this Surface")
		return
	var normals:PackedVector3Array = data[Mesh.ARRAY_NORMAL]
	if _global.button_pressed:
		normals = normals.duplicate()
		var t:Transform3D = Transform3D(current_mesh.global_transform.basis,Vector3.ZERO)
		for i in range(0,normals.size()):
			normals[i] = t * normals[i]
	var nn:Vector3=Vector3(nn_x.text.to_float(),nn_y.text.to_float(),nn_z.text.to_float())
	nn = nn.normalized()
	var interpolation:String=angle_interpolate.get_item_text(angle_interpolate.selected)
	var colors:PackedColorArray
	var total:float=end_angle.text.to_float()
	for normal in normals:
		var angle:float = abs(rad_to_deg(nn.angle_to(normal)))
		var ratio:float=angle/total
		var col:Color
		if interpolation == "smoothstep":
			col.r = smoothstep(color_a.color.r,color_b.color.r,ratio)
			col.g = smoothstep(color_a.color.g,color_b.color.g,ratio)
			col.b = smoothstep(color_a.color.b,color_b.color.b,ratio)
			col.a = smoothstep(color_a.color.a,color_b.color.a,ratio)
		elif interpolation == "linear":
			col = lerp(color_a.color,color_b.color,ratio)
		elif interpolation == "step":
			if angle < total:
				col = color_a.color
			else:
				col = color_b.color
		colors.push_back(col)
	make_mesh(data,colors)


func make_mesh(data:Array,colors:PackedColorArray):
	var type = arr_indices[buffer_type.get_item_text(buffer_type.selected)]
	if type == Mesh.ARRAY_COLOR:
		data[Mesh.ARRAY_COLOR] = colors
	else:
		var bytes:PackedByteArray
		for c in colors:
			bytes.push_back(c.r*255)
			bytes.push_back(c.g*255)
			bytes.push_back(c.b*255)
			bytes.push_back(c.a*255)
		data[type] = bytes
	var new:=ArrayMesh.new()
	for i in range(0,current_mesh.mesh.get_surface_count()):
		if i == surface_index.value:
			new.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,data)
		else:
			var _d = current_mesh.mesh.surface_get_arrays(i)
			new.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,_d)
	current_mesh.mesh = new












