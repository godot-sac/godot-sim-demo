extends Node3D
## Unified showcase: a UAV-like aircraft (godot-jsbsim JSBSimAircraft + JSBSimAutopilot) flies a waypoint loop over
## Üsküdar and the Bosphorus in Istanbul (godot-geo GeoTerrain with buildings, trees, roads and water from open
## data), land units drive on the streets and a boat on the water, everything is published on DIS
## (godot-dis), a 2D tactical map shows symbols and control measures (godot-milsymbol TacticalMap2D), an opposing
## air defence post keeps a line of sight on the UAV and can show its viewshed (godot-geo), and the DIS traffic can
## be recorded and played back (godot-dis DisRecorder / DisPlayer).
##
##   <godot> --path .                          (demo/main.tscn checks the add-ons, then opens this scene)
##
## Options after `--`:
##   --port N            DIS port (default 3000; --check uses 3290 unless given). Multicast 239.1.2.3, exercise 1.
##   --terrain PACKAGE   terrain package: 10km (default, res://terrain/uskudar_10km), 60km (res://terrain/uskudar)
##                       or a package directory
##   --no-layers         terrain without buildings, trees and roads (slower computers)
##   --no-vsync          draw as fast as possible (frame time measurements)
##   --time-scale X      simulation speed (1 to 16)
##   --record FILE       record from the start (default file for R: user://showcase.pcapng)
##   --replay FILE       open a recording in playback mode
##   --viewshed          start with the viewshed overlay on
##   --seconds N         quit after N game seconds
##   --screenshot FILE   save a PNG before quitting (needs a window)
##   --tour              press the keys of a short tour by itself (viewshed, map, units, recording, playback) and
##                       turn the camera slowly; for unattended screens and for recording the README animation
##   --capture DIR       with --tour: save the screen as PNG frames (DIR/f00000000.png ...) at 15 per second of
##                       wall-clock time and quit at the end of the tour (input of tools/make_media.py)
##   --check N           self-test: run N game seconds, record, play the recording back, check, report, exit code
##   --report FILE       JSON report of --check (default user://showcase_check.json)
## At the end of a run the console gets the frame times (median, 95th and 99th percentile).

const PACKAGES := {"10km": "res://terrain/uskudar_10km", "60km": "res://terrain/uskudar"}
const OPTIONS := ["port", "terrain", "no-layers", "no-vsync", "time-scale", "record", "replay", "viewshed", "seconds",
		"screenshot", "tour", "capture", "check", "report"]
const DEFAULT_RECORDING := "user://showcase.pcapng"
const SUN_ELEVATION := 28.0
const SUN_AZIMUTH := 220.0
const TRAIL_INTERVAL := 2.0
const REPLAY_SPEEDS := [0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0, 32.0]
## --tour: [seconds after the start (wall clock), key, shift]. Fast-forwards the first three minutes of the route at
## 16×, then runs at 4×: from 15.5 s on (about 28 s, recorded) the UAV comes out from behind the trees into the air
## defence post's view, the large map, the view of the post, the recording played back.
const TOUR := [[0.2, KEY_V], [0.4, KEY_BRACKETRIGHT], [0.5, KEY_BRACKETRIGHT], [0.6, KEY_BRACKETRIGHT],
		[0.7, KEY_BRACKETRIGHT], [10.9, KEY_BRACKETLEFT], [11.0, KEY_BRACKETLEFT], [15.5, KEY_R], [27.5, KEY_M],
		[33.5, KEY_M], [33.6, KEY_TAB, true], [38.5, KEY_P], [38.7, KEY_UP], [38.8, KEY_UP]]
const TOUR_TURN := 0.06  # rad/s of camera orbit during the tour
const TOUR_END := 44.0
## Frames per second of --capture. Real time, not Godot's Movie Maker mode: Movie Maker slows the game down against
## the wall clock that DIS timestamps, dead reckoning and the recorder use, so playback would look wrong.
const CAPTURE_FPS := 15.0
## Frame times kept for the statistics printed at the end (the latest ones; about 10 minutes at 300 fps).
const FRAME_HISTORY := 200000
const HELP := """Tab / Shift+Tab   camera on next / previous unit (UAV first)
Left drag         orbit                      Wheel   zoom
[  ]              simulation slower / faster
V                 viewshed of the air defence post for the UAV's height
M                 large / small map          (map: drag pans, wheel zooms)
R                 start / stop recording DIS traffic (%s)
P                 playback of the last recording / back to live
  in playback:    Space play / pause, Left / Right 10 s, Up / Down speed, Home start
F12               screenshot                 F1      this help        Esc   quit
user:// is Godot's user data folder of this project; the console prints the full paths."""

@onready var origin: DisGeoOrigin = $DisGeoOrigin
@onready var terrain: GeoTerrain = $GeoTerrain
@onready var network: DisNetwork = $DisNetwork
@onready var manager: DisEntityManager = $DisEntityManager
@onready var recorder: DisRecorder = $DisRecorder
@onready var own_forces: Node3D = $OwnForces
@onready var replay_manager: DisEntityManager = $Replay/ReplayManager
@onready var player: DisPlayer = $Replay/DisPlayer
@onready var camera: ShowcaseOrbitCamera = $Camera
@onready var info: Label = $HUD/Info
@onready var banner: Label = $HUD/Banner

var aircraft: JSBSimAircraft
var autopilot: JSBSimAutopilot
var uav_entity: DisEntity
var units: Array[ShowcaseGroundUnit] = []
var ad_post: ShowcaseGroundUnit
var map: ShowcaseMap
var sight: ShowcaseSight
var route := PackedVector3Array()
var route_height := 0.0
var game_time := 0.0
var time_scale := 1.0
var waypoints_reached := 0
var min_agl := INF
var min_clearance := INF  # above buildings, trees and ground
var replaying := false
var recording_path := DEFAULT_RECORDING
var _options := {}
var _targets: Array[Node3D] = []
var _target_index := 0
var _trail_clock := 0.0
var _message := ""
var _message_until := 0.0
var _quit_at := -1.0
var _type_cache := {}
var _replay_ids := {}  # entity id -> map id of replayed entities
var _check: ShowcaseCheck
var _tour_clock := -1.0  # seconds since the start of --tour; -1 without it
var _tour_step := 0
var _capture_dir := ""
var _capture_frame := 0
var _capture_tasks := PackedInt64Array()
var _frame_ms := PackedFloat32Array()
var _clearance_clock := 0.0


func _ready() -> void:
	_options = _parse_args(OS.get_cmdline_user_args())
	for name: String in _options:
		if name not in OPTIONS:
			push_warning("showcase: unknown option --%s (options: --%s)" % [name, ", --".join(OPTIONS)])
	if _options.has("check"):
		_check = ShowcaseCheck.new(self, float(_options.check))
	var port := int(_options.get("port", 3290 if _check else 3000))
	if _options.has("no-vsync"):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if not _load_terrain():
		return
	_place_sun()
	network.port = port
	network.share_port = true  # next to the other demos on this computer
	$Replay/ReplayNetwork.port = port
	network.start()
	manager.ground_path = manager.get_path_to(terrain)
	replay_manager.ground_path = replay_manager.get_path_to(terrain)
	manager.entity_appeared.connect(_on_remote_appeared)
	manager.entity_removed.connect(func(entity: Node, _reason: String) -> void:
			map.remove_unit(_remote_id(entity)))
	replay_manager.entity_appeared.connect(_on_replay_appeared)
	replay_manager.entity_removed.connect(_on_replay_removed)
	player.finished.connect(func() -> void: _say("End of recording"))
	recorder.stopped.connect(func(path: String, count: int) -> void:
			_say("Recorded %d packets to %s" % [count, path], path))

	map = ShowcaseMap.new()
	$HUD.add_child(map)
	map.setup(terrain)
	for g: Dictionary in ShowcaseScenario.GRAPHICS:
		map.add_graphic(g.id, g.sidc, g.points, g.amplifiers)
	_spawn_units()
	_spawn_uav()
	_setup_sight()
	map.route = route
	_update_map()
	map.map.zoom_to_content.call_deferred(20.0)  # once the panel has its size

	$HUD/Help.text = HELP % DEFAULT_RECORDING
	$HUD/Attribution.text = "\n".join(terrain.attribution()) + "\nDIS enumerations: SISO-REF-010, reprinted with " \
			+ "permission from SISO Inc.  Symbols: MIL-STD-2525D (godot-milsymbol, after milsymbol).  Flight model: " \
			+ "JSBSim J3Cub (LGPL-2.1) standing in for a UAV."
	_targets = [aircraft as Node3D]
	for u in units:
		_targets.append(u)
	_targets.append(ad_post)
	camera.target = aircraft
	camera.distance = 90.0
	camera.snap()

	set_time_scale(float(_options.get("time-scale", 8.0 if _check else 1.0)))
	if _options.has("record") or _check:
		# Per port: copies of this project share user://, and parallel checks use different ports.
		recording_path = str(_options.get("record", "user://showcase_check_%d.pcapng" % port))
		_start_recording()
	if _options.has("replay"):
		recording_path = str(_options.replay)
		_enter_replay.call_deferred()
	if _options.has("viewshed"):
		_toggle_viewshed.call_deferred()
	if _options.has("seconds"):
		_quit_at = float(_options.seconds)
	if _check:
		_check.start()
	if _options.has("tour"):
		_tour_clock = 0.0
		if _options.has("capture"):
			_capture_dir = str(_options.capture)
			DirAccess.make_dir_recursive_absolute(_capture_dir)
	get_window().title = "godot-sim-demo — UAV, DIS, terrain, tactical map"
	print("showcase: terrain %s, DIS 239.1.2.3:%d exercise 1 site %d, route %d waypoints, highest %.0f m (ellipsoid)" % [
			terrain.package_path, port, network.site_id, route.size(), route_height])


func _load_terrain() -> bool:
	var wanted := str(_options.get("terrain", ""))
	if _options.get("terrain") is bool:
		_fail("--terrain needs a value: 10km, 60km or a package folder")
		return false
	var candidates: Array = [PACKAGES.get(wanted, wanted)] if wanted != "" else PACKAGES.values()
	terrain.auto_layers = not _options.has("no-layers")
	for p: String in candidates:
		if p != "" and FileAccess.file_exists(p.path_join("terrain.json")):
			# The DIS origin is the package origin, so the terrain, JSBSim and DIS share one frame.
			var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(p.path_join("terrain.json")))
			origin.latitude = json.origin.latitude
			origin.longitude = json.origin.longitude
			origin.height = json.origin.height
			terrain.package_path = p
			break
	if not terrain.is_loaded():
		_fail("no terrain package %s; see README (Installation)" % (wanted if wanted != "" else "in res://terrain/"))
		return false
	if not terrain.origin_warning.is_empty():
		push_warning(terrain.origin_warning)
	camera.terrain = terrain
	camera.far = terrain.package.size_m * 3.0
	return true


func _place_sun() -> void:
	var el := deg_to_rad(SUN_ELEVATION)
	var az := deg_to_rad(SUN_AZIMUTH)
	var to_sun := Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el))
	$Sun.basis = Basis.looking_at(-to_sun, Vector3.UP)


func _type_info(entity_type: PackedInt32Array, force: int) -> Dictionary:
	var key := "%s/%d" % [entity_type, force]
	if not _type_cache.has(key):
		_type_cache[key] = {"name": DisEnums.get_entity_type_name(entity_type),
				"sidc": DisEnums.entity_type_to_sidc(entity_type, force)}
	return _type_cache[key]


func _make_entity(number: int, force: int, entity_type: PackedInt32Array, marking: String, dr: int) -> DisEntity:
	var entity := DisEntity.new()
	entity.name = "DisEntity"
	entity.entity_id = Vector3i(0, 0, number)  # site / application from the network
	entity.force_id = force
	entity.entity_type = entity_type
	entity.marking = marking
	entity.dr_algorithm = dr
	return entity


## Land units from the scenario and the air defence post.
func _spawn_units() -> void:
	var number := 2  # 1 is the UAV
	var list: Array = ShowcaseScenario.UNITS.duplicate(true)
	var ad: Dictionary = ShowcaseScenario.AD_UNIT.duplicate(true)
	ad.route = [ShowcaseScenario.AD_POSITION]
	list.append(ad)
	for u: Dictionary in list:
		var unit := ShowcaseGroundUnit.new()
		unit.name = u.marking
		unit.route = PackedVector3Array(u.route)
		unit.speed = u.speed
		unit.distance = u.get("start", 0.0)
		unit.terrain = terrain
		var entity_type := PackedInt32Array(u.entity_type)
		var entity := _make_entity(number, u.force, entity_type, u.marking, 2)  # FPW for land units
		number += 1
		unit.add_child(entity)
		var visual := ShowcaseUnitVisual.new()
		visual.name = "Visual"
		visual.terrain = terrain
		visual.setup(entity_type, u.force, u.marking, _type_info(entity_type, u.force).sidc)
		unit.add_child(visual)
		own_forces.add_child(unit)
		entity.network_path = entity.get_path_to(network)
		if u == ad:
			ad_post = unit
		else:
			units.append(unit)


## The UAV: JSBSimAircraft (J3Cub flight model) in the air on the route, its autopilot and DIS entity.
func _spawn_uav() -> void:
	var s: Dictionary = ShowcaseScenario.UAV
	route = ShowcaseScenario.route_points(terrain)
	for p in route:
		route_height = maxf(route_height, p.y)

	aircraft = JSBSimAircraft.new()
	aircraft.name = "UAV"
	aircraft.origin_latitude = origin.latitude
	aircraft.origin_longitude = origin.longitude
	aircraft.origin_height = origin.height
	var start: Vector3 = s.start
	var g := terrain.global_to_geodetic(Vector3(start.x, route[0].y, start.z))
	aircraft.latitude = g[0]
	aircraft.longitude = g[1]
	aircraft.height = route[0].y
	aircraft.heading = s.heading
	aircraft.airspeed = s.speed_kt
	aircraft.add_child(load("res://demo/uav_model.gd").new())
	autopilot = JSBSimAutopilot.new()
	autopilot.name = "Autopilot"
	aircraft.add_child(autopilot)
	uav_entity = _make_entity(1, ShowcaseScenario.FRIENDLY, PackedInt32Array(s.entity_type), s.marking, 4)
	aircraft.add_child(uav_entity)  # JSBSimAircraft gives it its velocities, acceleration and turn rates
	var visual := ShowcaseUnitVisual.new()
	visual.name = "Visual"
	visual.terrain = terrain
	visual.with_model = false
	visual.setup(PackedInt32Array(s.entity_type), ShowcaseScenario.FRIENDLY, s.marking, s.sidc)
	aircraft.add_child(visual)
	add_child(aircraft)  # starts (trims) the flight model
	aircraft.ground_path = aircraft.get_path_to(terrain)
	aircraft.geo_origin_path = aircraft.get_path_to(origin)
	uav_entity.network_path = uav_entity.get_path_to(network)
	if not aircraft.is_started():
		_fail("cannot start the flight model: " + aircraft.get_fdm().get_last_error())
		return
	aircraft.crashed.connect(func(reason: String) -> void: _say("UAV crashed: " + reason))
	aircraft.failed.connect(func(reason: String) -> void: _say("Flight model failed: " + reason))

	autopilot.engage()
	autopilot.target_altitude = route[0].y
	autopilot.target_speed = s.speed_kt
	autopilot.altitude_hold = true
	autopilot.speed_hold = true
	for p in route:
		autopilot.add_waypoint_local(p)
	autopilot.loop_route = true
	autopilot.follow_route = true
	autopilot.waypoint_reached.connect(func(i: int) -> void:
			waypoints_reached += 1
			_say("UAV reached waypoint %d" % (i + 1)))


func _setup_sight() -> void:
	sight = ShowcaseSight.new()
	sight.name = "Sight"
	sight.terrain = terrain
	var p := ad_post.position
	sight.eye = Vector3(p.x, p.y + ShowcaseScenario.AD_EYE_HEIGHT, p.z)
	sight.target = aircraft
	sight.viewshed_ready.connect(func(image: Image, rect: Rect2) -> void:
			map.set_viewshed(ImageTexture.create_from_image(image), rect))
	add_child(sight)


func set_time_scale(scale: float) -> void:
	time_scale = clampf(scale, 0.125, 16.0)
	if not replaying:
		aircraft.time_scale = time_scale
		for u: ShowcaseGroundUnit in own_forces.get_children():
			u.time_scale = time_scale
	sight.time_scale = time_scale


func _physics_process(delta: float) -> void:
	if replaying or aircraft == null or not aircraft.is_started():
		return
	if not aircraft.paused:
		game_time += delta * time_scale
	var agl := aircraft.position.y - terrain.height_at(aircraft.position.x, aircraft.position.z)
	if not is_nan(agl):
		min_agl = minf(min_agl, agl)
	_clearance_clock -= delta * time_scale
	if _clearance_clock <= 0.0:
		_clearance_clock = 1.0
		var top := ShowcaseScenario.top_at(terrain, aircraft.position.x, aircraft.position.z)
		if top > -INF:
			min_clearance = minf(min_clearance, aircraft.position.y - top)
	_trail_clock -= delta * time_scale
	if _trail_clock <= 0.0:
		_trail_clock = TRAIL_INTERVAL
		map.add_trail_point(aircraft.position)
	if _quit_at >= 0.0 and game_time >= _quit_at:
		_quit_at = -1.0
		_finish(0)
	if _check:
		_check.step(delta)


func _process(delta: float) -> void:
	if map == null:
		return
	_frame_ms.append(delta * 1000.0)
	if _frame_ms.size() > FRAME_HISTORY:  # long unattended runs: keep the latest frames only
		_frame_ms = _frame_ms.slice(FRAME_HISTORY / 2)
	if _tour_clock >= 0.0:
		_advance_tour(delta)
	if replaying and _quit_at >= 0.0 and player.get_position() >= minf(_quit_at, player.get_duration() - 0.1):
		_quit_at = -1.0  # --seconds in playback: seconds of the recording
		_finish(0)
	_update_map()
	_update_hud()


func _update_map() -> void:
	if sight.result.has("from"):
		map.los_from = sight.result.from
		map.los_to = sight.result.to
		map.los_point = sight.result.point
		map.los_visible = sight.result.visible
	else:
		map.los_from = Vector3.INF
	if replaying:
		for entity: DisRemoteEntity in replay_manager.get_entities():
			if _replay_ids.has(entity.get_entity_id()):
				map.put_unit(_replay_ids[entity.get_entity_id()], "", entity.global_position, "", "Replay")
		return
	map.put_unit("own/UAV", ShowcaseScenario.UAV.sidc, aircraft.position, uav_entity.marking, "Friendly")
	for u: ShowcaseGroundUnit in own_forces.get_children():
		var e: DisEntity = u.get_node("DisEntity")
		map.put_unit("own/" + e.marking, _type_info(e.entity_type, e.force_id).sidc, u.position, e.marking,
				"Friendly" if e.force_id == ShowcaseScenario.FRIENDLY else "Opposing")
	for entity: DisRemoteEntity in manager.get_entities():
		map.put_unit(_remote_id(entity), _type_info(entity.get_entity_type(), entity.get_force_id()).sidc,
				entity.global_position, entity.get_marking(), "Remote")


func _update_hud() -> void:
	var lines := PackedStringArray()
	if replaying:
		lines.append("PLAYBACK  %s / %s  ×%s  %s" % [_clock(player.get_position()), _clock(player.get_duration()),
				player.speed, "playing" if player.is_playing() else "paused"])
		lines.append("Recording: %s" % _shown(recording_path))
		lines.append("Replayed entities: %d (translucent)" % replay_manager.get_entity_count())
	else:
		var fdm := aircraft.get_fdm()
		var agl := aircraft.position.y - terrain.height_at(aircraft.position.x, aircraft.position.z)
		var g := terrain.global_to_geodetic(aircraft.position)
		lines.append("UAV-1  %s  alt %.0f m  AGL %.0f m  IAS %.0f kt  hdg %03.0f°" % [GeoMath.geodetic_to_mgrs(g[0],
				g[1]), g[2], agl, fdm.get_property("velocities/vc-kts"), fposmod(fdm.get_property("attitude/psi-deg"), 360.0)])
		lines.append("Autopilot: waypoint %d/%d, %.1f km to go, cross-track %.0f m; %d reached" % [
				autopilot.get_active_waypoint() + 1, autopilot.get_waypoint_count(),
				autopilot.get_distance_to_waypoint() / 1000.0, autopilot.get_cross_track_error(), waypoints_reached])
		lines.append("Time %s  ×%s" % [_clock(game_time), time_scale])
		lines.append("DIS 239.1.2.3:%d  sent %d (UAV)  remote entities %d" % [network.port,
				uav_entity.get_published_count(), manager.get_entity_count()])
		lines.append("Recording: " + ("● %s, %d packets, %s" % [recording_path.get_file(), recorder.get_packet_count(),
				_clock(recorder.get_elapsed())] if recorder.is_recording() else "off (R)"))
	if sight.result.has("visible"):
		lines.append("R-AD → UAV: %s, %.1f km; in view %.0f %% of the time%s" % [
				"IN VIEW" if sight.result.visible else "hidden by " + str(sight.result.obstacle),
				sight.result.from.distance_to(sight.result.to) / 1000.0, 100.0 * sight.exposure(),
				("  viewshed %.0f ms" % sight.last_viewshed_ms) if sight.viewshed_on else ""])
	lines.append("F1 help")
	info.text = "\n".join(lines)
	banner.text = _message if _now() < _message_until else ""


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if replaying:
		match key.physical_keycode:
			KEY_SPACE:
				if player.is_playing():
					player.pause()
				else:
					player.play()
				return
			KEY_LEFT:
				player.seek(maxf(player.get_position() - 10.0, 0.0))
				return
			KEY_RIGHT:
				player.seek(minf(player.get_position() + 10.0, player.get_duration()))
				return
			KEY_HOME:
				player.seek(0.0)
				return
			KEY_UP, KEY_DOWN:
				var i := REPLAY_SPEEDS.find(player.speed)
				i = clampi((i if i >= 0 else 2) + (1 if key.physical_keycode == KEY_UP else -1), 0,
						REPLAY_SPEEDS.size() - 1)
				player.speed = REPLAY_SPEEDS[i]
				return
	match key.physical_keycode:
		KEY_TAB:
			_target_index = posmod(_target_index + (-1 if key.shift_pressed else 1), _targets.size())
			var t := _targets[_target_index]
			camera.target = t
			if t == aircraft:
				camera.distance = 90.0
			else:  # from above the roofs around a unit in the streets
				camera.distance = 160.0
				camera.pitch = minf(camera.pitch, -0.5)
			camera.snap()
		KEY_BRACKETLEFT:
			set_time_scale(time_scale * 0.5)
		KEY_BRACKETRIGHT:
			set_time_scale(time_scale * 2.0)
		KEY_V:
			_toggle_viewshed()
		KEY_M:
			map.toggle_size()
		KEY_R:
			if replaying:
				return
			if recorder.is_recording():
				recorder.stop()
			else:
				recording_path = DEFAULT_RECORDING
				_start_recording()
		KEY_P:
			if replaying:
				_exit_replay()
			else:
				_enter_replay()
		KEY_F1:
			$HUD/Help.visible = not $HUD/Help.visible
		KEY_F12:
			_screenshot("user://showcase_%s.png" % Time.get_datetime_string_from_system().replace(":", "-"))
		KEY_ESCAPE:
			get_tree().quit()


func _advance_tour(delta: float) -> void:
	_tour_clock += delta
	if _capture_dir != "":
		_capture()
		if _tour_clock >= TOUR_END:
			_tour_clock = -1.0
			_finish(0)
			return
	camera.yaw += TOUR_TURN * delta
	while _tour_step < TOUR.size() and _tour_clock >= TOUR[_tour_step][0]:
		var key := InputEventKey.new()
		key.physical_keycode = TOUR[_tour_step][1]
		key.keycode = key.physical_keycode
		key.shift_pressed = TOUR[_tour_step].size() > 2 and TOUR[_tour_step][2]
		key.pressed = true
		Input.parse_input_event(key)
		_tour_step += 1


## Saves the last drawn frame for every frame slot that has passed (a slow frame fills several slots), so the
## frames keep wall-clock time. PNG encoding runs on worker threads.
func _capture() -> void:
	var image: Image = null
	while _capture_frame < _tour_clock * CAPTURE_FPS:
		if image == null:
			image = get_viewport().get_texture().get_image()
		var path := _capture_dir.path_join("f%08d.png" % _capture_frame)
		# The bound arguments keep the image alive until the task has run (a Callable on image.save_png would not).
		_capture_tasks.append(WorkerThreadPool.add_task(_save_frame.bind(image, path)))
		_capture_frame += 1


static func _save_frame(image: Image, path: String) -> void:
	image.save_png(path)


func _start_recording() -> void:
	if recorder.start(recording_path) == OK:
		_say("Recording DIS traffic to " + recording_path, recording_path)
	else:
		_say("Cannot record to " + recording_path, recording_path)


# --- Playback ------------------------------------------------------------------------------------------------------

## Stops the live simulation and plays `recording_path` back: the replayed entities appear translucent in 3D
## and on the map's Replay layer. The live units are hidden and stop publishing until playback ends.
func _enter_replay() -> bool:
	if recorder.is_recording():
		recorder.stop()
	if not FileAccess.file_exists(recording_path):
		_say("No recording yet: press R to record, then P to play it back")
		return false
	if player.load(recording_path) != OK:
		_say("Cannot open %s: %s" % [recording_path, player.recording.get_last_error() if player.recording else ""],
				recording_path)
		return false
	replaying = true
	aircraft.paused = true
	for u: ShowcaseGroundUnit in own_forces.get_children():
		u.time_scale = 0.0
	for e: DisEntity in _own_entities():
		e.publishing = false
	aircraft.visible = false
	own_forces.visible = false
	for layer in ["Friendly", "Opposing", "Remote"]:
		map.map.set_layer_visible(layer, false)
	map.clear_trail()
	sight.target = null
	player.speed = 1.0
	player.seek(0.0)
	player.play()
	var summary := player.recording.get_summary()
	_say("Playback: %d packets, %s, %d entities" % [summary.packets, _clock(summary.duration), summary.entities])
	return true


func _exit_replay() -> void:
	player.stop()
	replay_manager.clear()
	for id: Variant in _replay_ids.values():
		map.remove_unit(id)
	_replay_ids.clear()
	replaying = false
	aircraft.paused = false
	aircraft.visible = true
	own_forces.visible = true
	for e: DisEntity in _own_entities():
		e.publishing = true
	for layer in ["Friendly", "Opposing", "Remote"]:
		map.map.set_layer_visible(layer, true)
	sight.target = aircraft
	set_time_scale(time_scale)
	camera.target = _targets[_target_index]
	_say("Live")


func _on_replay_appeared(entity: DisRemoteEntity) -> void:
	var info_ := _type_info(entity.get_entity_type(), entity.get_force_id())
	var sidc: String = ShowcaseScenario.UAV.sidc if entity.get_marking() == ShowcaseScenario.UAV.marking \
			else info_.sidc
	var visual := ShowcaseUnitVisual.new()
	visual.name = "Visual"
	visual.terrain = terrain
	visual.setup(entity.get_entity_type(), entity.get_force_id(), entity.get_marking(), sidc, true)
	entity.add_child(visual)
	var id := "replay/%s" % entity.get_entity_id()
	_replay_ids[entity.get_entity_id()] = id
	map.put_unit(id, sidc, entity.global_position, entity.get_marking(), "Replay")
	if entity.get_marking() == ShowcaseScenario.UAV.marking:
		sight.target = entity
		if camera.target == aircraft or not is_instance_valid(camera.target):
			camera.target = entity


func _on_replay_removed(entity: Node, _reason: String) -> void:
	var remote := entity as DisRemoteEntity
	if remote and _replay_ids.has(remote.get_entity_id()):
		map.remove_unit(_replay_ids[remote.get_entity_id()])
		_replay_ids.erase(remote.get_entity_id())
	if sight.target == entity:
		sight.target = null


# --- Remote entities (other simulations on the same exercise) -------------------------------------------------------

func _on_remote_appeared(entity: DisRemoteEntity) -> void:
	var visual := ShowcaseUnitVisual.new()
	visual.name = "Visual"
	visual.terrain = terrain
	visual.setup(entity.get_entity_type(), entity.get_force_id(), entity.get_marking(),
			_type_info(entity.get_entity_type(), entity.get_force_id()).sidc)
	entity.add_child(visual)


func _remote_id(entity: Node) -> String:
	return "remote/%s" % (entity as DisRemoteEntity).get_entity_id()


# --- Helpers ---------------------------------------------------------------------------------------------------------

func own_entities() -> Array[DisEntity]:
	return _own_entities()


func _own_entities() -> Array[DisEntity]:
	var result: Array[DisEntity] = [uav_entity]
	for u: ShowcaseGroundUnit in own_forces.get_children():
		result.append(u.get_node("DisEntity"))
	return result


## Shows a message for a few seconds. The screen shows Godot paths (user://...), which keeps screenshots and
## recordings of the screen free of local folder names; the console also gets the full path of `path`.
func _say(text: String, path := "") -> void:
	var full := ProjectSettings.globalize_path(path)
	print(text + ("" if full == path else " (%s)" % full))
	_message = text.replace(path, _shown(path)) if path != "" else text
	_message_until = _now() + 4.0


## A path as the screen shows it: Godot paths as they are, other paths by their file name only.
static func _shown(path: String) -> String:
	return path if path.begins_with("user://") or path.begins_with("res://") else path.get_file()


static func _now() -> float:
	return Time.get_ticks_usec() / 1.0e6


static func _clock(seconds: float) -> String:
	return "%d:%04.1f" % [int(seconds) / 60, fmod(seconds, 60.0)]


func _screenshot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(path)
	_say("Screenshot %s (%s)" % [path, error_string(error)], path)


func _finish(code: int) -> void:
	if recorder.is_recording():
		recorder.stop()
	for task in _capture_tasks:
		WorkerThreadPool.wait_for_task_completion(task)
	if _capture_dir != "":
		print("captured %d frames to %s" % [_capture_frame, _capture_dir])
	print(frame_summary())
	if _options.has("screenshot"):
		await _screenshot(str(_options.screenshot))
	get_tree().quit(code)


## Frame times of this run (wall clock, every drawn frame): median, 95th and 99th percentile.
func frame_stats() -> Dictionary:
	var f := Array(_frame_ms.slice(mini(60, _frame_ms.size() / 2)))  # without the start-up frames
	f.sort()
	if f.is_empty():
		return {"frames": 0}
	return {"frames": f.size(), "median_ms": snappedf(f[f.size() / 2], 0.01),
			"p95_ms": snappedf(f[int(f.size() * 0.95)], 0.01), "p99_ms": snappedf(f[int(f.size() * 0.99)], 0.01)}


func frame_summary() -> String:
	var st := frame_stats()
	if st.frames == 0:
		return "frames: none"
	if DisplayServer.get_name() == "headless":
		return "frames: %d without a window, median %.2f ms" % [st.frames, st.median_ms]
	var size := get_viewport().get_visible_rect().size
	return "frames: %d at %dx%d, median %.2f ms (%.0f fps), p95 %.2f ms, p99 %.2f ms, layers %s" % [st.frames,
			size.x, size.y, st.median_ms, 1000.0 / st.median_ms, st.p95_ms, st.p99_ms,
			"off" if _options.has("no-layers") else "on"]


func _fail(message: String) -> void:
	push_error("showcase: " + message)
	print("showcase: " + message)
	get_tree().quit(1)


func _parse_args(args: PackedStringArray) -> Dictionary:
	var result := {}
	var i := 0
	while i < args.size():
		var arg := args[i]
		if arg.begins_with("--"):
			var name := arg.substr(2)
			if i + 1 < args.size() and not args[i + 1].begins_with("--"):
				result[name] = args[i + 1]
				i += 1
			else:
				result[name] = true
		i += 1
	return result


func _toggle_viewshed() -> void:
	sight.toggle()
	if not sight.viewshed_on:
		map.set_viewshed(null, Rect2())
	_say("Viewshed of R-AD for the UAV's height above ground: " + ("computing ..." if sight.viewshed_on else "off"))
