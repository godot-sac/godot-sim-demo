class_name ShowcaseScenario
## The showcase scenario in Üsküdar, Istanbul (godot-geo packages uskudar_10km and uskudar, origin 41.0200 N
## 29.0500 E). Positions are WGS84 latitude / longitude, Vector2(latitude, longitude) in degrees; scene_point()
## converts them with the loaded terrain package to scene metres (x east, z south, −z north; the frame of godot-dis
## DisGeoOrigin and godot-geo GeoTerrain), so another package of the area, with another origin, needs no change.
## tools/latlon.gd converts single points both ways. Heights come from the terrain at run time (GeoTerrain.height_at: streets, and the sea surface
## for the boat). Entity types are SISO-REF-010 values; symbols come from DisEnums.entity_type_to_sidc().
## The units, the air defence post and the exercise are imaginary. Land units drive on streets of the package's road
## layer (OpenStreetMap); nothing is placed at or next to a military area (the packages leave those out).
## The friendly side is around Bağlarbaşı and the Bosphorus, the opposing side east of the Çamlıca hills.
## tools/probe_route.gd measures the UAV route and the air defence post's view of it.

const TURKIYE := 218
const OTHER_COUNTRY := 0
const FRIENDLY := 1
const OPPOSING := 2

## DIS application of this demo (exercise 1 like the godot-dis, godot-geo and godot-jsbsim demos; own site).
const SITE := 5
const APPLICATION := 1

const UAV := {
	"marking": "UAV-1",
	"entity_type": [1, 2, TURKIYE, 50, 0, 0, 0],  # air platform, category 50 "Unmanned"
	"sidc": "10030100001103000000",  # MIL-STD-2525D air, military, unmanned aircraft
	"start": Vector2(41.033957, 29.044054),
	"heading": 266.0,
	"speed_kt": 75.0,
	"agl": 180.0,  # each waypoint's height above the highest building, tree or ground on the leg to it
}

## Loop flown by the UAV's JSBSimAutopilot (about 18 km, 8 min at 75 kt): over the Bosphorus off Kuzguncuk and
## Salacak, east across Üsküdar and between the two Çamlıca hills, north-east over the opposing side and back west
## past Büyük Çamlıca. It stays south of the Bosphorus Bridge and well clear of the Çamlıca TV tower.
const ROUTE := [Vector2(41.035303, 29.017892), Vector2(41.019989, 28.998876), Vector2(41.024502, 29.038110),
		Vector2(41.023598, 29.080914), Vector2(41.039800, 29.097571), Vector2(41.032605, 29.069026)]

## The opposing air defence post east of the Çamlıca hills: the hills hide the UAV over the Bosphorus, and buildings
## and trees around the post hide it on parts of the eastern legs (tools/probe_route.gd).
const AD_POSITION := Vector2(41.031699, 29.089241)
const AD_EYE_HEIGHT := 8.0

## {marking, entity_type, force, route (latitude / longitude; one point = stationary), speed (m/s), start (m along route)}.
## Moving units drive back and forth along their route; land routes follow streets, the boat stays on the water.
const UNITS := [
	{"marking": "T-1", "entity_type": [1, 1, TURKIYE, 1, 2, 0, 0], "force": FRIENDLY,
			"route": [Vector2(41.022963, 29.049631), Vector2(41.023223, 29.057146), Vector2(41.022016, 29.061200),
					Vector2(41.021989, 29.067335), Vector2(41.022322, 29.068869),
					Vector2(41.022699, 29.072186)], "speed": 6.0},
	{"marking": "T-2", "entity_type": [1, 1, TURKIYE, 1, 2, 0, 0], "force": FRIENDLY,
			"route": [Vector2(41.022963, 29.049631), Vector2(41.023223, 29.057146), Vector2(41.022016, 29.061200),
					Vector2(41.021989, 29.067335), Vector2(41.022322, 29.068869),
					Vector2(41.022699, 29.072186)], "speed": 6.0, "start": 400.0},
	{"marking": "ACV-1", "entity_type": [1, 1, TURKIYE, 2, 1, 0, 0], "force": FRIENDLY,
			"route": [Vector2(41.034254, 29.044803), Vector2(41.032579, 29.045386), Vector2(41.030931, 29.045695),
					Vector2(41.028005, 29.045945), Vector2(41.025943, 29.046433), Vector2(41.024007, 29.047206),
					Vector2(41.022287, 29.048228), Vector2(41.020846, 29.049394),
					Vector2(41.019199, 29.051046)], "speed": 5.0},
	{"marking": "SPA-1", "entity_type": [1, 1, TURKIYE, 4, 0, 0, 0], "force": FRIENDLY,
			"route": [Vector2(41.026311, 29.034531)], "speed": 0.0},
	{"marking": "PB-1", "entity_type": [1, 3, TURKIYE, 7, 0, 0, 0], "force": FRIENDLY,  # surface, light / patrol craft
			"route": [Vector2(41.034403, 29.017892), Vector2(41.026296, 29.008384),
					Vector2(41.018189, 29.000661)], "speed": 6.0},
	{"marking": "R-T1", "entity_type": [1, 1, OTHER_COUNTRY, 1, 0, 0, 0], "force": OPPOSING,
			"route": [Vector2(41.026621, 29.089334)], "speed": 0.0},
	{"marking": "R-T2", "entity_type": [1, 1, OTHER_COUNTRY, 1, 0, 0, 0], "force": OPPOSING,
			"route": [Vector2(41.027079, 29.091058)], "speed": 0.0},
	{"marking": "R-AFV", "entity_type": [1, 1, OTHER_COUNTRY, 2, 0, 0, 0], "force": OPPOSING,
			"route": [Vector2(41.029476, 29.087123), Vector2(41.030457, 29.088717), Vector2(41.031033, 29.090371),
					Vector2(41.031266, 29.092024), Vector2(41.031266, 29.093189), Vector2(41.031004, 29.095472),
					Vector2(41.029145, 29.104769), Vector2(41.028946, 29.106565),
					Vector2(41.028963, 29.108111)], "speed": 4.0},
]
const AD_UNIT := {"marking": "R-AD", "entity_type": [1, 1, OTHER_COUNTRY, 28, 0, 0, 0], "force": OPPOSING,
		"speed": 0.0}

## Control measures for TacticalMap2D: {id, sidc, points (latitude / longitude), amplifiers}. Point order per
## godot-milsymbol docs/control-measures.md (axis of advance: tip, centreline to the rear, arrowhead edge).
const GRAPHICS := [
	{"id": "PL ALPHA", "sidc": "10032500001403000000", "amplifiers": {"T": "ALPHA"},
			"points": [Vector2(41.057815, 29.079740), Vector2(41.033503, 29.080324), Vector2(41.006489, 29.079123),
					Vector2(40.982177, 29.079706)]},
	{"id": "BOUNDARY", "sidc": "10032500001101000000", "amplifiers": {},
			"points": [Vector2(40.999289, 29.038114), Vector2(41.000187, 29.073771), Vector2(40.999275, 29.107050)]},
	{"id": "AXIS STEEL", "sidc": "10032500001514030000", "amplifiers": {"T": "STEEL"},
			"points": [Vector2(41.027648, 29.086861), Vector2(41.022520, 29.067835), Vector2(41.022972, 29.048811),
					Vector2(41.030351, 29.081511)]},
	{"id": "OBJ IRON", "sidc": "10032500001517000000", "amplifiers": {"T": "IRON"},
			"points": [Vector2(41.028999, 29.087456), Vector2(41.029446, 29.093996), Vector2(41.024944, 29.094588),
					Vector2(41.024496, 29.087454)]},
	{"id": "NAI 1", "sidc": "10032500001202000000", "amplifiers": {"T": "1"},
			"points": [Vector2(41.033047, 29.097566), Vector2(41.032142, 29.107673), Vector2(41.026739, 29.107669),
					Vector2(41.027644, 29.097562)]},
	{"id": "EA HAMMER", "sidc": "10032500001513000000", "amplifiers": {"T": "HAMMER"},
			"points": [Vector2(41.041607, 29.082111), Vector2(41.041603, 29.092815), Vector2(41.035300, 29.092811),
					Vector2(41.035303, 29.082108)]},
]


## Scene position (metres, y = 0) of a Vector2(latitude, longitude) on the terrain package's origin.
static func scene_point(terrain: GeoTerrain, lat_lon: Vector2) -> Vector3:
	var g := terrain.geodetic_to_global(lat_lon.x, lat_lon.y, 0.0)
	return Vector3(g.x, 0.0, g.z)


## scene_point() of every Vector2(latitude, longitude) in the list.
static func scene_points(terrain: GeoTerrain, lat_lons: Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	for ll: Vector2 in lat_lons:
		out.append(scene_point(terrain, ll))
	return out


## The route with heights for terrain following: each waypoint is `UAV.agl` above the highest point on the leg to it
## (buildings and trees included; sampled every 100 m, on the leg and 300 m to both sides). The autopilot climbs or
## descends to it along that leg. `route` is in scene metres; empty means the scenario's ROUTE.
static func route_points(terrain: GeoTerrain, route: PackedVector3Array = PackedVector3Array(),
		agl: float = UAV.agl) -> PackedVector3Array:
	if route.is_empty():
		route = scene_points(terrain, ROUTE)
	var out := PackedVector3Array()
	var n := route.size()
	for i in n:
		var a: Vector3 = route[(i + n - 1) % n]
		var b: Vector3 = route[i]
		var side := (b - a).normalized().cross(Vector3.UP) * 300.0
		var highest := -INF
		for k in int(a.distance_to(b) / 100.0) + 1:
			var p := a.lerp(b, k * 100.0 / a.distance_to(b))
			for q: Vector3 in [p, p + side, p - side]:
				highest = maxf(highest, top_at(terrain, q.x, q.z))
		out.append(Vector3(b.x, highest + agl, b.z))
	return out


## Height of the highest thing at x, z: a building or tree top, else the ground; -INF outside the terrain.
static func top_at(terrain: GeoTerrain, x: float, z: float) -> float:
	var ground := terrain.height_at(x, z)
	if is_nan(ground):
		return -INF
	var hit := terrain.raycast(Vector3(x, ground + 1000.0, z), Vector3.DOWN, 1001.0)
	return maxf(ground, hit.position.y) if hit.hit else ground
