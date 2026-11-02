# Changelog

All notable changes to this project are documented here. Versions follow [semver](https://semver.org/).

## [Unreleased]
### Added
- Showcase scene `demo/showcase.tscn` (opened by `demo/main.tscn`, which checks the add-ons first): a UAV-like
  aircraft (godot-jsbsim J3Cub, `JSBSimAutopilot`) flies a terrain-following waypoint loop over the Ankara terrain
  (godot-geo), the UAV and seven ground units are published on DIS (godot-dis), a `TacticalMap2D` panel shows their
  MIL-STD-2525D symbols and six control measures (godot-milsymbol), an opposing air defence post keeps a line of sight
  on the UAV and shows its viewshed (godot-geo), and DIS traffic is recorded and played back (godot-dis
  `DisRecorder` / `DisPlayer`).
- Command line options `--port`, `--terrain`, `--time-scale`, `--record`, `--replay`, `--viewshed`, `--seconds`,
  `--screenshot`, and a headless self-test `--check N` with a JSON report and exit code.
- `tools/link_addons.py`: links the add-ons and the terrain package from sibling repositories.
- `tools/probe_heights.gd`, `tools/probe_route.gd`: terrain heights and route exposure for laying out scenarios.
