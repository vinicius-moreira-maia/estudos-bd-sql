CREATE TABLE account (
  id SERIAL,
  email VARCHAR(128) UNIQUE,
  created_at DATE NOT NULL DEFAULT NOW(),
  updated_at DATE NOT NULL DEFAULT NOW(),
  PRIMARY KEY(id)
);

CREATE TABLE post (
  id SERIAL,
  title VARCHAR(128) UNIQUE NOT NULL,
  content VARCHAR(1024), -- será alterado com ALTER
  account_id INTEGER REFERENCES account(id) ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY(id)
);

CREATE TABLE comment (
  id SERIAL,
  content TEXT NOT NULL,
  account_id INTEGER REFERENCES account(id) ON DELETE CASCADE,
  post_id INTEGER REFERENCES post(id) ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY(id)
);

CREATE TABLE fav (
  id SERIAL,
  oops TEXT,
  account_id INTEGER REFERENCES account(id) ON DELETE CASCADE,
  post_id INTEGER REFERENCES post(id) ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(post_id, account_id),
  PRIMARY KEY(id)
);

ALTER TABLE fav DROP COLUMN oops;
ALTER TABLE post ALTER COLUMN content TYPE TEXT;
ALTER TABLE fav ADD COLUMN howmuch INTEGER;

SELECT NOW(), NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'GMT-3';
SELECT * FROM pg_timezone_names WHERE name LIKE '%Brazil%';
SELECT NOW()::DATE, CAST(NOW() AS DATE), CAST(NOW() AS TIME);

SELECT COUNT(abbrev), abbrev FROM pg_timezone_names GROUP BY abbrev;

SELECT COUNT(abbrev) AS ct, abbrev FROM pg_timezone_names
WHERE is_dst = 't' GROUP BY abbrev HAVING COUNT(abbrev) > 1;

SELECT ct, abbrev FROM -- ct é uma coluna da tabela temporária
(
  SELECT COUNT(abbrev) AS ct, abbrev
  FROM pg_timezone_names
  WHERE is_dst = 't' GROUP BY abbrev
) AS zap -- Tabela temporária chamada zap
WHERE ct > 10;

-- isso vai falhar
INSERT INTO fav (post_id, account_id, howmuch)
VALUES (1, 1, 1)
RETURNING *; -- devolve o registro atualizado no mesmo comando

-- como se fosse um try except
INSERT INTO fav (post_id, account_id, howmuch)
VALUES (1, 1, 1)
ON CONFLICT (post_id, account_id) -- "não dê erro no conflito"
DO UPDATE SET howmuch = fav.howmuch + 1 -- faça isso no lugar
RETURNING *;

-- stored procedure para automatizar o processo de atualização da coluna updated_at
-- para que não seja preciso atualizar explicitamente (com NOW()) a cada update

-- função
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$ -- a função será usada como trigger
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- trigger
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON fav
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

CREATE TABLE album (
  id SERIAL,
  title VARCHAR(128) UNIQUE,
  PRIMARY KEY(id)
);

CREATE TABLE track (
    id SERIAL,
    title VARCHAR(128),
    len INTEGER, rating INTEGER, count INTEGER,
    album_id INTEGER REFERENCES album(id) ON DELETE CASCADE,
    UNIQUE(title, album_id),
    PRIMARY KEY(id)
);

DROP TABLE IF EXISTS track_raw;
CREATE TABLE track_raw
  (title TEXT, artist TEXT, album TEXT, album_id INTEGER,
  count INTEGER, rating INTEGER, len INTEGER);

\copy track_raw (title, artist, album, count, rating, len)  from 'library.csv' WITH D
ELIMITER ',' CSV;

-- inserindo na tabela (coluna title) o resultado de um select
INSERT INTO album (title)
SELECT DISTINCT album FROM track_raw;

UPDATE track_raw SET album_id = (SELECT album.id FROM album WHERE album.title = track_raw.album);

INSERT INTO track (title, len, rating, count)
SELECT title, len, rating, count FROM track_raw;

UPDATE track SET album_id = (SELECT album_id FROM track_raw WHERE track_raw.title = track.title);

SELECT track.title, album.title
FROM track
JOIN album ON track.album_id = album.id
ORDER BY track.title LIMIT 3;

DROP TABLE unesco_raw;
CREATE TABLE unesco_raw
    (name TEXT, description TEXT, justification TEXT, year INTEGER,
    longitude FLOAT, latitude FLOAT, area_hectares FLOAT,
    category TEXT, category_id INTEGER, state TEXT, state_id INTEGER,
    region TEXT, region_id INTEGER, iso TEXT, iso_id INTEGER);

CREATE TABLE category (
  id SERIAL,
  name VARCHAR(128) UNIQUE,
  PRIMARY KEY(id)
);

CREATE TABLE state (
  id SERIAL,
  name VARCHAR(128) UNIQUE,
  PRIMARY KEY(id)
);

CREATE TABLE region (
  id SERIAL,
  name VARCHAR(128) UNIQUE,
  PRIMARY KEY(id)
);

CREATE TABLE iso (
  id SERIAL,
  name VARCHAR(128) UNIQUE,
  PRIMARY KEY(id)
);

\copy unesco_raw(name,description,justification,year,longitude,latitude,area_hectares,category,state,region,iso) FROM 'whc-sites-2018-small.csv' WITH DELIMITER ',' CSV HEADER;

INSERT INTO category (name)
SELECT DISTINCT category FROM unesco_raw;

INSERT INTO state (name)
SELECT DISTINCT state FROM unesco_raw;

INSERT INTO region (name)
SELECT DISTINCT region FROM unesco_raw;

INSERT INTO iso (name)
SELECT DISTINCT iso FROM unesco_raw;

UPDATE unesco_raw SET category_id = (SELECT id FROM category WHERE unesco_raw.category = category.name);
UPDATE unesco_raw SET state_id = (SELECT id FROM state WHERE unesco_raw.state = state.name);
UPDATE unesco_raw SET region_id = (SELECT id FROM region WHERE unesco_raw.region = region.name);
UPDATE unesco_raw SET iso_id = (SELECT id FROM iso WHERE unesco_raw.iso = iso.name);

CREATE TABLE unesco AS
SELECT
name, description, justification, year,
longitude, latitude, area_hectares,
category_id, state_id,
region_id, iso_id
FROM unesco_raw;

DROP TABLE album CASCADE;
CREATE TABLE album (
    id SERIAL,
    title VARCHAR(128) UNIQUE,
    PRIMARY KEY(id)
);

DROP TABLE track CASCADE;
CREATE TABLE track (
    id SERIAL,
    title TEXT,
    artist TEXT,
    album TEXT,
    album_id INTEGER REFERENCES album(id) ON DELETE CASCADE,
    count INTEGER,
    rating INTEGER,
    len INTEGER,
    PRIMARY KEY(id)
);

DROP TABLE artist CASCADE;
CREATE TABLE artist (
    id SERIAL,
    name VARCHAR(128) UNIQUE,
    PRIMARY KEY(id)
);

DROP TABLE tracktoartist CASCADE;
CREATE TABLE tracktoartist (
    id SERIAL,
    track VARCHAR(128),
    track_id INTEGER REFERENCES track(id) ON DELETE CASCADE,
    artist VARCHAR(128),
    artist_id INTEGER REFERENCES artist(id) ON DELETE CASCADE,
    PRIMARY KEY(id)
);

\copy track(title,artist,album,count,rating,len) FROM 'library.csv' WITH DELIMITER ',' CSV;

INSERT INTO album (title) SELECT DISTINCT album FROM track;
INSERT INTO artist (name) SELECT DISTINCT artist FROM track;

UPDATE track SET album_id = (SELECT album.id FROM album WHERE album.title = track.album);

INSERT INTO tracktoartist (track, artist)
SELECT DISTINCT title, artist FROM track;

UPDATE tracktoartist SET track_id =
(SELECT track.id FROM track
WHERE tracktoartist.track = track.title);

UPDATE tracktoartist SET artist_id =
(SELECT artist.id FROM artist
WHERE tracktoartist.artist = artist.name);

ALTER TABLE track DROP COLUMN album;
ALTER TABLE track DROP COLUMN artist;

ALTER TABLE tracktoartist DROP COLUMN track;
ALTER TABLE tracktoartist DROP COLUMN artist;

SELECT track.title, album.title, artist.name
FROM track
JOIN album ON track.album_id = album.id
JOIN tracktoartist ON track.id = tracktoartist.track_id
JOIN artist ON tracktoartist.artist_id = artist.id
ORDER BY track.title
LIMIT 3;

