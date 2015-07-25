DROP TABLE IF EXISTS points;

CREATE TABLE points (
    address_id INT,
    address TEXT,
    point GEOMETRY(point, 4326)
);
