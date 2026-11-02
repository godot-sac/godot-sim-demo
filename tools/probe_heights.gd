extends SceneTree
## Prints a coarse height grid of the terrain package (scene metres, x east, z south) for laying out the scenario.
##   <godot> --headless --path . -s res://tools/probe_heights.gd -- [package] [step_m] [half_size_m]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var package := args[0] if args.size() > 0 else "res://terrain/uskudar_10km"
	var step := float(args[1]) if args.size() > 1 else 500.0
	var half := float(args[2]) if args.size() > 2 else 5000.0
	var terrain := GeoTerrain.new()
	root.add_child(terrain)
	terrain.package_path = package
	await process_frame
	var header := "z | x "
	var x := -half
	while x <= half:
		header += "%6d" % int(x / 1000.0)
		x += step
	print(header)
	var z := -half
	while z <= half:
		var line := "%5d" % int(z / 1000.0)
		x = -half
		while x <= half:
			line += "%6.0f" % terrain.height_at(x, z)
			x += step
		print(line)
		z += step
	quit()
