class_name ShowcaseScenario
## The showcase scenario in Üsküdar, Istanbul (godot-geo packages uskudar_10km and uskudar, origin 41.0200 N
## 29.0500 E). Positions are scene metres: x east, z south (−z north), the frame of godot-dis DisGeoOrigin and
## godot-geo GeoTerrain. Heights come from the terrain at run time (GeoTerrain.height_at: streets, and the sea surface
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
	"start": Vector3(-500, 0, -1550),
	"heading": 266.0,
	"speed_kt": 75.0,
	"agl": 180.0,  # each waypoint's height above the highest building, tree or ground on the leg to it
}

## Loop flown by the UAV's JSBSimAutopilot (about 18 km, 8 min at 75 kt): over the Bosphorus off Kuzguncuk and
## Salacak, east across Üsküdar and between the two Çamlıca hills, north-east over the opposing side and back west
## past Büyük Çamlıca. It stays south of the Bosphorus Bridge and well clear of the Çamlıca TV tower.
const ROUTE := [Vector3(-2700, 0, -1700), Vector3(-4300, 0, 0), Vector3(-1000, 0, -500), Vector3(2600, 0, -400),
		Vector3(4000, 0, -2200), Vector3(1600, 0, -1400)]

## The opposing air defence post east of the Çamlıca hills: the hills hide the UAV over the Bosphorus, and buildings
## and trees around the post hide it on parts of the eastern legs (tools/probe_route.gd).
const AD_POSITION := Vector3(3300, 0, -1300)
const AD_EYE_HEIGHT := 8.0

## {marking, entity_type, force, route (scene metres; one point = stationary), speed (m/s), start (m along route)}.
## Moving units drive back and forth along their route; land routes follow streets, the boat stays on the water.
const UNITS := [
	{"marking": "T-1", "entity_type": [1, 1, TURKIYE, 1, 2, 0, 0], "force": FRIENDLY,
			"route": [Vector3(-31, 0, -329), Vector3(601, 0, -358), Vector3(942, 0, -224), Vector3(1458, 0, -221),
					Vector3(1587, 0, -258), Vector3(1866, 0, -300)], "speed": 6.0},
	{"marking": "T-2", "entity_type": [1, 1, TURKIYE, 1, 2, 0, 0], "force": FRIENDLY,
			"route": [Vector3(-31, 0, -329), Vector3(601, 0, -358), Vector3(942, 0, -224), Vector3(1458, 0, -221),
					Vector3(1587, 0, -258), Vector3(1866, 0, -300)], "speed": 6.0, "start": 400.0},
	{"marking": "ACV-1", "entity_type": [1, 1, TURKIYE, 2, 1, 0, 0], "force": FRIENDLY,
			"route": [Vector3(-437, 0, -1583), Vector3(-388, 0, -1397), Vector3(-362, 0, -1214), Vector3(-341, 0, -889),
					Vector3(-300, 0, -660), Vector3(-235, 0, -445), Vector3(-149, 0, -254), Vector3(-51, 0, -94),
					Vector3(88, 0, 89)], "speed": 5.0},
	{"marking": "SPA-1", "entity_type": [1, 1, TURKIYE, 4, 0, 0, 0], "force": FRIENDLY,
			"route": [Vector3(-1301, 0, -701)], "speed": 0.0},
	{"marking": "PB-1", "entity_type": [1, 3, TURKIYE, 7, 0, 0, 0], "force": FRIENDLY,  # surface, light / patrol craft
			"route": [Vector3(-2700, 0, -1600), Vector3(-3500, 0, -700), Vector3(-4150, 0, 200)], "speed": 6.0},
	{"marking": "R-T1", "entity_type": [1, 1, OTHER_COUNTRY, 1, 0, 0, 0], "force": OPPOSING,
			"route": [Vector3(3308, 0, -736)], "speed": 0.0},
	{"marking": "R-T2", "entity_type": [1, 1, OTHER_COUNTRY, 1, 0, 0, 0], "force": OPPOSING,
			"route": [Vector3(3453, 0, -787)], "speed": 0.0},
	{"marking": "R-AFV", "entity_type": [1, 1, OTHER_COUNTRY, 2, 0, 0, 0], "force": OPPOSING,
			"route": [Vector3(3122, 0, -1053), Vector3(3256, 0, -1162), Vector3(3395, 0, -1226), Vector3(3534, 0, -1252),
					Vector3(3632, 0, -1252), Vector3(3824, 0, -1223), Vector3(4606, 0, -1017), Vector3(4757, 0, -995),
					Vector3(4887, 0, -997)], "speed": 4.0},
]
const AD_UNIT := {"marking": "R-AD", "entity_type": [1, 1, OTHER_COUNTRY, 28, 0, 0, 0], "force": OPPOSING,
		"speed": 0.0}

## Control measures for TacticalMap2D: {id, sidc, points (scene metres), amplifiers}. Point order per
## godot-milsymbol docs/control-measures.md (axis of advance: tip, centreline to the rear, arrowhead edge).
const GRAPHICS := [
	{"id": "PL ALPHA", "sidc": "10032500001403000000", "amplifiers": {"T": "ALPHA"},
			"points": [Vector3(2500, 0, -4200), Vector3(2550, 0, -1500), Vector3(2450, 0, 1500), Vector3(2500, 0, 4200)]},
	{"id": "BOUNDARY", "sidc": "10032500001101000000", "amplifiers": {},
			"points": [Vector3(-1000, 0, 2300), Vector3(2000, 0, 2200), Vector3(4800, 0, 2300)]},
	{"id": "AXIS STEEL", "sidc": "10032500001514030000", "amplifiers": {"T": "STEEL"},
			"points": [Vector3(3100, 0, -850), Vector3(1500, 0, -280), Vector3(-100, 0, -330),
					Vector3(2650, 0, -1150)]},
	{"id": "OBJ IRON", "sidc": "10032500001517000000", "amplifiers": {"T": "IRON"},
			"points": [Vector3(3150, 0, -1000), Vector3(3700, 0, -1050), Vector3(3750, 0, -550),
					Vector3(3150, 0, -500)]},
	{"id": "NAI 1", "sidc": "10032500001202000000", "amplifiers": {"T": "1"},
			"points": [Vector3(4000, 0, -1450), Vector3(4850, 0, -1350), Vector3(4850, 0, -750),
					Vector3(4000, 0, -850)]},
	{"id": "EA HAMMER", "sidc": "10032500001513000000", "amplifiers": {"T": "HAMMER"},
			"points": [Vector3(2700, 0, -2400), Vector3(3600, 0, -2400), Vector3(3600, 0, -1700),
					Vector3(2700, 0, -1700)]},
]


## The route with heights for terrain following: each waypoint is `UAV.agl` above the highest point on the leg to it
## (buildings and trees included; sampled every 100 m, on the leg and 300 m to both sides). The autopilot climbs or
## descends to it along that leg.
static func route_points(terrain: GeoTerrain, route: Array = ROUTE, agl: float = UAV.agl) -> PackedVector3Array:
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
