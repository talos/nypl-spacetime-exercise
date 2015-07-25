## Prerequisites

As this was done quickly, the prerequisites are not the cleanest.
I used a containerized postgres/postgis from
[docker4data](http://dockerfordata.com).

However, the host computer still needs a GDAL install in order to execute the
scripts, as well as Python with `psycopg2` (which can be installed with `pip
install -r requirements.txt`).

If I had more time, I could package the processing scripts in the Docker
container and make it truly portable, as `gdal` is inside the container, too.

## Running

To run:

    ./process.sh

This should output a `closest.geojson` file joining
`west_village_centerlines.geojson` to `addresses.json` lon/lat points.

The output file contains the `streetcode` and `street` properties from
`west_village_centerlines.geojson`, drawn from the closest centerline.  The
closest centerline *does not* mean the proper street for that number, as the
address point could be closer to a street it does not correspond to.  See "813
Gansevoort St" (feature 0 in the output geojson) for an example of this; it
should be 813 Washington St, but the Gansevoort centerline is in fact closer.

## How it works

The process is coordinated in `./process.sh`, which spits out helpful messages
about what it's doing.

First, a series of `export` statements tells our scripts where to find
postgres.  As I'm using Docker4data, it lives in a docker container exposing
port 54321.

A Python script 
