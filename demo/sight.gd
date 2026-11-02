class_name ShowcaseSight
extends Node3D
## Line of sight from the opposing air defence post to the UAV (godot-geo GeoVisibility.line_of_sight; terrain,
## buildings and tree crowns block), drawn in 3D: red while the UAV is in view, yellow up to what hides it. The
## queries run on worker threads (a few kilometres through the city cost up to ~15 ms). The viewshed (toggle())
## shows where the UAV, at its present height above the ground, would be in view of the post; it is computed on a
## worker thread with GeoVisibility and drawn over the terrain (GeoTerrain.set_overlay).

signal viewshed_ready(image: Image, rect: Rect2)

const INTERVAL := 0.2  # wall-clock seconds between line of sight queries
const VIEWSHED_RADIUS := 9000.0
const VIEWSHED_RESOLUTION := 256

var terrain: GeoTerrain
var eye := Vector3.ZERO  # global eye position of the post
var target: Node3D
var time_scale := 1.0
## Last result of GeoTerrain.line_of_sight (global positions), plus "from" and "to".
var result := {}
var queries := 0
var visible_queries := 0
## Game seconds with the UAV in view / covered by queries (each query stands for the time since the previous one).
var visible_time := 0.0
var covered_time := 0.0
var viewshed_on := false
var viewshed_busy := false
var last_viewshed: Image
var last_viewshed_rect := Rect2()
var last_viewshed_ms := 0.0
var _clock := 0.0
var _game_time := 0.0  # since the last query
var _task := -1
var _mesh := ImmediateMesh.new()
var _thread: Thread


func _ready() -> void:
	var line := MeshInstance3D.new()
	line.mesh = _mesh
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	mat.render_priority = 3
	line.material_override = mat
	add_child(line)
	top_level = true


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		result = {}
		_game_time = 0.0
		return
	_game_time += delta * time_scale
	_clock -= delta
	if _clock > 0.0 or _task >= 0:
		return
	_clock = INTERVAL
	query()


## Starts a line of sight query to the target's present position; `result` is updated when it is done.
func query() -> void:
	var to := target.global_position
	_task = WorkerThreadPool.add_task(_trace.bind(terrain.package, terrain.to_package_local(eye),
			terrain.to_package_local(to), _query_done.bind(eye, to, _game_time)))
	_game_time = 0.0


static func _trace(package: GeoTerrainPackage, a: Vector3, b: Vector3, done: Callable) -> void:
	done.call_deferred(GeoVisibility.line_of_sight(package, a, b))


func _query_done(r: Dictionary, from: Vector3, to: Vector3, game_seconds: float) -> void:
	WorkerThreadPool.wait_for_task_completion(_task)
	_task = -1
	r.point = terrain.from_package_local(r.point)
	r.clearance_point = terrain.from_package_local(r.clearance_point)
	r["from"] = from
	r["to"] = to
	result = r
	queries += 1
	covered_time += game_seconds
	if r.visible:
		visible_queries += 1
		visible_time += game_seconds


## Share of the game time the UAV was in view, 0..1.
func exposure() -> float:
	return visible_time / covered_time if covered_time > 0.0 else 0.0


## The line as camera-facing ribbons a few pixels wide (plain lines are one pixel and vanish over the terrain).
func _process(_delta: float) -> void:
	_mesh.clear_surfaces()
	var cam := get_viewport().get_camera_3d()
	if cam == null or not result.has("from") or target == null:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	if result.visible:
		_ribbon(cam, eye, result.to, Color(1.0, 0.25, 0.2))
	else:
		_ribbon(cam, eye, result.point, Color(1.0, 0.85, 0.25))
		_ribbon(cam, result.point, result.to, Color(0.8, 0.8, 0.8, 0.35))
	_mesh.surface_end()


func _ribbon(cam: Camera3D, a: Vector3, b: Vector3, color: Color) -> void:
	var c := cam.global_position
	var pixel := 2.0 * tan(deg_to_rad(cam.fov) * 0.5) / get_viewport().get_visible_rect().size.y
	var side := (b - a).cross(c - (a + b) * 0.5).normalized()
	var wa := side * a.distance_to(c) * pixel * 1.5
	var wb := side * b.distance_to(c) * pixel * 1.5
	_mesh.surface_set_color(color)
	for v: Vector3 in [a - wa, a + wa, b + wb, a - wa, b + wb, b - wb]:
		_mesh.surface_add_vertex(v)


## Viewshed on / off. On: computed for the UAV's present height above the ground.
func toggle() -> void:
	viewshed_on = not viewshed_on
	if viewshed_on:
		compute_viewshed()
	else:
		terrain.clear_overlay()


func compute_viewshed() -> void:
	if viewshed_busy:
		return
	var height := 2.0
	if target:
		var g := terrain.height_at(target.global_position.x, target.global_position.z)
		if not is_nan(g):
			height = maxf(target.global_position.y - g, 2.0)
	viewshed_busy = true
	_thread = Thread.new()
	_thread.start(_viewshed_job.bind(terrain.package, terrain.to_package_local(eye), height, Time.get_ticks_usec()))


func _viewshed_job(package: GeoTerrainPackage, local_eye: Vector3, height: float, started: int) -> void:
	var image := GeoVisibility.viewshed(package, local_eye, VIEWSHED_RADIUS, height, VIEWSHED_RESOLUTION)
	_viewshed_done.call_deferred(image, (Time.get_ticks_usec() - started) / 1000.0)


func _viewshed_done(image: Image, ms: float) -> void:
	_thread.wait_to_finish()
	_thread = null
	viewshed_busy = false
	last_viewshed = image
	last_viewshed_rect = terrain.viewshed_rect(eye, VIEWSHED_RADIUS)
	last_viewshed_ms = ms
	var colors := GeoVisibility.viewshed_colors(image)
	if viewshed_on:
		terrain.set_overlay(colors, last_viewshed_rect)
	viewshed_ready.emit(colors, last_viewshed_rect)


## Share of the viewshed's ground (inside the radius) that is visible, 0..1.
static func visible_share(image: Image) -> float:
	var seen := 0
	var total := 0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a > 0.5:
				total += 1
				if c.r > 0.5:
					seen += 1
	return float(seen) / total if total > 0 else 0.0


func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
	if _thread:
		_thread.wait_to_finish()
