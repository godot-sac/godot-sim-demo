extends SceneTree
## Measures the UAV route of demo/scenario.gd against an air defence post: per leg the waypoint height the showcase
## uses (terrain following over buildings and trees) and the share of the leg the post can see (buildings and trees
## block, as in the showcase). With "scan" it tries every candidate post on a grid instead and lists the best.
##   <godot> --headless --path . -s res://tools/probe_route.gd -- '<json>'
## json (all optional): {"package": "res://terrain/uskudar_10km", "ad": [x, z] (m; default the scenario's),
##   "route": [[x, z], ...] (m; default the scenario's), "agl": 180, "eye": 8,
##   "scan": [x0, z0, x1, z1, step] (m), "target": [0.3, 0.7] (wanted share in view for "scan")}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var cfg: Dictionary = JSON.parse_string(args[0]) if args.size() > 0 else {}
	var terrain := GeoTerrain.new()
	terrain.auto_layers = false  # queries only; the layers' data is read by GeoVisibility
	root.add_child(terrain)
	terrain.package_path = cfg.get("package", "res://terrain/uskudar_10km")
	await process_frame
	var plan := PackedVector3Array()  # empty: the scenario's route
	if cfg.has("route"):
		for p: Array in cfg.route:
			plan.append(Vector3(p[0], 0, p[1]))
	var route := ShowcaseScenario.route_points(terrain, plan, cfg.get("agl", ShowcaseScenario.UAV.agl))
	var samples := _samples(route)
	var eye_height: float = cfg.get("eye", ShowcaseScenario.AD_EYE_HEIGHT)
	if cfg.has("scan"):
		_scan(terrain, cfg.scan, samples, eye_height, cfg.get("target", [0.3, 0.7]))
		quit()
		return
	var ad := ShowcaseScenario.scene_point(terrain, ShowcaseScenario.AD_POSITION)
	if cfg.has("ad"):
		ad = Vector3(cfg.ad[0], 0, cfg.ad[1])
	var eye := Vector3(ad.x, terrain.height_at(ad.x, ad.z) + eye_height, ad.z)
	print("post at (%.0f, %.0f) m, eye %.0f m" % [eye.x, eye.z, eye.y])
	var total := 0
	var seen := 0
	var length := 0.0
	var blocked := {}
	for leg in samples.size():
		var leg_seen := 0
		var min_clear := INF
		for p: Vector3 in samples[leg]:
			min_clear = minf(min_clear, p.y - ShowcaseScenario.top_at(terrain, p.x, p.z))
			var r := terrain.line_of_sight(eye, p)
			if r.visible:
				leg_seen += 1
			else:
				blocked[r.obstacle] = blocked.get(r.obstacle, 0) + 1
		var a := route[(leg + route.size() - 1) % route.size()]
		var b := route[leg]
		total += samples[leg].size()
		seen += leg_seen
		length += a.distance_to(b)
		print("leg %d -> (%5.0f, %5.0f) m  height %4.0f m  %4.1f km  in view %3.0f %%  lowest clearance (straight) %4.0f m"
				% [leg, b.x, b.z, b.y, a.distance_to(b) / 1000.0, 100.0 * leg_seen / samples[leg].size(), min_clear])
	print("loop %.1f km, %.1f min at 75 kt, in view %.0f %%, hidden by %s" % [length / 1000.0, length / 38.6 / 60.0,
			100.0 * seen / total, blocked])
	quit()


## Points every 200 m along each leg (straight between the waypoints).
func _samples(route: PackedVector3Array) -> Array:
	var out := []
	for i in route.size():
		var a := route[(i + route.size() - 1) % route.size()]
		var b := route[i]
		var leg := []
		for k in int(a.distance_to(b) / 200.0) + 1:
			leg.append(a.lerp(b, k * 200.0 / a.distance_to(b)))
		out.append(leg)
	return out


func _scan(terrain: GeoTerrain, box: Array, samples: Array, eye_height: float, target: Array) -> void:
	var found := []
	var z: float = box[1]
	while z <= box[3]:
		var x: float = box[0]
		while x <= box[2]:
			var g := terrain.height_at(x, z)
			# On open ground: not on water, not inside a building footprint.
			if not is_nan(g) and terrain.water_at(x, z) < 0.1 and \
					terrain.package.layer_value("footprints", x, z) == 0:
				var eye := Vector3(x, g + eye_height, z)
				var seen := 0
				var total := 0
				for leg: Array in samples:
					for p: Vector3 in leg:
						total += 1
						if terrain.line_of_sight(eye, p).visible:
							seen += 1
				found.append([float(seen) / total, x, z])
			x += box[4]
		z += box[4]
	var mid: float = (target[0] + target[1]) * 0.5
	found.sort_custom(func(a: Array, b: Array) -> bool: return absf(a[0] - mid) < absf(b[0] - mid))
	print("%d candidates; nearest to %.0f %% in view:" % [found.size(), 100.0 * mid])
	for f: Array in found.slice(0, 25):
		print("  (%5.0f, %5.0f)  in view %3.0f %%" % [f[1], f[2], 100.0 * f[0]])
