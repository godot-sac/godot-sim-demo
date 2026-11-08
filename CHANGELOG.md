# Changelog

All notable changes to this project are documented here. Versions follow [semver](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-11-08
First release. Tested with godot-dis, godot-geo, godot-jsbsim and godot-milsymbol 0.1.0 (pinned in `addons.json`)
and Godot 4.7.2 on Windows 11 and Ubuntu 24.04.

### Added
- Showcase scene `demo/showcase.tscn` (opened by `demo/main.tscn`, which checks the add-ons first) in Üsküdar,
  Istanbul, on the godot-geo package `uskudar_10km` (or `uskudar`, 60 km, with `--terrain 60km`) with buildings,
  trees, roads and water:
  - a UAV-like aircraft (godot-jsbsim J3Cub flight model, `JSBSimAutopilot`) flies a six-waypoint loop over the
    Bosphorus and the Çamlıca hills, each waypoint 180 m above the highest building, tree or ground on its leg;
  - the UAV, land units driving on streets of the package's road layer and a patrol boat on the sea surface are
    published on DIS (godot-dis, multicast 239.1.2.3, exercise 1);
  - a `TacticalMap2D` panel shows their MIL-STD-2525D symbols and six control measures (godot-milsymbol);
  - an opposing air defence post keeps a line of sight on the UAV (terrain, buildings and tree crowns block; worker
    threads) and shows its viewshed (godot-geo);
  - DIS traffic is recorded and played back (godot-dis `DisRecorder` / `DisPlayer`).
  Units, post and exercise are imaginary and placed away from military areas.
- Command line options `--port`, `--terrain`, `--no-layers`, `--no-vsync`, `--time-scale`, `--record`, `--replay`,
  `--viewshed`, `--seconds`, `--screenshot`, `--tour`, `--capture`, and a headless self-test `--check N` (flight,
  waypoints, clearance above terrain, buildings and trees, DIS publishing, unit heights, line of sight and viewshed,
  map, recording and playback) with a JSON report and exit code. Frame times are printed at the end of a run.
- `addons.json` and `tools/fetch_addons.py`: download the pinned add-on release zips and the terrain package
  (cached, checksums, `--mirror`, `--all` for the 60 km package, safe unpacking); `tools/link_addons.py` links the
  sibling repositories for development; `docs/addons.md` explains both ways and why not git submodules.
- Tools for laying out a scenario: `tools/latlon.gd` (latitude / longitude to scene metres and back),
  `tools/probe_heights.gd`, `tools/probe_route.gd` (route exposure, scan for post positions).
- `docs/getting-started.md`, `docs/media.md`; `tools/make_media.py` makes the tour animation (a release asset) and
  the 1280 × 640 social preview image from `--tour --capture` frames.
- The scene shows the data notices of the terrain package (Copernicus DEM and Sentinel-2, OpenStreetMap / Overture
  Maps, ESA WorldCover, ETH canopy height, GHSL) and of SISO-REF-010, milsymbol and JSBSim; the screen shows Godot
  paths or file names only, never local folders.

[Unreleased]: https://github.com/godot-sac/godot-sim-demo/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/godot-sac/godot-sim-demo/releases/tag/v0.1.0
