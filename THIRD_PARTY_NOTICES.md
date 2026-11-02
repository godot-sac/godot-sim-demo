# Third-Party Notices

This repository contains only the demo project. The add-ons and the terrain package are installed next to it
(`addons/`, `terrain/`) and are not part of this repository; each carries its own licence and notices, which apply
when you distribute the project with them:

- **godot-dis** (MIT): bundles open-dis-cpp (BSD-2-Clause) and SISO-REF-010 enumeration data
  ("Reprinted with permission from SISO Inc."); see its `THIRD_PARTY_NOTICES.md`.
- **godot-geo** (MIT); terrain packages contain modified Copernicus DEM and Sentinel-2 data with the notices below.
- **godot-jsbsim** (MIT): links JSBSim (LGPL-2.1) dynamically; aircraft data (J3Cub) is LGPL-2.1, see its
  `addons/jsbsim/data/LICENSE.md` and the model's `NOTICE.md`.
- **godot-milsymbol** (MIT): port of milsymbol (MIT, Copyright (c) 2017 Måns Beckman - www.spatialillusions.com);
  control measure tables from Esri joint-military-symbology-xml (Apache-2.0).

## Data shown on screen and in `docs/images/`
The demo shows these notices in its window (bottom left), and the screenshots in `docs/images/` contain the same data.

### Copernicus DEM GLO-30
> produced using Copernicus WorldDEM-30 © DLR e.V. 2010-2014 and © Airbus Defence and Space GmbH 2014-2018 provided
> under COPERNICUS by the European Union and ESA; all rights reserved

### Copernicus Sentinel-2
> Contains modified Copernicus Sentinel data 2025

### SISO-REF-010
DIS enumerations (entity type names, symbol mapping) reprinted with permission from SISO Inc.
