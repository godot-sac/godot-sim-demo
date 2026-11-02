class_name ShowcaseCheck
extends RefCounted
## `--check N`: runs the showcase for N game seconds while recording the DIS traffic, plays the recording back at
## 16× and checks that every add-on did its part. Prints a SHOWCASE_CHECK line, writes a JSON report (--report) and
## quits with exit code 0 (all checks passed) or 1.
##
## Checks: the flight model runs without crash or failure; the autopilot reaches waypoints and keeps clear of the
## terrain, buildings and trees; every own entity is published on DIS; the land units' and the boat's DIS positions
## lie on the terrain or the water (godot-dis ECEF converted back with godot-geo GeoMath); lines of sight and the
## viewshed give plausible answers; the map shows all units and control measures; the recording plays back with
## every entity, near its live position.

const MIN_AGL := 100.0
const MIN_CLEARANCE := 60.0  # above the highest building or tree under the UAV
const GROUND_TOLERANCE := 0.5  # m between a land unit's DIS height and the terrain
const REPLAY_TOLERANCE_AIR := 300.0
const REPLAY_TOLERANCE_LAND := 60.0
const REPLAY_SPEED := 16.0

var showcase: Node
var seconds := 60.0
var checks := {}  # name -> {ok, value}
var _sample_clock := 0.0
var _ground_error := 0.0
var _ground_samples := 0
var _frame_ms := PackedFloat32Array()
var _last_frame := 0
var _phase := "live"
var _live_positions := {}  # marking -> global position when the recording stopped
var _viewshed_share := -1.0
var _started := 0


func _init(p_showcase: Node, p_seconds: float) -> void:
	showcase = p_showcase
	seconds = p_seconds


func start() -> void:
	_started = Time.get_ticks_msec()
	_last_frame = Time.get_ticks_usec()
	print("checking for %.0f game seconds at ×%s" % [seconds, showcase.time_scale])
	showcase.sight.viewshed_ready.connect(func(_image: Image, _rect: Rect2) -> void:
			_viewshed_share = ShowcaseSight.visible_share(showcase.sight.last_viewshed))
	showcase.sight.compute_viewshed()
	# Safety net: a stuck run still reports (wall clock).
	showcase.get_tree().create_timer(seconds / showcase.time_scale + 120.0, true, false, true).timeout.connect(
			func() -> void:
				if _phase != "done":
					_add("finished in time", false, _phase)
					_report())


## Called every physics frame while live.
func step(delta: float) -> void:
	var now := Time.get_ticks_usec()
	_frame_ms.append((now - _last_frame) / 1000.0)
	_last_frame = now
	if _phase != "live":
		return
	_sample_clock -= delta * showcase.time_scale
	if _sample_clock <= 0.0:
		_sample_clock = 1.0
		_sample_ground()
	if showcase.game_time >= seconds:
		_end_live()


## Height of each land unit's and the boat's last DIS position above the terrain (or water surface) under it.
func _sample_ground() -> void:
	var terrain: GeoTerrain = showcase.terrain
	for u: ShowcaseGroundUnit in showcase.own_forces.get_children():
		var pdu: DisEntityStatePdu = (u.get_node("DisEntity") as DisEntity).create_pdu()
		var g := GeoMath.ecef_to_geodetic(pdu.location_ecef)
		var h := terrain.geodetic_height(g[0], g[1])
		_ground_error = maxf(_ground_error, absf(g[2] - h))
		_ground_samples += 1


func _end_live() -> void:
	_phase = "replay"
	var aircraft: JSBSimAircraft = showcase.aircraft
	_add("flight model running", aircraft.is_started() and not aircraft.is_failed() and not aircraft.is_crashed(),
			"crashed" if aircraft.is_crashed() else ("failed" if aircraft.is_failed() else "ok"))
	_add("autopilot reached waypoints", showcase.waypoints_reached >= 2, showcase.waypoints_reached)
	_add("UAV clear of the terrain", showcase.min_agl >= MIN_AGL, snappedf(showcase.min_agl, 0.1))
	_add("UAV clear of buildings and trees", showcase.min_clearance >= MIN_CLEARANCE,
			snappedf(showcase.min_clearance, 0.1))
	var unpublished := []
	for e: DisEntity in showcase.own_entities():
		if e.get_published_count() == 0:
			unpublished.append(e.marking)
		_live_positions[e.marking] = (e.get_parent() as Node3D).global_position
	_add("all entities published on DIS", unpublished.is_empty(), unpublished if unpublished else
			showcase.own_entities().size())
	_add("units on the ground or water (DIS height)", _ground_samples > 0 and _ground_error <= GROUND_TOLERANCE,
			"%.3f m max over %d samples" % [_ground_error, _ground_samples])
	_check_sight()
	var map: ShowcaseMap = showcase.map
	_add("map units", map.map.get_unit_count() == showcase.own_entities().size() + showcase.manager.get_entity_count(),
			map.map.get_unit_count())
	var graphics := 0
	for g: Dictionary in ShowcaseScenario.GRAPHICS:
		if map.map.has_graphic(g.id) and map.map.get_graphic_shape(g.id) != null:
			graphics += 1
	_add("map control measures", graphics == ShowcaseScenario.GRAPHICS.size(), graphics)
	var recorder: DisRecorder = showcase.recorder
	var packets := recorder.get_packet_count()
	recorder.stop()
	_add("recording has packets", packets > 0, packets)
	var player: DisPlayer = showcase.player
	player.finished.connect(_end_replay, CONNECT_ONE_SHOT)
	if not showcase._enter_replay():
		_add("recording plays back", false, "cannot open " + showcase.recording_path)
		_report()
		return
	player.speed = REPLAY_SPEED


func _check_sight() -> void:
	var sight: ShowcaseSight = showcase.sight
	var terrain: GeoTerrain = showcase.terrain
	_add("line of sight queries", sight.queries > 0, "%d, UAV in view %.0f %%" % [sight.queries,
			100.0 * sight.exposure()])
	var up: Dictionary = terrain.line_of_sight(sight.eye, sight.eye + Vector3(0, 500, 0))
	# A point 5 m under the ground 3 km away (towards the package centre, so it is inside) can not be seen.
	var toward := Vector3(-sight.eye.x, 0, -sight.eye.z).normalized()
	var far := sight.eye + (toward if toward != Vector3.ZERO else Vector3.RIGHT) * 3000.0
	far.y = terrain.height_at(far.x, far.z) - 5.0
	var under: Dictionary = terrain.line_of_sight(sight.eye, far)
	_add("line of sight sanity (sky visible, underground hidden)", up.visible and not under.visible,
			"%s / %s" % [up.visible, under.visible])
	_add("viewshed plausible", _viewshed_share > 0.0 and _viewshed_share < 1.0,
			"%.1f %% visible, %.0f ms" % [100.0 * _viewshed_share, sight.last_viewshed_ms])


func _end_replay() -> void:
	var manager: DisEntityManager = showcase.replay_manager
	var worst_air := 0.0
	var worst_land := 0.0
	var missing := _live_positions.keys()
	for entity: DisRemoteEntity in manager.get_entities():
		var marking := entity.get_marking()
		if not _live_positions.has(marking):
			continue
		missing.erase(marking)
		var d: float = entity.global_position.distance_to(_live_positions[marking])
		if marking == ShowcaseScenario.UAV.marking:
			worst_air = maxf(worst_air, d)
		else:
			worst_land = maxf(worst_land, d)
	_add("recording plays back every entity", missing.is_empty(), missing if missing else manager.get_entity_count())
	_add("replayed positions match live", worst_air <= REPLAY_TOLERANCE_AIR and worst_land <= REPLAY_TOLERANCE_LAND,
			"UAV %.0f m, land %.1f m" % [worst_air, worst_land])
	_report()


func _add(name: String, ok: bool, value: Variant) -> void:
	checks[name] = {"ok": ok, "value": value}
	print("  %s %s: %s" % ["ok  " if ok else "FAIL", name, value])


func _report() -> void:
	_phase = "done"
	var failed := checks.values().filter(func(c: Dictionary) -> bool: return not c.ok).size()
	var frames := Array(_frame_ms)
	frames.sort()
	var report := {
		"ok": failed == 0,
		"failed": failed,
		"game_seconds": snappedf(showcase.game_time, 0.01),
		"wall_seconds": (Time.get_ticks_msec() - _started) / 1000.0,
		"time_scale": showcase.time_scale,
		"terrain": showcase.terrain.package_path,
		"route_height": snappedf(showcase.route_height, 0.1),
		"frame_ms": {"mean": _mean(frames), "p99": frames[int(frames.size() * 0.99)] if frames else 0.0},
		"render_frames": showcase.frame_stats(),
		"layers": not showcase._options.has("no-layers"),
		"checks": checks,
	}
	var path := str(showcase._options.get("report", "user://showcase_check.json"))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "  "))
	print("SHOWCASE_CHECK %s failed=%d checks=%d game=%.0f s report=%s" % ["ok" if failed == 0 else "FAILED",
			failed, checks.size(), showcase.game_time, ProjectSettings.globalize_path(path)])
	showcase.get_tree().quit(0 if failed == 0 else 1)


static func _mean(values: Array) -> float:
	var total := 0.0
	for v: float in values:
		total += v
	return total / values.size() if values else 0.0
