DROP TABLE users;

CREATE TABLE users (
   id SERIAL,
   name VARCHAR(128),
   email VARCHAR(128) UNIQUE,
   PRIMARY KEY(id)
);

CREATE TABLE pg4e_debug (
  id SERIAL,
  query VARCHAR(4096),
  result VARCHAR(4096),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(id)
);

SELECT query, result, created_at FROM pg4e_debug;

CREATE TABLE pg4e_result (
  id SERIAL,
  link_id INTEGER UNIQUE,
  score FLOAT,
  title VARCHAR(4096),
  note VARCHAR(4096),
  debug_log VARCHAR(8192),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP
);

SELECT title, note FROM pg4e_result;

CREATE TABLE ages (
   name VARCHAR(128),
   age INTEGER
);

DELETE FROM ages;
INSERT INTO ages (name, age) VALUES ('Klevis', 20);
INSERT INTO ages (name, age) VALUES ('Rubyn', 37);
INSERT INTO ages (name, age) VALUES ('Saffi', 34);
INSERT INTO ages (name, age) VALUES ('Sineidin', 18);

CREATE TABLE automagic (
    id SERIAL,
    name VARCHAR(32) NOT NULL,
    height REAL NOT NULL
);

CREATE TABLE track_raw
(title TEXT, artist TEXT, album TEXT,
count INTEGER, rating INTEGER, len INTEGER);

-- copiando um csv para uma tabela / as colunas do csv devem coincidir com as da tabela
\copy track_raw(title,artist,album,count,rating,len) FROM 'library.csv' WITH DELIMITER ',' CSV;

SELECT title, album FROM track_raw ORDER BY title LIMIT 3;