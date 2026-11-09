# Exporting the showcase

The showcase runs as an exported game on Windows and Linux with the add-ons' release zips: godot-dis and
godot-jsbsim load their release libraries, godot-jsbsim extracts its aircraft data to `user://jsbsim/`, and
godot-geo reads the terrain package from a folder next to the executable.

## Steps
1. Install the add-ons and the terrain package (see the README, Installation) and Godot 4.7.2's export templates
   (*Editor → Manage Export Templates*, or unpack `Godot_v4.7.2-stable_export_templates.tpz` into the editor's
   `export_templates/4.7.2.stable/` folder).
2. Export with the presets in `export_presets.cfg` (*Windows* and *Linux*, x86_64):
   ```sh
   godot --headless --path . --export-release "Windows" build/export/windows/godot-sim-demo.exe
   godot --headless --path . --export-release "Linux" build/export/linux/godot-sim-demo.x86_64
   ```
   Godot copies the GDExtension libraries and the JSBSim shared library next to the executable.
3. Copy the terrain package next to the executable, keeping the folder names:
   ```
   build/export/windows/
     godot-sim-demo.exe  godot-sim-demo.pck  JSBSim.dll  libgodot_dis....dll  libgodot_jsbsim....dll
     terrain/uskudar_10km/terrain.json  height.exr  ...
   ```
   (`terrain/uskudar` for the 60 km package, `--terrain 60km`.)

## Why the presets look like this
- **Include filter `*.json, *.xml, *.txt, *.md`:** the add-ons read data files that are not Godot resources
  (godot-dis and godot-milsymbol tables in JSON, the JSBSim aircraft in XML, licence notices); without the filter
  the export leaves them out.
- **Terrain outside the `.pck`:** godot-geo packages are plain files (EXR, PNG, binary layers) read with
  `FileAccess`, and `terrain/` has a `.gdignore`, so the export never packs them. In an exported game a `res://`
  path that is not in the `.pck` is looked up in the executable's folder, so `res://terrain/uskudar_10km` finds
  `terrain/uskudar_10km` next to the executable without code changes.
- **Separate `.pck`** (not embedded): the libraries have to sit next to the executable anyway.

## Tested
| Godot | Platform | Add-ons | Result |
|---|---|---|---|
| 4.7.2 release template | Windows 11 x86_64 | 0.1.0 release zips, terrain `uskudar_10km` | `--headless -- --check 480` 14/14; windowed 60 fps (vsync) |
| 4.7.2 release template | Linux x86_64, Ubuntu 24.04 (WSL2) | the same | `--headless -- --check 480` 14/14 |

Not tried: macOS, debug templates, other architectures.
