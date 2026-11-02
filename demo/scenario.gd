class_name ShowcaseScenario
## The showcase scenario south-east of the terrain origin (Ankara). Positions are scene metres: x east, z south
## (−z north), the frame of godot-dis DisGeoOrigin and godot-geo GeoTerrain. Heights come from the terrain at run
## time. Entity types are SISO-REF-010 values; symbols come from DisEnums.entity_type_to_sidc().
## The friendly side is in the basin, the opposing side in the hills to the south-east.
## tools/probe_heights.gd prints the terrain heights for laying this out.

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
	"start": Vector3(-6000, 0, 2500),
	"heading": 95.0,
	"speed_kt": 75.0,
	"agl": 180.0,  # each waypoint's height above the highest ground on the leg to it
}

## Loop flown by the UAV's JSBSimAutopilot (about 41 km, 18 min at 75 kt): across the phase line, over the
## objective and the named area of interest in the hills, and back north of the objective.
const ROUTE := [Vector3(0, 0, 2000), Vector3(5000, 0, 5000), Vector3(10000, 0, 9000), Vector3(16000, 0, 10000),
		Vector3(16000, 0, 4000), Vector3(7000, 0, 4000)]

## The opposing air defence post covers the objective from the valley north of it; the hills east and south-east
## of the post hide the UAV on parts of the loop (about 60 % in view per lap, tools/probe_route.gd).
const AD_POSITION := Vector3(10000, 0, 0)
const AD_EYE_HEIGHT := 8.0

## {marking, entity_type, force, route (scene metres; one point = stationary), speed (m/s), start (m along route)}.
## Moving units drive back and forth along their route.
const UNITS := [
	{"marking": "T-1", "entity_type": [1, 1, TURKIYE, 1, 2, 0, 0], "force": FRIENDLY,
			"route": [Vector3(-9000, 0, 1000), Vector3(-5000, 0, 2000), Vector3(-1000, 0, 3500)], "speed": 6.0},
	{"marking": "T-2", "entity_type": [1, 1, TURKIYE, 1, 2, 0, 0], "force": FRIENDLY,
			"route": [Vector3(-9000, 0, 1000), Vector3(-5000, 0, 2000), Vector3(-1000, 0, 3500)], "speed": 6.0,
			"start": 600.0},
	{"marking": "ACV-1", "entity_type": [1, 1, TURKIYE, 2, 1, 0, 0], "force": FRIENDLY,
			"route": [Vector3(-8000, 0, 5000), Vector3(-4000, 0, 5500), Vector3(0, 0, 6000)], "speed": 5.0},
	{"marking": "SPA-1", "entity_type": [1, 1, TURKIYE, 4, 0, 0, 0], "force": FRIENDLY,
			"route": [Vector3(-11000, 0, 3000)], "speed": 0.0},
	{"marking": "R-T1", "entity_type": [1, 1, OTHER_COUNTRY, 1, 0, 0, 0], "force": OPPOSING,
			"route": [Vector3(7400, 0, 9200)], "speed": 0.0},
	{"marking": "R-T2", "entity_type": [1, 1, OTHER_COUNTRY, 1, 0, 0, 0], "force": OPPOSING,
			"route": [Vector3(8200, 0, 10000)], "speed": 0.0},
	{"marking": "R-AFV", "entity_type": [1, 1, OTHER_COUNTRY, 2, 0, 0, 0], "force": OPPOSING,
			"route": [Vector3(12000, 0, 7000), Vector3(9000, 0, 6500)], "speed": 4.0},
]
const AD_UNIT := {"marking": "R-AD", "entity_type": [1, 1, OTHER_COUNTRY, 28, 0, 0, 0], "force": OPPOSING,
		"speed": 0.0}

## Control measures for TacticalMap2D: {id, sidc, points (scene metres), amplifiers}. Point order per
## godot-milsymbol docs/control-measures.md (axis of advance: tip, centreline to the rear, arrowhead edge).
const GRAPHICS := [
	{"id": "PL ALPHA", "sidc": "10032500001403000000", "amplifiers": {"T": "ALPHA"},
			"points": [Vector3(2000, 0, -3000), Vector3(2300, 0, 6000), Vector3(1800, 0, 16000)]},
	{"id": "BOUNDARY", "sidc": "10032500001101000000", "amplifiers": {},
			"points": [Vector3(-14000, 0, 4200), Vector3(-6000, 0, 4000), Vector3(2000, 0, 4500)]},
	{"id": "AXIS STEEL", "sidc": "10032500001514030000", "amplifiers": {"T": "STEEL"},
			"points": [Vector3(6500, 0, 8300), Vector3(-1000, 0, 3200), Vector3(-8000, 0, 1500),
					Vector3(4800, 0, 8100)]},
	{"id": "OBJ IRON", "sidc": "10032500001517000000", "amplifiers": {"T": "IRON"},
			"points": [Vector3(6600, 0, 8600), Vector3(9000, 0, 8400), Vector3(9300, 0, 10800),
					Vector3(6800, 0, 11000)]},
	{"id": "NAI 1", "sidc": "10032500001202000000", "amplifiers": {"T": "1"},
			"points": [Vector3(14500, 0, 5000), Vector3(17500, 0, 5300), Vector3(17300, 0, 9000),
					Vector3(14300, 0, 8700)]},
	{"id": "EA HAMMER", "sidc": "10032500001513000000", "amplifiers": {"T": "HAMMER"},
			"points": [Vector3(3000, 0, 9000), Vector3(5500, 0, 9000), Vector3(5800, 0, 12000),
					Vector3(3200, 0, 12300)]},
]
