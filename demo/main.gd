extends Node
## Entry scene: checks that the four add-ons and a terrain package are present, then opens demo/showcase.tscn.
## The showcase scripts use the add-ons' classes directly, so without this step a missing add-on would only show
## up as script parse errors.

const SHOWCASE := "res://demo/showcase.tscn"
const ADDONS := [
	["godot-dis", "res://addons/dis/dis.gdextension", "DisNetwork"],
	["godot-jsbsim", "res://addons/jsbsim/jsbsim.gdextension", "JSBSimAircraft"],
	["godot-geo", "res://addons/geo/geo_terrain.gd", ""],
	["godot-milsymbol", "res://addons/milsymbol/milsymbol.gd", ""],
]
const PACKAGES := ["res://terrain/uskudar_10km", "res://terrain/uskudar"]


func _ready() -> void:
	var problems := PackedStringArray()
	for addon: Array in ADDONS:
		# Exported games keep scripts as remapped resources, so FileAccess alone does not see them.
		if not FileAccess.file_exists(addon[1]) and not ResourceLoader.exists(addon[1]):
			problems.append("%s is missing (%s)" % [addon[0], addon[1].get_base_dir()])
		elif addon[2] != "" and not ClassDB.class_exists(addon[2]):
			problems.append("%s is present but its library did not load (build it, or use a release zip)" % addon[0])
	if not PACKAGES.any(func(p: String) -> bool: return FileAccess.file_exists(p.path_join("terrain.json"))):
		problems.append("no terrain package in %s (uskudar_10km or uskudar)" % ("terrain/ next to the executable"
				if OS.has_feature("template") else "res://terrain/"))
	if problems.is_empty():
		get_tree().change_scene_to_file.call_deferred(SHOWCASE)
		return
	var text := "godot-sim-demo cannot start:\n  - " + "\n  - ".join(problems) + \
			"\nSet up the add-ons as described in README.md (Installation), then run\n" + \
			"  godot --headless --path . --import"
	printerr(text)
	var label := Label.new()
	label.text = text
	label.position = Vector2(24, 24)
	add_child(label)
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().has("--check"):
		get_tree().quit(1)
