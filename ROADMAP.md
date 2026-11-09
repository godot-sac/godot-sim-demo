# Roadmap

godot-sim-demo is the joint showcase of four Godot add-ons: godot-dis, godot-geo, godot-jsbsim and
godot-milsymbol. It distributes no add-on itself; it pins their releases in `addons.json`.

## 0.1.0 (first release)
- Showcase in Üsküdar, Istanbul: UAV on autopilot, land units and a boat on DIS, tactical map with control
  measures, line of sight and viewshed past terrain, buildings and trees, recording and playback.
- Setup from the add-ons' release zips (`tools/fetch_addons.py`) or the sibling repositories
  (`tools/link_addons.py`); headless self-test `--check`; getting-started guide.

## Next
- A UAV flight model of its own in godot-jsbsim to replace the J3Cub stand-in.

Suggestions and bug reports are welcome as issues; see [CONTRIBUTING.md](CONTRIBUTING.md).
