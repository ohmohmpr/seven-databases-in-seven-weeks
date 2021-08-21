CREATE TABLE cities(
    name text NOT NULL,
    postal_code varchar(9) CHECK (postal_code <> ''),
    country_code char(2) REFERENCES countries,
    PRIMARY KEY (country_code, postal_code)
);

INSERT INTO cities
VALUES ('Toronto', 'M4C1B5', 'ca');

INSERT INTO cities
VALUES ('Portland', '87200', 'us');

UPDATE cities
SET postal_code = '97206'
WHERE name = 'Portland';

SELECT cities.*, country_name
FROM cities INNER JOIN countries
    ON cities.country_code = countries.country_code;

CREATE TABLE venues (
    venue_id SERIAL PRIMARY KEY,
    name varchar(255),
    street_address text,
    type char(7) CHECK ( type in ('public', 'private') ) DEFAULT 'public',
    postal_code varchar(9),
    country_code char(2),
    FOREIGN KEY ( country_code, postal_code)
        REFERENCES cities (country_code, postal_code) MATCH FULL
);

INSERT INTO venues (name, postal_code, country_code)
VALUES ('Crystal Ballroom', '97206', 'us');

SELECT v.venue_id, v.name, c.name
FROM venues AS v INNER JOIN cities AS c
    ON v.postal_code=c.postal_code AND v.country_code=c.country_code;

INSERT INTO venues (name, postal_code, country_code)
VALUES ('Voodoo Doughnut', '97206', 'us') RETURNING venue_id;

CREATE TABLE events (
    event_id SERIAL PRIMARY KEY,
    title varchar(255),
    starts timestamp,
    ends timestamp,
    venue_id int,
    FOREIGN KEY ( venue_id)
        REFERENCES venues ( venue_id )
);

INSERT INTO events (title, starts, ends, venue_id)
VALUES ('Fight Club', '2018-02-15 17:30:00', '2018-02-15 19:30:00', 2) RETURNING event_id;

INSERT INTO events (title, starts, ends)
VALUES ('April Fools Day', '2018-04-01 00:00:00', '2018-04-01 23:59:00') RETURNING event_id;

INSERT INTO events (title, starts, ends)
VALUES ('Christmas Day', '2018-12-25 00:00:00', '2018-12-25 23:59:00') RETURNING event_id;

UPDATE events
SET starts = '2018-12-25 00:00:00'
WHERE title = 'Christmas Day';

SELECT e.title, v.name
FROM events AS e JOIN venues AS v
    ON e.venue_id = v.venue_id;

SELECT e.title, v.name
FROM events AS e LEFT JOIN venues AS v
    ON e.venue_id = v.venue_id;

SELECT e.title, v.name
FROM events AS e FULL JOIN venues AS v
    ON e.venue_id = v.venue_id;    

SELECT * FROM events WHERE starts >='2018-04-01';

CREATE INDEX events_title
    ON events USING hash(title);

CREATE INDEX events_starts
    ON events USING btree (starts);

SELECT * FROM pg_class WHERE relname LIKE 'events%' or relname LIKE 'countries%' or relname LIKE 'cities%' or relname LIKE 'venues%';

SELECT co.country_name, e.title 
FROM events e JOIN venues v 
    ON e.venue_id = v.venue_id
    JOIN cities c
    ON v.postal_code = c.postal_code AND v.country_code = c.country_code
    JOIN countries co
    ON co.country_code = c.country_code;

ALTER TABLE venues
    ADD active boolean DEFAULT true;

-- DAY 2