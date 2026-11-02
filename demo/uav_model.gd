extends Node3D
## Simple medium-altitude UAV look built from primitives (long straight wing, slim fuselage, V tail, pusher
## propeller), looking along −Z. The flight model under it is the J3Cub bundled with godot-jsbsim; see README.

const BODY := Color(0.78, 0.8, 0.82)
const DARK := Color(0.15, 0.15, 0.16)

@export var aircraft: JSBSimAircraft

var _propeller: Node3D


func _ready() -> void:
	if aircraft == null:
		aircraft = get_parent() as JSBSimAircraft
	var mat := _material(BODY)
	var body := CapsuleMesh.new()
	body.radius = 0.45
	body.height = 6.5
	_part(body, mat, Vector3(0, 0, 0.3), Vector3(PI / 2, 0, 0))
	var dome := SphereMesh.new()
	dome.radius = 0.5
	dome.height = 0.8
	_part(dome, mat, Vector3(0, 0.25, -2.2))
	var wing := BoxMesh.new()
	wing.size = Vector3(14.0, 0.12, 0.9)
	_part(wing, mat, Vector3(0, 0.15, -0.2))
	var boom := CylinderMesh.new()
	boom.top_radius = 0.08
	boom.bottom_radius = 0.08
	boom.height = 3.0
	_part(boom, mat, Vector3(0, 0.1, 4.6), Vector3(PI / 2, 0, 0))
	var tail := BoxMesh.new()
	tail.size = Vector3(1.8, 0.08, 0.7)
	for side in [-1.0, 1.0]:  # V tail
		_part(tail, mat, Vector3(side * 0.75, 0.55, 5.8), Vector3(0, 0, side * deg_to_rad(35.0)))
	_propeller = Node3D.new()
	_propeller.position = Vector3(0, 0, 3.6)
	add_child(_propeller)
	var blade := BoxMesh.new()
	blade.size = Vector3(1.6, 0.12, 0.04)
	var prop := MeshInstance3D.new()
	prop.mesh = blade
	prop.material_override = _material(DARK)
	_propeller.add_child(prop)


func _process(delta: float) -> void:
	if aircraft == null or not aircraft.is_started() or aircraft.paused:
		return
	_propeller.rotate_z(40.0 * delta * aircraft.time_scale)


func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.6
	return m


func _part(mesh: Mesh, mat: Material, at: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	mi.rotation = rot
	add_child(mi)
	return mi
