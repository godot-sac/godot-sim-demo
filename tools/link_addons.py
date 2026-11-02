"""Links the four add-ons and the terrain packages from sibling repositories into this project (development setup):

    addons/dis        <- ../godot-dis/addons/dis              (GDExtension; build it there first)
    addons/geo        <- ../godot-geo/addons/geo
    addons/jsbsim     <- ../godot-jsbsim/addons/jsbsim        (GDExtension; build it there first)
    addons/milsymbol  <- ../godot-milsymbol/addons/milsymbol
    terrain           <- ../godot-geo/terrain                 (packages built by godot-geo tools/build_terrain.py)

Directory junctions on Windows (no admin rights or developer mode needed), symbolic links elsewhere; all are
git-ignored. A missing sibling is reported and skipped; the demo tells you at start-up what is still missing.

Usage (from the repo root, any Python 3): python tools/link_addons.py [--workspace ..] [--godot <godot executable>]
With --godot the project is imported once afterwards, so Godot registers the add-ons' classes.
"""
import argparse
import os
import subprocess
import sys
from pathlib import Path

LINKS = [
    ("addons/dis", "godot-dis/addons/dis"),
    ("addons/geo", "godot-geo/addons/geo"),
    ("addons/jsbsim", "godot-jsbsim/addons/jsbsim"),
    ("addons/milsymbol", "godot-milsymbol/addons/milsymbol"),
    ("terrain", "godot-geo/terrain"),
]
# Compiled libraries the GDExtensions need (not in git; built in the sibling repositories).
BINARIES = [("addons/dis/bin", "godot-dis: scons"), ("addons/jsbsim/bin", "godot-jsbsim: tools/build_jsbsim.py + scons")]


def link(target: Path, source: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    if os.name == "nt":
        subprocess.run(["cmd", "/c", "mklink", "/J", str(target), str(source)], check=True,
                       stdout=subprocess.DEVNULL)
    else:
        target.symlink_to(source, target_is_directory=True)


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--workspace", type=Path, default=root.parent, help="folder holding the sibling repos")
    parser.add_argument("--godot", type=Path, help="Godot executable; import the project after linking")
    args = parser.parse_args()
    problems = 0
    for target_rel, source_rel in LINKS:
        target = root / target_rel
        source = (args.workspace / source_rel).resolve()
        if target.exists() or target.is_symlink():
            print(f"{target_rel} already exists")
            continue
        if not source.is_dir():
            print(f"skipped {target_rel}: missing {source}; clone the sibling repository next to this one",
                  file=sys.stderr)
            problems += 1
            continue
        link(target, source)
        print(f"linked {target_rel} -> {source}")
    for binary_rel, how in BINARIES:
        folder = root / binary_rel
        if (root / binary_rel).parent.is_dir() and not (folder.is_dir() and any(folder.rglob("*.*"))):
            print(f"warning: {binary_rel} is empty; build the extension first ({how})", file=sys.stderr)
            problems += 1
    if not any((root / "terrain").glob("*/terrain.json")):
        print("warning: no terrain package; build godot-geo terrain/ankara_60km (godot-geo docs/demo-3d.md)",
              file=sys.stderr)
        problems += 1
    if args.godot:
        print("importing the project ...")
        subprocess.run([str(args.godot), "--headless", "--path", str(root), "--import"], check=False)
    else:
        print("Run once so Godot registers the classes: <godot> --headless --path . --import")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
