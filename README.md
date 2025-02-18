 [![Code of Conduct](https://img.shields.io/badge/%E2%9D%A4-code%20of%20conduct-blue.svg?style=flat)](https://github.com/edgi-govdata-archiving/overview/blob/main/CONDUCT.md)

# EJAM-API
In February 2025, USEPA removed its EJScreen website from public access, including an API for querying EJScreen indices/indicators and Census data. One of the main features of the API was geographically-based inquiries. It could be used to, for instance, return  EJScreen and Census metrics weighted based on the Census Blocks within an 3 mile buffer around a selected point. The API facilitated the creation of [community reports](https://www.sf.gov/sites/default/files/2024-03/EJScreen%20Community%20Report.pdf) based on those kinds of queries. 

Recreating that API would require extensive reverse engineering of the ArcGIS map server(s) that hosted the API functionality. Instead, our approach is to draw on EJAM, an R package that produces similar kinds of outputs. EJAM does not currently provide an API; this repo contains files necessary to create a Docker image of EJAM and its dependencies as well as an API model.

# Model
There is currently one endpoint to the API - `report` - which accepts the following parameters:
- `lat` - the latitude of a given point
- `lon` - the longitude of that point
- `shape` - a GeoJSON object describing an area of interest, such as a polygon of neighborhood boundaries
- `buffer` - radius, in miles, around the center of a point or out from the edge of a polygon to extend the search. EJAM default = 3.
- `fips` - the Census FIPS code for a Block, Block Group, or Tract
`report` expects either `lat`/`lon` OR `shape` OR `fips`. The default buffer is 3 miles but can be explicitly set to 0.
An HTML format of a report is returned.

# Examples
Block Group in the Phoenix, AZ area with a 1 mile buffer: https://ejamapi-84652557241.us-central1.run.app/report?buffer=1&fips=040131109012
A point in the Phoenix area with a 4 mile buffer: https://ejamapi-84652557241.us-central1.run.app/report?lat=33&lon=-112&buffer=4
A rectangular area of interest in Phoenix, with no buffer: https://ejamapi-84652557241.us-central1.run.app/report?shape=%7B%22type%22%3A%22FeatureCollection%22%2C%22features%22%3A%5B%7B%22type%22%3A%22Feature%22%2C%22properties%22%3A%7B%7D%2C%22geometry%22%3A%7B%22coordinates%22%3A%5B%5B%5B-112.01991856401462%2C33.51124624304089%5D%2C%5B-112.01991856401462%2C33.47010908826502%5D%2C%5B-111.95488826248605%2C33.47010908826502%5D%2C%5B-111.95488826248605%2C33.51124624304089%5D%2C%5B-112.01991856401462%2C33.51124624304089%5D%5D%5D%2C%22type%22%3A%22Polygon%22%7D%7D%5D%7D&buffer=0

# Set-up
1. Work locally with EJAM by installing R/RStudio. Follow the instructions in the EJAM documentation.
2. Test changes to the API (i.e. modify `rest_controller.r`)
3. Re-build and tag the Docker image
4. Push to Docker Hub and/or Google Artifact Registry
5. Re-deploy in Google Cloud Run

---

## License & Copyright

Copyright (C) <year> Environmental Data and Governance Initiative (EDGI)
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.0.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the [`LICENSE`](/LICENSE) file for details.