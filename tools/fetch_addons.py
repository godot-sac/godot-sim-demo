"""Downloads the four add-ons and the terrain package from their GitHub releases and unpacks them into this project:

    addons/dis  addons/geo  addons/jsbsim  addons/milsymbol  terrain/uskudar_10km  (with --all also terrain/uskudar)

addons.json pins the repository, version and file of each package. Downloads are kept in .cache/downloads/, so a
second run does not download again; a checksum in addons.json is verified, a missing one is printed.
A folder that is already there is left alone (--force replaces it, but never a link made by tools/link_addons.py).

Usage (from the repo root, any Python 3.8+, no packages needed):
    python tools/fetch_addons.py [--owner NAME] [--mirror DIR_OR_URL] [--all] [--force] [--godot <godot executable>]
--owner      GitHub user or organisation of the add-on repositories (default: "owner" in addons.json)
--mirror     take the zips from this folder or URL instead of GitHub (files named as "asset" in addons.json)
--all        also the optional packages (the 60 km terrain, 245 MB download)
--godot      import the project once afterwards, so Godot registers the add-ons' classes
"""
import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / ".cache" / "downloads"
URL = "https://github.com/{owner}/{repo}/releases/download/v{version}/{asset}"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def download(source: str, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    partial = target.with_suffix(target.suffix + ".part")
    if "://" not in source:
        shutil.copyfile(source, partial)
    else:
        print(f"  downloading {source}")
        with urllib.request.urlopen(source, timeout=60) as response, partial.open("wb") as f:
            shutil.copyfileobj(response, f, 1 << 20)
    partial.replace(target)


def is_link(rel: str) -> bool:
    """True if rel or a folder above it in the project is a symbolic link or a directory junction."""
    return (ROOT / rel).resolve() != ROOT.resolve().joinpath(*PurePosixPath(rel).parts)


def unpack(archive: Path, rel: str) -> None:
    """Unpacks the folder rel (e.g. addons/dis) from the zip; it may sit at rel/ or at its last part (dis/).
    A .gdignore next to rel in the zip (terrain/.gdignore: the editor must not import terrain data) comes along."""
    with zipfile.ZipFile(archive) as z:
        names = z.namelist()
        ignore = str(PurePosixPath(rel).parent / ".gdignore")
        if ignore in names and not (ROOT / ignore).exists():
            (ROOT / ignore).parent.mkdir(parents=True, exist_ok=True)
            (ROOT / ignore).write_bytes(z.read(ignore))
        for prefix in (rel + "/", PurePosixPath(rel).name + "/"):
            members = [n for n in names if n.startswith(prefix) and not n.endswith("/")]
            if members:
                break
        else:
            raise RuntimeError(f"{archive.name} has no {rel}/ folder")
        target = ROOT / rel
        with tempfile.TemporaryDirectory(dir=ROOT) as tmp:
            staging = Path(tmp) / "x"
            for name in members:
                part = PurePosixPath(name[len(prefix):])
                # Zip names use "/"; a backslash or drive letter would be a separator on Windows (zip slip).
                if part.is_absolute() or ".." in part.parts or ":" in name or "\\" in name:
                    raise RuntimeError(f"{archive.name}: unsafe path {name}")
                out = staging.joinpath(*part.parts)
                if staging.resolve() not in out.resolve().parents:
                    raise RuntimeError(f"{archive.name}: unsafe path {name}")
                out.parent.mkdir(parents=True, exist_ok=True)
                with z.open(name) as src, out.open("wb") as dst:
                    shutil.copyfileobj(src, dst)
                mode = (z.getinfo(name).external_attr >> 16) & 0o777
                if mode & 0o111:
                    out.chmod(mode)
            # Move the old folder aside first: if a file in it is locked (an open editor holding a library), the
            # rename fails and the old add-on stays whole instead of half deleted.
            old = Path(tmp) / "old"
            if target.exists():
                target.replace(old)
            target.parent.mkdir(parents=True, exist_ok=True)
            staging.replace(target)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--owner", help="GitHub user or organisation of the add-on repositories")
    parser.add_argument("--mirror", help="folder or URL holding the release zips (instead of GitHub)")
    parser.add_argument("--all", action="store_true", help="also the optional packages (60 km terrain)")
    parser.add_argument("--force", action="store_true", help="replace folders that are already there")
    parser.add_argument("--godot", type=Path, help="Godot executable; import the project afterwards")
    args = parser.parse_args()
    config = json.loads((ROOT / "addons.json").read_text(encoding="utf-8"))
    owner = args.owner or config["owner"]
    if not args.mirror and owner == "OWNER":
        print("The add-on repositories are not published yet (addons.json has the placeholder owner OWNER).\n"
              "Pass --owner NAME, --mirror DIR with the release zips, or use tools/link_addons.py with the\n"
              "sibling repositories (docs/addons.md).", file=sys.stderr)
        return 2
    problems = 0
    packages = [p for p in config["packages"] if args.all or not p.get("optional")]
    for pkg in packages:
        rel, asset = pkg["path"], pkg["asset"]
        target = ROOT / rel
        if target.exists() or target.is_symlink():
            if is_link(rel):
                print(f"{rel} is a link to a sibling repository; left alone (remove the link to use the release)")
                continue
            if not args.force:
                print(f"{rel} already exists (--force replaces it)")
                continue
        cached = CACHE / pkg["repo"] / pkg["version"] / asset
        try:
            if not cached.is_file():
                if args.mirror:
                    source = args.mirror.rstrip("/") + "/" + asset
                    if "://" not in source:
                        source = str(Path(args.mirror) / asset)
                else:
                    source = URL.format(owner=owner, **pkg)
                download(source, cached)
            digest = sha256(cached)
            if pkg.get("sha256") and pkg["sha256"] != digest:
                cached.unlink()
                raise RuntimeError(f"checksum mismatch for {asset} (got {digest}); the download was removed")
            try:
                unpack(cached, rel)
            except zipfile.BadZipFile:
                cached.unlink()  # not a zip: download it again next time
                raise
            print(f"{rel} <- {pkg['repo']} {pkg['version']} {asset}"
                  + ("" if pkg.get("sha256") else f" (sha256 {digest})"))
        except (OSError, RuntimeError, zipfile.BadZipFile) as error:
            print(f"failed: {rel}: {error}", file=sys.stderr)
            problems += 1
    if args.godot:
        print("importing the project ...", flush=True)
        subprocess.run([str(args.godot), "--headless", "--path", str(ROOT), "--import"], check=False)
    elif not problems:
        print("Run once so Godot registers the classes: <godot> --headless --path . --import")
    total = len(packages)
    print(f"fetch_addons: done, {total - problems} of {total} packages in place"
          + (f"; {problems} failed (see above)" if problems else ""))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
