class_name ShowcaseMap
extends PanelContainer
## The 2D tactical map (godot-milsymbol TacticalMap2D) in a corner of the screen: units as MIL-STD-2525 symbols,
## control measures, and an overlay with the UAV route and track, the line of sight and the viewshed footprint.
## Scene positions are converted with the terrain (GeoTerrain.global_to_geodetic), so the map and the 3D view agree.

const SMALL := Vector2(460, 360)
const TRAIL_POINTS := 400

var map: TacticalMap2D
var terrain: GeoTerrain
var route := PackedVector3Array()
var los_from := Vector3.INF
var los_to := Vector3.INF
var los_point := Vector3.INF
var los_visible := false
var _under: Control  # viewshed and route, under the symbols
var _overlay: Control  # track and line of sight, over the symbols
var _trail := PackedVector3Array()
var _viewshed: Texture2D
var _viewshed_rect := Rect2()
var _large := false


func setup(p_terrain: GeoTerrain) -> void:
	terrain = p_terrain
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	_resize()
	map = TacticalMap2D.new()
	map.symbol_size = 30.0
	map.label_limit = 60
	add_child(map)
	for layer: String in ["Control measures", "Friendly", "Opposing", "Remote", "Replay"]:
		map.add_layer(layer)
	var origin := terrain.global_to_geodetic(Vector3.ZERO)
	map.center_on(origin[0], origin[1], 60.0)
	_under = _layer_control(_draw_under)
	map.move_child(_under, 0)  # after the background, before the symbol layers
	_overlay = _layer_control(_draw_overlay)


## Toggles between the corner panel and a large map.
func toggle_size() -> void:
	_large = not _large
	_resize()


func _resize() -> void:
	var size_px := SMALL
	if _large:
		size_px = get_viewport_rect().size * Vector2(0.62, 0.72)
	offset_left = -size_px.x - 12.0
	offset_top = -size_px.y - 12.0
	offset_right = -12.0
	offset_bottom = -12.0


func geodetic(p: Vector3) -> PackedFloat64Array:
	return terrain.global_to_geodetic(p)


func add_graphic(id: String, sidc: String, points: Array, amplifiers: Dictionary) -> void:
	var lon_lat := PackedVector2Array()
	for p: Vector3 in points:
		var g := geodetic(p)
		lon_lat.append(Vector2(g[1], g[0]))
	map.add_graphic(id, sidc, lon_lat, amplifiers, "Control measures")


## Adds or moves a unit at a scene position.
func put_unit(id: Variant, sidc: String, p: Vector3, label: String, layer: String) -> void:
	var g := geodetic(p)
	if map.has_unit(id):
		map.move_unit(id, g[0], g[1])
	else:
		map.add_unit(id, sidc, g[0], g[1], label, layer)


func remove_unit(id: Variant) -> void:
	if map.has_unit(id):
		map.remove_unit(id)


func add_trail_point(p: Vector3) -> void:
	_trail.append(p)
	if _trail.size() > TRAIL_POINTS:
		_trail = _trail.slice(_trail.size() - TRAIL_POINTS)


func clear_trail() -> void:
	_trail.clear()


func set_viewshed(texture: Texture2D, rect: Rect2) -> void:
	_viewshed = texture
	_viewshed_rect = rect


func _process(_delta: float) -> void:
	if _overlay:
		_under.queue_redraw()
		_overlay.queue_redraw()


func _screen(p: Vector3) -> Vector2:
	var g := geodetic(p)
	return map.lat_lon_to_screen(g[0], g[1])


func _layer_control(draw: Callable) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.draw.connect(draw)
	map.add_child(c)
	return c


func _draw_under() -> void:
	if _viewshed:
		# The viewshed is a square in the local plane; over a few km Web Mercator maps it to a rectangle.
		var nw := _screen(Vector3(_viewshed_rect.position.x, 0, _viewshed_rect.position.y))
		var se := _screen(Vector3(_viewshed_rect.end.x, 0, _viewshed_rect.end.y))
		_under.draw_texture_rect(_viewshed, Rect2(nw, se - nw), false, Color(1, 1, 1, 0.7))
	if route.size() > 1:
		var pts := PackedVector2Array()
		for p in route:
			pts.append(_screen(p))
		pts.append(pts[0])
		_under.draw_polyline(pts, Color(0.55, 0.8, 1.0, 0.5), 1.5)
		for p in pts:
			_under.draw_circle(p, 3.0, Color(0.55, 0.8, 1.0, 0.8))


func _draw_overlay() -> void:
	if _trail.size() > 1:
		var pts := PackedVector2Array()
		for p in _trail:
			pts.append(_screen(p))
		_overlay.draw_polyline(pts, Color(1, 1, 1, 0.6), 1.0)
	if los_from != Vector3.INF and los_to != Vector3.INF:
		var a := _screen(los_from)
		var b := _screen(los_to)
		if los_visible:
			_overlay.draw_line(a, b, Color(1.0, 0.3, 0.25, 0.9), 2.0)
		else:
			var c := _screen(los_point)
			_overlay.draw_line(a, c, Color(1.0, 0.85, 0.3, 0.9), 2.0)
			_overlay.draw_dashed_line(c, b, Color(0.8, 0.8, 0.8, 0.6), 1.0, 6.0)
