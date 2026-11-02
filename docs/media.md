# Animation and preview image

The README animation (`docs/images/showcase.gif`) and the social preview image (`docs/images/social-preview.png`,
1280 × 640, set by hand in the GitHub repository settings under "Social preview") are made from a recording of the
built-in tour, so they can be made again after a change to the scene.

## Record the tour
`--tour` presses the keys by itself: it fast-forwards the first four minutes of the route at 16×, then, at 4×,
records the DIS traffic while the UAV flies into the air defence post's view (the line turns from yellow to red),
opens the large map, moves the camera to the post and plays the recording back. With `--capture` it saves the screen
as PNG frames, 15 per second, and quits after 44 s:

```sh
godot --path . -- --tour --capture <frames> --port 3291
```

It needs a window (not `--headless`) and writes about 660 frames (1–2 GB) to `<frames>`. `--port 3291` keeps the run
off the default DIS port. The frames are taken in real time on purpose: Godot's Movie Maker mode (`--write-movie`)
would slow the game down against the wall clock that DIS timestamps, dead reckoning and the recorder use, and the
played-back units would freeze and disappear.

## Make the files
```sh
python tools/make_media.py <frames>
```
Needs Pillow (`pip install Pillow`). Defaults: the animation is seconds 15.5 to 43.5 of the tour, 480 pixels wide at
8 frames per second with one shared 64-colour palette (about 4 MB); the preview is the frame at second 26.5, cropped
to 1280 × 640, with the project name and the data attribution on it. `--width`, `--fps`, `--colors`, `--start`,
`--end` and `--preview-at` change them.

## Size and where the files live
Git holds only files the README needs and that stay small. Larger media, such as a full-resolution video of the
tour, belong on the GitHub release as assets, not in git.

| File | In git | Size |
|---|---|---|
| `docs/images/showcase.gif` | yes (README) | about 4 MB |
| `docs/images/social-preview.png` | yes (upload it in the repository settings) | about 650 kB |
| `docs/images/showcase.jpg`, `playback.jpg` | yes (README, getting-started guide) | ~150 kB each |
| full-resolution tour video | no: a release asset if wanted (encode the frames with any video tool) | |

## Attribution
Every image shows the terrain, so the Copernicus attribution must stay visible: the scene draws it in the lower left
corner (from the terrain package's `attribution`), the preview image carries it along the bottom edge, and the README
repeats it under the animation. At GIF size the in-scene text is too small to read, which is why the README line is
there.
