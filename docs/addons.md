# Getting the add-ons

The demo needs four add-ons and one terrain package. None of them is in this repository; the project expects them
at fixed paths, and the scenes do not care how they got there:

```
addons/dis/            godot-dis        (GDExtension, C++)
addons/geo/            godot-geo        (GDScript)
addons/jsbsim/         godot-jsbsim     (GDExtension, C++, with the JSBSim library)
addons/milsymbol/      godot-milsymbol  (GDScript)
terrain/uskudar_10km/  terrain package from the godot-geo release (terrain.json, height, imagery, layers)
```

All five paths are git-ignored. There are two ways to fill them.

## 1. Release zips (users)
`tools/fetch_addons.py` downloads the release zips that `addons.json` pins and unpacks them:

```sh
python tools/fetch_addons.py --godot <path to the Godot executable>
```

| Package | Release file |
|---|---|
| godot-dis | `https://github.com/OWNER/godot-dis/releases/download/v0.1.0/godot-dis-0.1.0.zip` |
| godot-geo | `https://github.com/OWNER/godot-geo/releases/download/v0.1.0/godot-geo-0.1.0.zip` |
| godot-jsbsim | `https://github.com/OWNER/godot-jsbsim/releases/download/v0.1.0/godot-jsbsim-0.1.0.zip` |
| godot-milsymbol | `https://github.com/OWNER/godot-milsymbol/releases/download/v0.1.0/godot-milsymbol-0.1.0.zip` |
| Üsküdar terrain (10 × 10 km, 21 MB) | `https://github.com/OWNER/godot-geo/releases/download/v0.1.0/godot-geo-terrain-uskudar-10km.zip` |
| optional, with `--all`: Üsküdar terrain (60 × 60 km, 245 MB) | `https://github.com/OWNER/godot-geo/releases/download/v0.1.0/godot-geo-terrain-uskudar-60km.zip` |

`OWNER` is a placeholder until the repositories are published; until then the script stops and says so.

- The add-on zips hold `addons/<name>/` at their root (the Godot Asset Library layout), with the compiled libraries
  for Windows and Linux in the C++ ones. The terrain zips hold `terrain/uskudar_10km/` (or `terrain/uskudar/`)
  and `terrain/.gdignore`, which keeps the editor from importing the terrain data.
- Downloads are cached in `.cache/downloads/` (git-ignored); `--force` unpacks again over existing folders.
- `--mirror DIR_OR_URL` takes the zips from a folder or another server instead of GitHub (offline machines, or to
  try release candidates before they are published).
- `addons.json` holds a SHA-256 for each file once the releases exist; a mismatch stops the script.

Without Python: download the five files from the table and unpack them into the project folder so that the paths
above exist, then run `godot --headless --path . --import` once.

## 2. Sibling repositories (development)
To work on an add-on and see the change in the demo at once, clone the add-on repositories next to this one, build
the two C++ add-ons and the terrain package there (each repository's `docs/building.md`, and godot-geo's
`docs/city.md` for the Üsküdar packages), then link them in:

```sh
python tools/link_addons.py --godot <path to the Godot executable>
```

It creates directory junctions (Windows) or symbolic links (Linux, macOS) to the sibling folders and imports the
project. `fetch_addons.py` never replaces a link; delete the links to switch back to the releases.

## Why release zips and not git submodules
- godot-dis and godot-jsbsim are C++ extensions whose compiled libraries are not in git. A submodule gives the
  sources only: every user would need a C++ toolchain, SCons and CMake, and the JSBSim build, before the demo opens.
- The terrain packages are generated data (21 MB and 245 MB zipped); they live on the godot-geo release, not in its
  git history.
- A pinned release (version in `addons.json`, checksum of the file) is as reproducible as a submodule commit, and
  the demo is then tested against exactly what add-on users get.

Contributors who change an add-on use the sibling layout above; submodules can be added later if a combined
"build everything from source" checkout turns out to be useful.

## Updating the pins
When an add-on makes a release: change its `version` and `asset` in `addons.json`, run
`python tools/fetch_addons.py --force`, put the printed SHA-256 into `addons.json`, run the self-test
(`godot --headless --path . -- --check 480`), and note the change in `CHANGELOG.md`.
