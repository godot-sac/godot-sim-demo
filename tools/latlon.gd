extends SceneTree
## Converts between WGS84 latitude / longitude and the scene metres of demo/scenario.gd (x east, z south, origin of
## the terrain package), and prints the ground height there, for placing units and waypoints in your own scenario.
##   <godot> --headless --path . -s res://tools/latlon.gd -- [--package DIR] geo:LAT,LON ... xz:X,Z ...
## Example: geo:41.0214,29.0805 -> Vector3(2565, 0, -156); xz:3300,-1300 -> 41.031699, 29.089241.
## A scenario for another area needs a terrain package of that area (godot-geo tools/build_terrain.py).


func _initialize() -> void:
	var args := Array(OS.get_cmdline_user_args())
	var package := "res://terrain/uskudar_10km"
	var i := args.find("--package")
	if i >= 0 and i + 1 < args.size():
		package = args[i + 1]
		args = args.slice(0, i) + args.slice(i + 2)
	var terrain := GeoTerrain.new()
	terrain.auto_layers = false  # positions and heights only
	root.add_child(terrain)
	terrain.package_path = package
	await process_frame
	if not terrain.is_loaded():
		printerr("cannot load the terrain package %s" % package)
		quit(1)
		return
	if args.is_empty():
		print("usage: -- [--package DIR] geo:LAT,LON ... xz:X,Z ...")
	for arg: String in args:
		var v := arg.substr(arg.find(":") + 1).split(",")
		if v.size() != 2 or not (arg.begins_with("geo:") or arg.begins_with("xz:")):
			printerr("not geo:LAT,LON or xz:X,Z: %s" % arg)
			continue
		if arg.begins_with("geo:"):
			var p := terrain.geodetic_to_global(float(v[0]), float(v[1]), 0.0)
			print("%s -> Vector3(%d, 0, %d)  ground %.1f m" % [arg, roundi(p.x), roundi(p.z),
					terrain.height_at(p.x, p.z)])
		else:
			var g := terrain.global_to_geodetic(Vector3(float(v[0]), 0.0, float(v[1])))
			print("%s -> %.6f, %.6f  ground %.1f m" % [arg, g[0], g[1], terrain.height_at(float(v[0]), float(v[1]))])
	quit()
