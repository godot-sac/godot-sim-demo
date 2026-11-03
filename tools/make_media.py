"""Makes the README animation and the social preview image from the frames of `--tour --capture`.

1. Record the tour as PNG frames (needs a window; 44 s, 1-2 GB of frames; see docs/media.md):
       godot --path . -- --tour --capture <frames> --port 3291
2. python tools/make_media.py <frames> [--start 15.5 --end 43.5] [--width 440 --fps 6 --colors 48] [--preview-at 37.3]
   writes build/media/showcase.gif (a release asset, not in git) and docs/images/social-preview.png
   (1280 x 640, for the repository settings).

Needs Pillow (pip install Pillow); it is a maintainer tool, the demo itself does not use Python.
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
TITLE = "godot-sim-demo"
SUBTITLE = "Flight dynamics, DIS, terrain and MIL-STD-2525D symbols in Godot 4"
# The terrain package's notices (terrain.json "attribution"), shortened to two lines for the image.
ATTRIBUTION = [
    "© OpenStreetMap contributors, Overture Maps Foundation (ODbL 1.0). Contains modified Copernicus Sentinel data 2025. "
    "Copernicus WorldDEM-30 © DLR e.V. 2010-2014 and © Airbus Defence and Space GmbH 2014-2018,",
    "provided under COPERNICUS by the EU and ESA. Land cover © ESA WorldCover project 2021 (CC BY 4.0). Canopy height: "
    "ETH Global Canopy Height 2020, Lang et al. 2023 (CC BY 4.0). Building heights: GHS-BUILT-H R2023A, EC JRC (CC BY 4.0).",
]


def frame(frames: Path, rate: float, seconds: float) -> Image.Image:
    return Image.open(frames / f"f{round(seconds * rate):08d}.png").convert("RGB")


def font(size: int) -> ImageFont.ImageFont:
    for name in ["DejaVuSans.ttf", "arial.ttf", "segoeui.ttf"]:
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


def make_gif(frames: Path, rate: float, start: float, end: float, width: int, fps: int, colors: int, out: Path) -> None:
    images = []
    t = start
    while t < end:
        im = frame(frames, rate, t)
        images.append(im.resize((width, round(im.height * width / im.width)), Image.LANCZOS))
        t += 1.0 / fps
    # One palette for all frames (from a few samples) keeps colours steady and the file smaller.
    sample = Image.new("RGB", (width, images[0].height * 4))
    for i in range(4):
        sample.paste(images[i * len(images) // 4], (0, i * images[0].height))
    palette = sample.quantize(colors=colors, method=Image.Quantize.MEDIANCUT)
    paletted = [im.quantize(palette=palette, dither=Image.Dither.NONE) for im in images]
    paletted[0].save(out, save_all=True, append_images=paletted[1:], duration=round(1000 / fps), loop=0,
                     optimize=True, disposal=1)
    print(f"{out.name}: {len(paletted)} frames, {out.stat().st_size / 1e6:.1f} MB")


def make_preview(frames: Path, rate: float, at: float, out: Path) -> None:
    im = frame(frames, rate, at)
    scale = 1280 / im.width
    im = im.resize((1280, round(im.height * scale)), Image.LANCZOS)
    top = (im.height - 640) // 2
    im = im.crop((0, top, 1280, top + 640))
    draw = ImageDraw.Draw(im, "RGBA")
    draw.rectangle((0, 0, 1280, 130), fill=(16, 20, 28, 255))  # also hides the HUD text
    draw.text((40, 22), TITLE, font=font(52), fill=(255, 255, 255))
    draw.text((42, 84), SUBTITLE, font=font(24), fill=(200, 210, 225))
    # The scene's own attribution text would be cut off by the crop: cover it with the shortened notices.
    draw.rectangle((0, 548, 1280, 640), fill=(16, 20, 28, 255))
    for i, line in enumerate(ATTRIBUTION):
        draw.text((12, 574 + 20 * i), line, font=font(11), fill=(225, 225, 225))
    im.save(out, optimize=True)
    print(f"{out.name}: {im.width} x {im.height}, {out.stat().st_size / 1e3:.0f} kB")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("frames", type=Path, help="folder with the PNG frames of --capture (f00000000.png, ...)")
    parser.add_argument("--rate", type=float, default=15.0, help="frames per second of the capture")
    parser.add_argument("--start", type=float, default=15.5, help="first second of the animation")
    parser.add_argument("--end", type=float, default=43.5, help="last second of the animation")
    parser.add_argument("--width", type=int, default=440)
    parser.add_argument("--fps", type=int, default=6)
    parser.add_argument("--colors", type=int, default=48)
    parser.add_argument("--preview-at", type=float, default=37.3, help="second of the social preview frame")
    parser.add_argument("--out", type=Path, default=ROOT / "docs" / "images", help="folder of the preview image")
    parser.add_argument("--gif-out", type=Path, default=ROOT / "build" / "media", help="folder of the animation")
    args = parser.parse_args()
    make_gif(args.frames, args.rate, args.start, args.end, args.width, args.fps, args.colors, args.gif_out / "showcase.gif")
    make_preview(args.frames, args.rate, args.preview_at, args.out / "social-preview.png")


if __name__ == "__main__":
    main()
