# Changelog

All notable changes to this project are documented here. Versions follow [semver](https://semver.org/).

## [Unreleased]
### Changed
- The showcase moved from Ankara to Üsküdar, Istanbul (godot-geo packages `uskudar_10km`, default, and `uskudar`,
  60 km, with `--terrain 10km|60km`): buildings, trees, roads and water are drawn; the UAV loop crosses the Bosphorus
  and the Çamlıca hills, each waypoint 180 m above the highest building, tree or ground on its leg; land units drive
  on streets of the package's road layer; a patrol boat (DIS surface platform) runs on the Bosphorus; the air defence
  post's line of sight and viewshed are blocked by buildings and tree crowns too (about half of each lap in view);
  new control measures. Units, post and exercise are imaginary and kept away from military areas.
- Line of sight queries run on worker threads; the "in view" share is weighted by game time.
- `addons.json` pins the godot-geo terrain assets `godot-geo-terrain-uskudar-10km.zip` (and, with
  `fetch_addons.py --all`, `-60km.zip`); `fetch_addons.py` also unpacks the zip's `terrain/.gdignore`.
- The README animation, social preview and screenshots show Üsküdar; the scene's attribution box lists all data
  sources of the package.
### Added
- `--no-layers` (terrain without buildings, trees and roads), `--no-vsync`; frame times printed at the end of every
  run and in the `--check` report.
- `--check` also checks the UAV's clearance above buildings and trees.
- `tools/probe_route.gd` `scan`: tries air defence post positions on a grid.
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
