#!/bin/bash -e

export PGHOST=$(boot2docker ip || echo -n localhost)
export PGUSER=postgres
export PGPORT=54321
export PGDATABASE=postgres
export PGPASSWORD=docker4data

echo 'Importing addresses.json into postgres'
psql < schema.sql
python import.py

echo 'Importing west_village_centerlines.geojson into postgres'
ogr2ogr -overwrite -f PostgreSQL \
  PG:"host=$PGHOST user=$PGUSER port=$PGPORT dbname=$PGDATABASE password=$PGPASSWORD" \
  west_village_centerlines.geojson -nln west_village_centerlines

echo 'Joining west_village_centerlines to addresses'
psql < join.sql

echo 'Exporting joined data as closest.geojson'
rm -f closest.geojson
ogr2ogr -overwrite -f geojson closest.geojson \
  PG:"host=$PGHOST user=$PGUSER port=$PGPORT dbname=$PGDATABASE password=$PGPASSWORD" \
  -geomfield point \
  -sql "select * from closest" 2>/dev/null
