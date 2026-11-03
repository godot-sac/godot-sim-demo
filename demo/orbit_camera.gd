class_name ShowcaseOrbitCamera
extends Camera3D
## Orbits the target node: left drag turns, the wheel zooms. The view follows the target smoothly; snap() jumps.
## Mouse input is ignored over GUI controls (the tactical map has its own panning and zooming).

var target: Node3D
var yaw := 0.6
var pitch := -0.3
var distance := 120.0
var min_distance := 15.0
var max_distance := 30000.0
## The orbit centre follows the target's heading (chase view) when true.
var follow_heading := false
var terrain: GeoTerrain
var _center := Vector3.ZERO
var _dragging := false


func snap() -> void:
	if target:
		_center = target.global_position
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button:
		match button.button_index:
			MOUSE_BUTTON_LEFT:
				_dragging = button.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if button.pressed:
					distance = maxf(distance / 1.15, min_distance)
			MOUSE_BUTTON_WHEEL_DOWN:
				if button.pressed:
					distance = minf(distance * 1.15, max_distance)
	var motion := event as InputEventMouseMotion
	if motion and _dragging:
		yaw -= motion.relative.x * 0.005
		pitch = clampf(pitch - motion.relative.y * 0.005, -1.45, 0.3)


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	_center = _center.lerp(target.global_position, 1.0 - exp(-delta * 8.0))
	if _center.distance_to(target.global_position) > 2000.0:
		_center = target.global_position
	_apply()


func _apply() -> void:
	var heading := 0.0
	if follow_heading and target:
		var f := -target.global_basis.z
		heading = atan2(-f.x, -f.z)
	var dir := Vector3(sin(yaw + heading) * cos(pitch), -sin(pitch), cos(yaw + heading) * cos(pitch))
	var eye := _center + dir * distance
	if terrain:  # stay above the ground, and near it above buildings and trees (the tallest is under 400 m)
		var ground := terrain.height_at(eye.x, eye.z)
		if not is_nan(ground) and eye.y < ground + 400.0:
			var top := ShowcaseScenario.top_at(terrain, eye.x, eye.z)
			if eye.y < top + 5.0:
				eye.y = top + 5.0
	global_position = eye
	if not eye.is_equal_approx(_center):
		look_at(_center, Vector3.UP)
