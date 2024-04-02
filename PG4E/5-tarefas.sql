--------------------- TAREFA 1
CREATE TABLE docs01 (id SERIAL, doc TEXT, PRIMARY KEY(id));

CREATE TABLE invert01 (
  keyword TEXT,
  doc_id INTEGER REFERENCES docs01(id) ON DELETE CASCADE
);

INSERT INTO docs01 (doc) VALUES
('The word counting program above directly uses all of these patterns'),
('What could possibly go wrong'),
('As we saw in our earliest conversations with Python we must communicate'),
('very precisely when we write Python code The smallest deviation or'),
('mistake will cause Python to give up looking at your program'),
('Beginning programmers often take the fact that Python leaves no room for'),
('errors as evidence that Python is mean hateful and cruel While Python'),
('seems to like everyone else Python knows them personally and holds a'),
('grudge against them Because of this grudge Python takes our perfectly'),
('written programs and rejects them as unfit just to torment us');

INSERT INTO invert01 (doc_id, keyword)
SELECT DISTINCT id, s.keyword AS keyword
FROM docs01 AS D, unnest(string_to_array(LOWER(D.doc), ' ')) s(keyword)
ORDER BY id;

SELECT keyword, doc_id FROM invert01 ORDER BY keyword, doc_id LIMIT 10;



--------------------- TAREFA 2
CREATE TABLE docs02 (id SERIAL, doc TEXT, PRIMARY KEY(id));

CREATE TABLE invert02 (
  keyword TEXT,
  doc_id INTEGER REFERENCES docs02(id) ON DELETE CASCADE
);

INSERT INTO docs02 (doc) VALUES
('The word counting program above directly uses all of these patterns'),
('What could possibly go wrong'),
('As we saw in our earliest conversations with Python we must communicate'),
('very precisely when we write Python code The smallest deviation or'),
('mistake will cause Python to give up looking at your program'),
('Beginning programmers often take the fact that Python leaves no room for'),
('errors as evidence that Python is mean hateful and cruel While Python'),
('seems to like everyone else Python knows them personally and holds a'),
('grudge against them Because of this grudge Python takes our perfectly'),
('written programs and rejects them as unfit just to torment us');

CREATE TABLE stop_words (word TEXT unique);

INSERT INTO stop_words (word) VALUES
('i'), ('a'), ('about'), ('an'), ('are'), ('as'), ('at'), ('be'),
('by'), ('com'), ('for'), ('from'), ('how'), ('in'), ('is'), ('it'), ('of'),
('on'), ('or'), ('that'), ('the'), ('this'), ('to'), ('was'), ('what'),
('when'), ('where'), ('who'), ('will'), ('with');

-- a coluna s.keyword é criada temporariamente durante a execução da consulta
-- para representar as palavras individuais extraídas da coluna doc.
INSERT INTO invert02 (doc_id, keyword)
SELECT DISTINCT id, s.keyword AS keyword
FROM docs02 AS D, unnest(string_to_array(lower(D.doc), ' ')) s(keyword)
WHERE s.keyword NOT IN (SELECT word FROM stop_words)
ORDER BY id;

SELECT keyword, doc_id FROM invert02 ORDER BY keyword, doc_id LIMIT 10;



--------------------- TAREFA 3
CREATE TABLE docs03 (id SERIAL, doc TEXT, PRIMARY KEY(id));

DROP INDEX array03;
CREATE INDEX array03 ON docs03 USING gin(string_to_array(lower(doc), ' ') array_ops);

INSERT INTO docs03 (doc) VALUES
('The word counting program above directly uses all of these patterns'),
('What could possibly go wrong'),
('As we saw in our earliest conversations with Python we must communicate'),
('very precisely when we write Python code The smallest deviation or'),
('mistake will cause Python to give up looking at your program'),
('Beginning programmers often take the fact that Python leaves no room for'),
('errors as evidence that Python is mean hateful and cruel While Python'),
('seems to like everyone else Python knows them personally and holds a'),
('grudge against them Because of this grudge Python takes our perfectly'),
('written programs and rejects them as unfit just to torment us');

INSERT INTO docs03 (doc) SELECT 'Neon ' || generate_series(10000,20000);

SELECT id, doc FROM docs03 WHERE '{conversations}' <@ string_to_array(lower(doc), ' ');
EXPLAIN SELECT id, doc FROM docs03 WHERE '{conversations}' <@ string_to_array(lower(doc), ' ');



--------------------- TAREFA 4
CREATE TABLE docs03 (id SERIAL, doc TEXT, PRIMARY KEY(id));

CREATE INDEX fulltext03 ON docs03 USING gin(to_tsvector('english', doc));

INSERT INTO docs03 (doc) VALUES
('The word counting program above directly uses all of these patterns'),
('What could possibly go wrong'),
('As we saw in our earliest conversations with Python we must communicate'),
('very precisely when we write Python code The smallest deviation or'),
('mistake will cause Python to give up looking at your program'),
('Beginning programmers often take the fact that Python leaves no room for'),
('errors as evidence that Python is mean hateful and cruel While Python'),
('seems to like everyone else Python knows them personally and holds a'),
('grudge against them Because of this grudge Python takes our perfectly'),
('written programs and rejects them as unfit just to torment us');

-- transforma-se a coluna doc em tsvector, depois usa-se tsquery para realizar a consulta
SELECT id, doc FROM docs03 WHERE to_tsquery('english', 'conversations') @@ to_tsvector('english', doc);
EXPLAIN SELECT id, doc FROM docs03 WHERE to_tsquery('english', 'conversations') @@ to_tsvector('english', doc);
