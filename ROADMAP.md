# Roadmap

godot-sim-demo is the joint showcase of four Godot add-ons: godot-dis, godot-geo, godot-jsbsim and
godot-milsymbol. It distributes no add-on itself; it pins their releases in `addons.json`.

## 0.1.0 (first release)
- Showcase in Üsküdar, Istanbul: UAV on autopilot, land units and a boat on DIS, tactical map with control
  measures, line of sight and viewshed past terrain, buildings and trees, recording and playback.
- Setup from the add-ons' release zips (`tools/fetch_addons.py`) or the sibling repositories
  (`tools/link_addons.py`); headless self-test `--check`; getting-started guide.

## Next
- Pin the add-on releases' SHA-256 checksums in `addons.json` once they are published.
- Continuous integration: fetch the release zips and run `--check 480` on Windows and Linux.
- A UAV flight model of its own in godot-jsbsim to replace the J3Cub stand-in.
- Fewer overlapping labels on the tactical map where units are close together.
- Scenario positions in latitude / longitude, so another terrain package needs no manual conversion.

Suggestions and bug reports are welcome as issues; see [CONTRIBUTING.md](CONTRIBUTING.md).
