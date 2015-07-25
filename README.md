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
Gansevoort St" in the output geojson for an example of this; it should be 813
Washington St, but the Gansevoort centerline is in fact closer.

## How it works

The process is coordinated in `./process.sh`, which spits out helpful messages
about what it's doing.

    export PGHOST=$(boot2docker ip || echo -n localhost)
    export PGUSER=postgres
    export PGPORT=54321
    export PGDATABASE=postgres
    export PGPASSWORD=docker4data

First, a series of `export` statements tells our scripts where to find
postgres.  As I'm using Docker4data, it lives in a docker container exposing
port 54321.

    echo 'Importing addresses.json into postgres'
    psql < schema.sql
    python import.py

Then, we pipe in `schema.sql` to create our schema for points.  We use Python
to add our points into postgres, with lon/lat properly inserted as a `POINT`.

    echo 'Importing west_village_centerlines.geojson into postgres'
    ogr2ogr -overwrite -f PostgreSQL \
      PG:"host=$PGHOST user=$PGUSER port=$PGPORT dbname=$PGDATABASE password=$PGPASSWORD" \
      west_village_centerlines.geojson -nln west_village_centerlines

Next, we use `ogr2ogr` to import the `west_village_centerlines.geojson` into
Postgres.

    echo 'Joining west_village_centerlines to addresses'
    psql < join.sql

Now we can join the two tables.  Since the number of records being joined is
minimal, we don't have to worry about maximizing efficiency.  A simple
cross-join is done between the two tables, with the minimum distance between
every point and every line calculated and added to each joined row.

Next, we create a derivative table, grouped with one row for each point.  This
row contains minimum of all the distances to all the lines.

Finally, we re-join the derivative table to the joined table, using the point
and that minimum distance.  This lets us pull out the street name and
streetcode of the line with that minimum distance.

    echo 'Exporting joined data as closest.geojson'
    rm -f closest.geojson
    ogr2ogr -overwrite -f geojson closest.geojson \
      PG:"host=$PGHOST user=$PGUSER port=$PGPORT dbname=$PGDATABASE password=$PGPASSWORD" \
      -geomfield point \
      -sql "select * from closest" 2>/dev/null

We then export that final table as geojson, again using `ogr2ogr`.

## How we could be more efficient

If we were working with a scale of data where a cross-join was not practical,
instead we could draw generous buffers around each point, and take advantage of
a geographic index to join together the lines and points.

Depending on the size of the buffer, the join would still likely hit several
lines.  However, it would not hit every line, and would thus be much more
efficient.

We would still need to make a grouped table with the minimum distance, and
re-join as we did in the process above.  The joined table would just be much
smaller and faster to generate.
