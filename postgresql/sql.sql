CREATE TABLE countries (
    country_code char(2) PRIMARY KEY,
    country_name text UNIQUE
);

INSERT INTO countries (country_code, country_name)
VALUES ('us', 'United States'), ('mx', 'Mexico'), ('au', 'Australia'),
     ('gb', 'United Kingdom'), ('de', 'Germany'), ('ll', 'Loompaland');

INSERT INTO countries
VALUES ('uk','United Kingdom');

SELECT *
FROM countries;



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
VALUES ('April Fools Day', '2018-04-01 00:00:00', '2018-04-01 23:59:00'),
('Christmas Day', '2018-12-25 00:00:00', '2018-12-25 23:59:00') RETURNING event_id;


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

INSERT INTO countries
VALUES ('th','Thailand');

INSERT INTO cities
VALUES ('Bangkok', '10400', 'th');

INSERT INTO venues (name, postal_code, country_code)
VALUES ('Phayathai', '10400', 'th');

INSERT INTO events (title, starts, ends, venue_id)
VALUES ('Wedding', '2018-02-26 21:00:00', '2018-02-26 23:00:00', (
    SELECT venue_id
    FROM venues
    WHERE name = 'Voodoo Doughnut'
    )
), ('Dinner with Mom', '2018-02-26 18:00:00', '2018-02-26 20:30:00', (
    SELECT venue_id
    FROM venues
    WHERE name = 'Phayathai'
    )
), ('Valentine''s Day', '2018-02-14 00:00:00', '2018-02-14 23:59:00', NULL
);

SELECT count(title)
FROM events
WHERE title LIKE '%Day%';

SELECT min(starts), max(ends)
FROM events e INNER JOIN venues v
    ON e.venue_id = v.venue_id
WHERE v.name = 'Voodoo Doughnut';

-- GROUP BY
SELECT venue_id, count(*)
FROM events
GROUP BY venue_id;

SELECT venue_id
FROM events
GROUP BY venue_id
HAVING count(*) >= 2 AND venue_id IS NOT NULL;

SELECT venue_id FROM events GROUP BY venue_id;
SELECT DISTINCT venue_id FROM events;

-- Window Functions
SELECT title, venue_id, count(*)
FROM events
GROUP BY venue_id;

SELECT title, count(*) OVER (PARTITION BY venue_id) FROM events;

-- TRANSACTIONS
BEGIN TRANSACTION;
    DELETE FROM events;
ROLLBACK;
SELECT * FROM events;

-- STORED PROCEDURES
SELECT add_event('House Party', '2018-05-03 23:00', '2018-05-04 02:00', 'Run''s House', '97206', 'us');
-- PULL THE TRIGGERS
CREATE TABLE logs (
    event_id integer,
    old_title varchar(255),
    old_starts timestamp,
    old_ends timestamp,
    logged_at timestamp DEFAULT current_timestamp
);

ALTER TABLE logs
    RENAME old_tiltle TO old_title;

UPDATE events
SET ends='2018-05-04 01:00:00'
WHERE title='House Party';

SELECT event_id, old_title, old_ends, logged_at
FROM logs;

-- Views
CREATE VIEW holidays AS
    SELECT event_id AS holiday_id, title AS name, starts AS date
    FROM events
    WHERE title LIKE '%Day%' AND venue_id IS NULL;

SELECT name, to_char(date, 'Month DD, YYYY') AS date
FROM holidays
WHERE date <= '2018-04-01';

ALTER TABLE events
ADD colors text ARRAY;

CREATE OR REPLACE VIEW holidays AS
    SELECT event_id AS holiday_id, title AS name, starts AS date, colors
    FROM events
    WHERE title LIKE '%Day%' AND venue_id IS NULL;

UPDATE holidays SET colors = '{"red", "green"}' where name = 'Christmas Day';

EXPLAIN VERBOSE
    SELECT * FROM holidays;

SELECT extract(year from starts) as year,
    extract(month from starts) as month, count(*)
FROM events
GROUP BY year, month
ORDER BY year, month;

CREATE TEMPORARY TABLE month_count(month INT);
INSERT INTO month_count VALUES (1),(2),(3),(4),(5),
(6),(7),(8),(9),(10),(11),(12);

CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT * 
FROM crosstab(
    'SELECT extract(year from starts) as year,
        extract(month from starts) as month, count(*)
    FROM events
    GROUP BY year, month
    ORDER BY year, month',
    'SELECT * FROM month_count'
);

SELECT * FROM crosstab(
'SELECT extract(year from starts) as year,
extract(month from starts) as month, count(*) FROM events
GROUP BY year, month
ORDER BY year, month',
  'SELECT * FROM month_count'
) AS (
year int,
jan int, feb int, mar int, apr int, may int, jun int, jul int, aug int, sep int, oct int, nov int, dec int
) ORDER BY YEAR;

-- day 3
CREATE EXTENSION IF NOT EXISTS tablefunc;
CREATE EXTENSION IF NOT EXISTS dict_xsyn;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS cube;

docker exec -it postgresql_db_1 psql -h localhost -U postgres -d 7dbs -c "SELECT '1'::cube;"

create_movies.sql
CREATE TABLE genres (
    name text UNIQUE,
    position integer
);
CREATE TABLE movies (
    movie_id SERIAL PRIMARY KEY,
    title text,
    genre cube
);
CREATE TABLE actors (
    actor_id SERIAL PRIMARY KEY,
    name text
);
CREATE TABLE movies_actors (
    movie_id integer REFERENCES movies NOT NULL,
    actor_id integer REFERENCES actors NOT NULL,
    UNIQUE (movie_id, actor_id)
);
CREATE INDEX movies_actors_movie_id ON movies_actors (movie_id);
CREATE INDEX movies_actors_actor_id ON movies_actors (actor_id);
CREATE INDEX movies_genres_cube ON movies USING gist (genre);

SELECT title FROM movies WHERE title ILIKE 'stardust%';
SELECT title FROM movies WHERE title ILIKE 'stardust_%';

SELECT COUNT(*) FROM movies WHERE title !~* '^the.*';

CREATE INDEX movies_title_pattern ON movies (lower(title) text_pattern_ops);
SELECT levenshtein('bat', 'fads');

SELECT levenshtein('bat', 'fad') fad,
    levenshtein('bat', 'fat') fat,
    levenshtein('bat', 'bat') bat;

SELECT movie_id, title FROM movies
WHERE levenshtein(lower(title), lower('a hard day nght')) <= 3;

SELECT show_trgm('Avatar');

CREATE INDEX movies_title_trigram ON movies
USING gist (title gist_trgm_ops);

SELECT title
FROM movies
WHERE title % 'Avatre';

SELECT title
FROM movies
WHERE title @@ 'night & day';

SELECT title
FROM movies
WHERE to_tsvector(title) @@ to_tsquery('english', 'night & day');

SELECT to_tsvector('A Hard Day''s Night'),
    to_tsquery('english', 'night & day');

SELECT to_tsvector('Six Days Seven Nights'),
    to_tsquery('english', 'night & day');

SELECT to_tsvector('Long Day''s Journey Into Night'),
    to_tsquery('english', 'night & day');

SELECT *
FROM movies
WHERE title @@ to_tsquery('english', 'a');

cat 'pg_config --sharedir' usr/share/postgresql/13/tsearch_data/english.stop

SELECT to_tsvector('english', 'A Hard Day''s Night');
SELECT to_tsvector('simple', 'A Hard Day''s Night');

\dF
\dFd

SELECT ts_lexize('english_stem', 'Day''s');

SELECT to_tsvector('german', 'was machst du gerade?');

EXPLAIN
SELECT *
FROM movies
WHERE title @@ 'night & day';

CREATE INDEX movies_title_searchable ON movies
USING gin(to_tsvector('english', title));

EXPLAIN
SELECT *
FROM movies
WHERE to_tsvector('english', title) @@ 'night & day';

SELECT * FROM actors
WHERE name = 'Broos Wils';

SELECT *
FROM actors
WHERE name % 'Broos Wils';

SELECT title
FROM movies NATURAL JOIN movies_actors NATURAL JOIN actors
WHERE metaphone(name, 6) = metaphone('Broos Wils', 6);

SELECT name, dmetaphone(name), dmetaphone_alt(name),
    metaphone(name, 8), soundex(name)
FROM actors;

SELECT * FROM actors
WHERE metaphone(name, 8) % metaphone('Robin Williams', 8)
ORDER BY levenshtein(lower('Robin Williams'), lower(name));

SELECT *
FROM actors
WHERE dmetaphone(name) % dmetaphone('Ron');

SELECT name,
cube_ur_coord('(0,7,0,0,0,0,0,0,0,7,0,0,0,0,10,0,0,0)', position) as score
FROM genres g
WHERE cube_ur_coord('(0,7,0,0,0,0,0,0,0,7,0,0,0,0,10,0,0,0)', position) > 0;

SELECT m.movie_id, m.title
FROM movies m, (SELECT genre, title FROM movies WHERE title = 'Mad Max') s WHERE cube_enlarge(s.genre, 5, 18) @> m.genre AND s.title <> m.title
ORDER BY cube_distance(m.genre, s.genre)
LIMIT 10;
