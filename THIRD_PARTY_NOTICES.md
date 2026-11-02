# Third-Party Notices

This repository contains only the demo project. The add-ons and the terrain package are installed next to it
(`addons/`, `terrain/`) and are not part of this repository; each carries its own licence and notices, which apply
when you distribute the project with them:

- **godot-dis** (MIT): bundles open-dis-cpp (BSD-2-Clause) and SISO-REF-010 enumeration data
  ("Reprinted with permission from SISO Inc."); see its `THIRD_PARTY_NOTICES.md`.
- **godot-geo** (MIT); the Üsküdar terrain packages contain data from Copernicus DEM, Sentinel-2, OpenStreetMap
  (via Overture Maps), ESA WorldCover, ETH Global Canopy Height and GHSL with the notices below (also in each
  package's `terrain.json`).
- **godot-jsbsim** (MIT): links JSBSim (LGPL-2.1) dynamically; aircraft data (J3Cub) is LGPL-2.1, see its
  `addons/jsbsim/data/LICENSE.md` and the model's `NOTICE.md`.
- **godot-milsymbol** (MIT): port of milsymbol (MIT, Copyright (c) 2017 Måns Beckman - www.spatialillusions.com);
  control measure tables from Esri joint-military-symbology-xml (Apache-2.0).

## Data shown on screen and in `docs/images/`
The demo shows these notices in its window (bottom left, from the terrain package), and the screenshots and the
animation in `docs/images/` contain the same data.

### Copernicus DEM GLO-30
> produced using Copernicus WorldDEM-30 © DLR e.V. 2010-2014 and © Airbus Defence and Space GmbH 2014-2018 provided
> under COPERNICUS by the European Union and ESA; all rights reserved

The organisations in charge of the Copernicus programme by law or by delegation do not incur any liability for any
use of the Copernicus WorldDEM-30.

### Copernicus Sentinel-2
> Contains modified Copernicus Sentinel data 2025

### OpenStreetMap, Overture Maps (buildings, roads, water)
> © OpenStreetMap contributors, Overture Maps Foundation (ODbL 1.0, https://www.openstreetmap.org/copyright)

The terrain package's building, road and water layers are a derived database under the Open Database License 1.0.
The land unit routes in `demo/scenario.gd` are a few points along streets of that road layer.

### ESA WorldCover
> © ESA WorldCover project 2021 / Contains modified Copernicus Sentinel data (2021) processed by ESA WorldCover
> consortium (CC BY 4.0)

### ETH Global Canopy Height
> Canopy height: Lang, N., Jetz, W., Schindler, K., Wegner, J. D. (2023), A high-resolution canopy height model of
> the Earth, Nature Ecology & Evolution; ETH Global Canopy Height 2020, doi:10.3929/ethz-b-000609802 (CC BY 4.0)

### GHSL building heights
> Building heights: Pesaresi, M., Politis, P. (2023), GHS-BUILT-H R2023A, European Commission, Joint Research Centre,
> doi:10.2905/85005901-3A49-48DD-9D19-6261354F56FE (CC BY 4.0)

### SISO-REF-010
DIS enumerations (entity type names, symbol mapping) reprinted with permission from SISO Inc.
