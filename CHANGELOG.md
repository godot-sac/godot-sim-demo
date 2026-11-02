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
- `addons.json` and `tools/fetch_addons.py`: download the pinned add-on release zips and the terrain package
  (cached, checksums, `--mirror` for a local folder); `docs/addons.md` explains both ways and the submodule decision.
- `docs/getting-started.md`: clone, one command, running showcase.
- `--tour`: presses the keys of a short tour by itself (unattended screens, the README animation); with
  `--capture DIR` it saves the frames in real time, and `tools/make_media.py` makes the README animation and the
  1280 × 640 social preview image from them (`docs/media.md`).
### Fixed
- The on-screen messages, the playback line and the help show Godot paths (`user://...`), so screenshots and
  recordings of the screen do not contain local folder names; the console still prints the full paths.
- `DisEntityManager.entity_removed` handlers take the signal's `reason` argument (removing entities printed errors).
- `tools/probe_heights.gd`, `tools/probe_route.gd`: terrain heights and route exposure for laying out scenarios.
