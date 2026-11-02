class_name ShowcaseGroundUnit
extends Node3D
## A land unit that sits on the terrain and drives back and forth along its route (one point: stationary). It is
## published on DIS by its DisEntity child (velocity estimated by godot-dis from the movement).

var route := PackedVector3Array()
var speed := 0.0  # m/s
var distance := 0.0  # along the route, metres
var terrain: GeoTerrain
## Simulation speed of the demo (fast-forward); 0 stops the unit.
var time_scale := 1.0
var _length := 0.0
var _direction := 1.0


func _ready() -> void:
	for i in range(1, route.size()):
		_length += route[i - 1].distance_to(route[i])
	_place()


func _physics_process(delta: float) -> void:
	if speed <= 0.0 or _length <= 0.0 or time_scale <= 0.0:
		return
	distance += _direction * speed * delta * time_scale
	if distance >= _length or distance <= 0.0:
		distance = clampf(distance, 0.0, _length)
		_direction = -_direction
	_place()


## Position on the terrain at `distance`, facing along the route.
func _place() -> void:
	var at := route[0]
	var forward := Vector3.FORWARD
	var left := distance
	for i in range(1, route.size()):
		var leg := route[i] - route[i - 1]
		if left <= leg.length() or i == route.size() - 1:
			at = route[i - 1] + leg.normalized() * minf(left, leg.length())
			forward = leg.normalized() * _direction
			break
		left -= leg.length()
	var ground := terrain.height_at(at.x, at.z) if terrain else NAN
	at.y = ground if not is_nan(ground) else 0.0
	position = at
	if route.size() > 1:
		basis = Basis.looking_at(Vector3(forward.x, 0.0, forward.z), Vector3.UP)
