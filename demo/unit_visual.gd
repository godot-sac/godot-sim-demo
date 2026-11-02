class_name ShowcaseUnitVisual
extends Node3D
## Look of one unit, added as a child of the node that moves it (a ShowcaseGroundUnit, the UAV or a
## DisRemoteEntity): a simple model from primitives that grows with distance so it stays visible, a MIL-STD-2525
## symbol of constant screen size (godot-milsymbol MilSymbolSprite3D), the marking, and for aircraft a line down to
## the ground.

const FORCE_COLORS := {1: Color(0.35, 0.6, 1.0), 2: Color(1.0, 0.35, 0.3), 3: Color(0.4, 0.9, 0.4)}
## Models grow beyond this distance so a 7 m tank is still a few pixels at 10 km.
const TRUE_SIZE_DISTANCE := 300.0
const MAX_SCALE := 25.0

var terrain: GeoTerrain
## Show a model (false for the UAV, which has its own).
var with_model := true
var _model: Node3D
var _stem: MeshInstance3D
var _stem_mesh: ImmediateMesh
var _is_air := false


## entity_type: SISO-REF-010 kind, domain, country, category, ...; ghost: drawn translucent (replay).
func setup(entity_type: PackedInt32Array, force: int, marking: String, sidc: String, ghost := false) -> void:
	var color: Color = FORCE_COLORS.get(force, Color(1, 1, 0.5))
	_is_air = entity_type.size() > 1 and entity_type[1] == 2
	var category := entity_type[3] if entity_type.size() > 3 else 0
	_model = Node3D.new()
	add_child(_model)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color.darkened(0.35)
	mat.roughness = 0.8
	if ghost:
		mat.albedo_color = Color(color.lightened(0.2), 0.55)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if with_model:
		if _is_air:
			_aircraft(mat)
		elif category == 1:
			_tank(mat)
		elif category == 28:
			_air_defence(mat)
		else:
			_box(mat, Vector3(3.0, 2.2, 6.5))

	var label := Label3D.new()
	label.text = marking + (" (replay)" if ghost else "")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.fixed_size = true
	label.pixel_size = 0.0008
	label.no_depth_test = true
	label.modulate = color.lightened(0.3)
	label.outline_size = 8
	label.offset = Vector2(0, -38)
	label.font_size = 28
	label.render_priority = 2
	add_child(label)

	if not sidc.is_empty():
		var sprite := MilSymbolSprite3D.new()
		sprite.sidc = sidc
		sprite.symbol_size = 60.0
		sprite.anchor_at_origin = false
		sprite.fixed_size = true
		sprite.pixel_size = 0.0007
		sprite.no_depth_test = true
		sprite.render_priority = 1
		if ghost:
			sprite.modulate = Color(1, 1, 1, 0.6)
		# Above the unit, not on it (refresh() resets the offset, so set it after every render).
		sprite.symbol_changed.connect(func() -> void:
				sprite.offset = Vector2(0, sprite.texture.get_height() * 0.5 + 45.0))
		add_child(sprite)

	if _is_air:
		_stem_mesh = ImmediateMesh.new()
		_stem = MeshInstance3D.new()
		_stem.mesh = _stem_mesh
		_stem.top_level = true
		_stem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var stem_mat := StandardMaterial3D.new()
		stem_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		stem_mat.albedo_color = Color(color, 0.6)
		stem_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_stem.material_override = stem_mat
		add_child(_stem)


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam and _model:
		var d := cam.global_position.distance_to(global_position)
		_model.scale = Vector3.ONE * clampf(d / TRUE_SIZE_DISTANCE, 1.0, MAX_SCALE)
	if _stem and terrain:
		var p := global_position
		var g := terrain.height_at(p.x, p.z)
		_stem_mesh.clear_surfaces()
		if not is_nan(g):
			_stem_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			_stem_mesh.surface_add_vertex(p)
			_stem_mesh.surface_add_vertex(Vector3(p.x, g, p.z))
			_stem_mesh.surface_end()


func _part(mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	_model.add_child(mi)
	return mi


func _box(mat: Material, size: Vector3) -> void:
	var b := BoxMesh.new()
	b.size = size
	_part(b, mat, Vector3(0, size.y * 0.5, 0))


func _tank(mat: Material) -> void:
	var hull := BoxMesh.new()
	hull.size = Vector3(3.6, 1.3, 7.0)
	_part(hull, mat, Vector3(0, 0.9, 0))
	var turret := BoxMesh.new()
	turret.size = Vector3(2.6, 0.9, 3.2)
	_part(turret, mat, Vector3(0, 2.0, 0.3))
	var gun := CylinderMesh.new()
	gun.top_radius = 0.12
	gun.bottom_radius = 0.12
	gun.height = 5.0
	_part(gun, mat, Vector3(0, 2.1, -3.6), Vector3(PI / 2, 0, 0))


func _air_defence(mat: Material) -> void:
	_box(mat, Vector3(3.2, 1.6, 6.0))
	var mast := CylinderMesh.new()
	mast.top_radius = 0.15
	mast.bottom_radius = 0.2
	mast.height = 4.0
	_part(mast, mat, Vector3(0, 3.6, 1.5))
	var radar := BoxMesh.new()
	radar.size = Vector3(3.0, 1.2, 0.2)
	_part(radar, mat, Vector3(0, 5.6, 1.5))


func _aircraft(mat: Material) -> void:
	var body := CylinderMesh.new()
	body.top_radius = 0.6
	body.bottom_radius = 0.9
	body.height = 16.0
	_part(body, mat, Vector3.ZERO, Vector3(PI / 2, 0, 0))
	var wing := BoxMesh.new()
	wing.size = Vector3(11.0, 0.25, 4.0)
	_part(wing, mat, Vector3(0, 0, 1.0))
	var tail := BoxMesh.new()
	tail.size = Vector3(4.5, 0.2, 2.0)
	_part(tail, mat, Vector3(0, 0, 7.0))
