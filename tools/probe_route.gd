extends SceneTree
## Lays out the UAV route: for an air defence post and a loop of waypoints (km, x east, z south) prints, per leg,
## the waypoint height the showcase would use (terrain following) and the share of the leg the post can see.
##   <godot> --headless --path . -s res://tools/probe_route.gd -- '<json>'
## json: {"ad": [x, z] or "box": [x, z, w, d], "route": [[x, z], ...], "agl": 250, "eye": 8}


func _initialize() -> void:
	var cfg: Dictionary = JSON.parse_string(OS.get_cmdline_user_args()[0])
	var terrain := GeoTerrain.new()
	root.add_child(terrain)
	terrain.package_path = cfg.get("package", "res://terrain/ankara_60km")
	await process_frame
	var agl: float = cfg.get("agl", 250.0)
	var eye: Vector3
	if cfg.has("box"):
		var b: Array = cfg.box
		eye = Vector3(0, -INF, 0)
		for z in range(int(b[1] * 1000), int((b[1] + b[3]) * 1000) + 1, 100):
			for x in range(int(b[0] * 1000), int((b[0] + b[2]) * 1000) + 1, 100):
				var h := terrain.height_at(x, z)
				if h > eye.y:
					eye = Vector3(x, h, z)
	else:
		eye = Vector3(cfg.ad[0] * 1000.0, 0, cfg.ad[1] * 1000.0)
		eye.y = terrain.height_at(eye.x, eye.z)
	eye.y += cfg.get("eye", 8.0)
	print("post at (%.1f, %.1f) km, eye %.0f m" % [eye.x / 1000.0, eye.z / 1000.0, eye.y])
	var pts: Array = cfg.route
	var n := pts.size()
	var total := 0
	var seen := 0
	var length := 0.0
	var heights := []
	for i in n:
		var a := Vector3(pts[(i + n - 1) % n][0], 0, pts[(i + n - 1) % n][1]) * 1000.0
		var b := Vector3(pts[i][0], 0, pts[i][1]) * 1000.0
		var side := (b - a).normalized().cross(Vector3.UP) * 300.0
		var highest := -INF
		for k in int(a.distance_to(b) / 100.0) + 1:
			var p := a.lerp(b, k * 100.0 / a.distance_to(b))
			for q: Vector3 in [p, p + side, p - side]:
				var h := terrain.height_at(q.x, q.z)
				if not is_nan(h):
					highest = maxf(highest, h)
		heights.append(highest + agl)
	for i in n:
		var a := Vector3(pts[(i + n - 1) % n][0], heights[(i + n - 1) % n], pts[(i + n - 1) % n][1] * 1.0)
		a.x *= 1000.0
		a.z *= 1000.0
		var b := Vector3(pts[i][0] * 1000.0, heights[i], pts[i][1] * 1000.0)
		var leg_total := 0
		var leg_seen := 0
		var min_agl := INF
		for k in int(a.distance_to(b) / 200.0) + 1:
			var p := a.lerp(b, k * 200.0 / a.distance_to(b))
			min_agl = minf(min_agl, p.y - terrain.height_at(p.x, p.z))
			leg_total += 1
			if terrain.line_of_sight(eye, p).visible:
				leg_seen += 1
		total += leg_total
		seen += leg_seen
		length += a.distance_to(b)
		print("leg %d -> (%5.1f, %5.1f) km  height %4.0f m  %4.1f km  in view %3.0f %%  min agl (straight) %4.0f m" % [
				i, pts[i][0], pts[i][1], heights[i], a.distance_to(b) / 1000.0, 100.0 * leg_seen / leg_total, min_agl])
	print("loop %.1f km, %.0f min at 75 kt, in view %.0f %%" % [length / 1000.0, length / 38.6 / 60.0,
			100.0 * seen / total])
	quit()
