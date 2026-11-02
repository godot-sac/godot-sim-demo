# Animation and preview image

The README animation (`docs/images/showcase.gif`) and the social preview image (`docs/images/social-preview.png`,
1280 × 640, set by hand in the GitHub repository settings under "Social preview") are made from a recording of the
built-in tour, so they can be made again after a change to the scene.

## Record the tour
`--tour` presses the keys by itself: it turns the viewshed on, fast-forwards the first three minutes of the route
at 16×, then, at 4×, records the DIS traffic while the UAV comes out from behind the trees into the air defence
post's view (the line turns from yellow to red), opens the large map, moves the camera above the post and plays the
recording back. With `--capture` it saves the screen as PNG frames, 15 per second, and quits after 44 s:

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
Needs Pillow (`pip install Pillow`). Defaults: the animation is seconds 15.5 to 43.5 of the tour, 440 pixels wide at
6 frames per second with one shared 48-colour palette (about 4.7 MB; the city has much more detail than open
terrain, so larger settings quickly pass 8 MB); the preview is the frame at second 37.3 (the post seen from above),
cropped to 1280 × 640, with the project name and the data attribution on it. `--width`, `--fps`, `--colors`, `--start`,
`--end` and `--preview-at` change them.

## Size and where the files live
Git holds only files the README needs and that stay small. Larger media, such as a full-resolution video of the
tour, belong on the GitHub release as assets, not in git.

| File | In git | Size |
|---|---|---|
| `docs/images/showcase.gif` | yes (README) | about 4.7 MB |
| `docs/images/social-preview.png` | yes (upload it in the repository settings) | about 760 kB |
| `docs/images/showcase.jpg`, `playback.jpg` | yes (README, getting-started guide) | 180–270 kB each |
| full-resolution tour video | no: a release asset if wanted (encode the frames with any video tool) | |

## Attribution
Every image shows the terrain package's data (Copernicus DEM and Sentinel-2, OpenStreetMap / Overture Maps
buildings, roads and water, ESA WorldCover, ETH canopy height, GHSL building heights), so its notices must stay
visible: the scene draws them in the lower left corner on a dark box (from the package's `attribution`), the preview
image carries a shortened two-line version along the bottom edge (it covers the scene's own text, which the crop
would cut), and the README repeats them under the animation. At GIF size the in-scene text is too small to read,
which is why the README line is there.
