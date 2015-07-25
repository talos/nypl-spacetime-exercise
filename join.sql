/*
 * Do a full cross-join between points and lines.  We don't have that many
 * points, after all.
 */
DROP TABLE IF EXISTS joined;
CREATE TABLE joined AS
SELECT *, ST_DISTANCE(p.point, wvc.wkb_geometry) as distance
FROM points p, west_village_centerlines wvc;

/*
 * Find the shortest distance from the join, we'll use that as a key to look
 * up the line after the fact.
 */
DROP TABLE IF EXISTS closest_ref;
CREATE TABLE closest_ref AS
SELECT address_id, address, min(distance) min_distance
FROM joined
GROUP BY address_id, address;

/*
 * Using the min distance, look up the row in the joined table.
 */
DROP TABLE IF EXISTS closest;
CREATE TABLE closest AS
SELECT cr.*, joined.point, joined.streetcode, joined.street
FROM joined, closest_ref cr
WHERE joined.address_id = cr.address_id AND
      joined.address = cr.address AND
      joined.distance = cr.min_distance;

