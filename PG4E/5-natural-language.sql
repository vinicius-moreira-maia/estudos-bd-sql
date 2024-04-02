-- strings, arrays e linhas
SELECT string_to_array('Hello world', ' ');
SELECT unnest(string_to_array('Hello world', ' '));

-- Criando algo parecido com o GIN
CREATE TABLE docs (id SERIAL, doc TEXT, PRIMARY KEY(id));

-- tabela com os campos de texto em si
INSERT INTO docs (doc) VALUES
   ('This is SQL and Python and other fun teaching stuff'),
   ('More people should learn SQL from UMSI'),
   ('UMSI also teaches Python and also SQL');

CREATE TABLE docs_gin (
   keyword TEXT,
   doc_id INTEGER REFERENCES docs(id) ON DELETE CASCADE
);

-- Quebrando os documentos em palavras com os id's da coluna doc da tabela docs, separados
-- em linhas (somente visualização)
-- s(keyword) é uma tabela temporaria, cuja unica coluna é keyword
SELECT id, s.keyword AS keyword
FROM docs AS D, unnest(string_to_array(D.doc, ' ')) s(keyword)
ORDER BY id;

-- consultando sem linhas duplicadas
SELECT DISTINCT id, s.keyword AS keyword
FROM docs AS D, unnest(string_to_array(D.doc, ' ')) s(keyword)
ORDER BY id;

-- adicionando o índice invertido na tabela de fato (docs_gin)
-- GIN = Generalized Inverted Indexes
-- lembrando que essa é a sintaxe para inserir dados em uma tabela a partir de uma consulta
INSERT INTO docs_gin (doc_id, keyword)
SELECT DISTINCT id, s.keyword AS keyword
FROM docs AS D, unnest(string_to_array(D.doc, ' ')) s(keyword)
ORDER BY id;

-- ÍNDICE PRONTO !!

-- Consultas no índice criado

-- Achando as keywods iguais à 'UMSI'
-- essa consulta já me informa todos os documentos que possuem 'UMSI'
SELECT DISTINCT keyword, doc_id FROM docs_gin AS G
WHERE G.keyword = 'UMSI';

-- Achando os documentos (com os id's) que contém 'UMSI'
SELECT DISTINCT id, doc FROM docs AS D
JOIN docs_gin AS G ON D.id = G.doc_id
WHERE G.keyword = 'UMSI';

-- Achando os documentos que contém alguma palavra do conjunto, usando IN
SELECT DISTINCT doc FROM docs AS D
JOIN docs_gin AS G ON D.id = G.doc_id
WHERE G.keyword IN ('fun', 'people');

-- Achando os documentos que contém qualquer palavra do array, usando a função ANY
SELECT DISTINCT doc FROM docs AS D
JOIN docs_gin AS G ON D.id = G.doc_id
WHERE G.keyword = ANY(string_to_array('I want to learn', ' '));

-- Achando os documentos que contém qualquer palavra do array, usando a função ANY
SELECT DISTINCT id, doc FROM docs AS D
JOIN docs_gin AS G ON D.id = G.doc_id
WHERE G.keyword = ANY(string_to_array('Search for Lemons and Neons', ' '));

-------------------------------------

-- GIN (Generalized Inverse Indexes) "pensa" nas colunas contendo arrays
-- O GIN precisa saber qual tipo de dado dos arrays
-- array_ops significa array de strings
-- todo WHERE usará operadores de arrays (como o <@)

DROP INDEX gin1;

CREATE INDEX gin1 ON docs USING gin(string_to_array(doc, ' ') array_ops);

INSERT INTO docs (doc) VALUES
('This is SQL and Python and other fun teaching stuff'),
('More people should learn SQL from UMSI'),
('UMSI also teaches Python and also SQL');

-- Inserindo muitas linhas para que o índice seja usado, pois se forem poucas pode ser que o Postgres
-- não o use
INSERT INTO docs (doc) SELECT 'Neon ' || generate_series(10000,20000);

-- <@ significa 'se está contito em'
-- a parte mais importante dessa consulta é o WHERE (onde existe mais custo)
-- a expressão 'string_to_array(doc, ' ')' deve ser exatamente igual a da criação do índice
-- nesse WHERE eu transformo todo texto em um array de palavras
SELECT id, doc FROM docs WHERE '{learn}' <@ string_to_array(doc, ' ');
EXPLAIN SELECT id, doc FROM docs WHERE '{learn}' <@ string_to_array(doc, ' ');


---------- LINGUAGEM NATURAL
CREATE TABLE docs (id SERIAL, doc TEXT, PRIMARY KEY(id));
INSERT INTO docs (doc) VALUES
('This is SQL and Python and other fun teaching stuff'),
('More people should learn SQL from UMSI'),
('UMSI also teaches Python and also SQL');
SELECT * FROM docs;

-- criando a consulta para formar a tabela de mapeamento
-- com todas as palavras em caixa baixa
-- com DISTINCT para remover linhas repetidas
SELECT DISTINCT id, s.keyword AS keyword
FROM docs AS D, unnest(string_to_array(lower(D.doc), ' ')) s(keyword)
ORDER BY id;

-- tabela de mapeamento
CREATE TABLE docs_gin (
  keyword TEXT,
  doc_id INTEGER REFERENCES docs(id) ON DELETE CASCADE
);

-- tabela de "stop words"
CREATE TABLE stop_words (word TEXT unique);
INSERT INTO stop_words (word) VALUES ('is'), ('this'), ('and');

-- consulta que exclui as stop words da tabela de mapeamento
SELECT DISTINCT id, s.keyword AS keyword
FROM docs AS D, unnest(string_to_array(lower(D.doc), ' ')) s(keyword)
WHERE s.keyword NOT IN (SELECT word FROM stop_words)
ORDER BY id;

-- 'unnest' transforma o array gerado em uma tabela, cujo alias é 's', e cuja coluna é 'keyword'
-- de acordo com a ordem de execução de um SELECT (que começa no FROM),
-- é possível selecionar s.keyword no SELECT
-- colocando a lista de palavras sem as stop words na tabela de mapeamento
INSERT INTO docs_gin (doc_id, keyword)
SELECT DISTINCT id, s.keyword AS keyword
FROM docs AS D, unnest(string_to_array(lower(D.doc), ' ')) s(keyword)
WHERE s.keyword NOT IN (SELECT word FROM stop_words)
ORDER BY id;

-- CONSULTAS --
-- consulta de uma palavra
SELECT DISTINCT doc FROM docs AS D
JOIN docs_gin AS G ON D.id = G.doc_id
WHERE G.keyword = lower('UMSI');

-- consulta de várias palavras
SELECT DISTINCT doc FROM docs AS D
JOIN docs_gin AS G ON D.id = G.doc_id
WHERE G.keyword =
  ANY(string_to_array(lower('Meet fun people'), ' '));

-- consultando uma "stop word" como se ela estivesse lá
SELECT DISTINCT doc FROM docs AS D
JOIN docs_gin AS G ON D.id = G.doc_id
WHERE G.keyword = lower('and');


-- Adicionando stems (derivações) -> diminui o índice

-- mapeamento palavra -> derivada
CREATE TABLE docs_stem (word TEXT, stem TEXT);
INSERT INTO docs_stem (word, stem) VALUES
('teaching', 'teach'), ('teaches', 'teach');

-- movendo a extração inicial para uma subconsulta
SELECT id, keyword FROM (
SELECT DISTINCT id, s.keyword AS keyword
FROM docs AS D, unnest(string_to_array(lower(D.doc), ' ')) s(keyword)
) AS X;

-- adicionando as stems como uma terceira coluna
SELECT id, keyword, stem FROM (
SELECT DISTINCT id, s.keyword AS keyword
FROM docs AS D, unnest(string_to_array(lower(D.doc), ' ')) s(keyword)
) AS K
LEFT JOIN docs_stem AS S ON K.keyword = S.word;

-- se a stem estiver presente, use-a
-- juntando a coluna keyword com a coluna stem
-- AS awesome -> alias para a coluna derivada
-- CASE WHEN stem IS NOT NULL THEN stem ELSE keyword END AS awesome -> uma condição para os valores dessa
-- coluna =)))))
SELECT id,
CASE WHEN stem IS NOT NULL THEN stem ELSE keyword END AS awesome,
keyword, stem
FROM (
SELECT DISTINCT id, lower(s.keyword) AS keyword
FROM docs AS D, unnest(string_to_array(D.doc, ' ')) s(keyword)
) AS K
LEFT JOIN docs_stem AS S ON K.keyword = S.word;

-- COALESCE é outra forma de criar a consulta anterior (da coluna derivada)

-- coalesce retorna o primeiro não nulo em uma lista
SELECT COALESCE(NULL, NULL, 'umsi');
SELECT COALESCE('umsi', NULL, 'SQL');

-- se a stem estiver presente, use-a no lugar da keyword
SELECT id, COALESCE(stem, keyword) AS keyword
FROM (
SELECT DISTINCT id, s.keyword AS keyword
FROM docs AS D, unnest(string_to_array(lower(D.doc), ' ')) s(keyword)
) AS K
LEFT JOIN docs_stem AS S ON K.keyword = S.word;

DELETE FROM docs_gin;

-- inserindo somente as stems
INSERT INTO docs_gin (doc_id, keyword)
SELECT id, COALESCE(stem, keyword)
FROM (
  SELECT DISTINCT id, s.keyword AS keyword
  FROM docs AS D, unnest(string_to_array(lower(D.doc), ' ')) s(keyword)
) AS K
LEFT JOIN docs_stem AS S ON K.keyword = S.word;

-- stop words e stems
DELETE FROM docs_gin;

INSERT INTO docs_gin (doc_id, keyword)
SELECT id, COALESCE(stem, keyword)
FROM (
  SELECT DISTINCT id, s.keyword AS keyword
  FROM docs AS D, unnest(string_to_array(lower(D.doc), ' ')) s(keyword)
  WHERE s.keyword NOT IN (SELECT word FROM stop_words)
) AS K
LEFT JOIN docs_stem AS S ON K.keyword = S.word;

-- algumas consultas
-- a função coalesce está recebendo dois parâmetros, um select e o resultado de lower('SQL')
SELECT COALESCE((SELECT stem FROM docs_stem WHERE word=lower('SQL')), lower('SQL'));

SELECT DISTINCT id, doc FROM docs AS D
JOIN docs_gin AS G ON D.id = G.doc_id
WHERE G.keyword = COALESCE((SELECT stem FROM docs_stem WHERE word=lower('SQL')), lower('SQL'));

SELECT COALESCE((SELECT stem FROM docs_stem WHERE word=lower('teaching')), lower('teaching'));

SELECT DISTINCT id, doc FROM docs AS D
JOIN docs_gin AS G ON D.id = G.doc_id
WHERE G.keyword = COALESCE((SELECT stem FROM docs_stem WHERE word=lower('teaching')), lower('teaching'));

-- Funções de Busca de Texto

-- tsvector é um array que guarda informações sobre um documento de texto/string
-- guarda palavras derivadas (stemmed), filtro de stop words e posições
SELECT to_tsvector('english', 'UMSI also teaches Python and also SQL');
SELECT to_tsvector('portuguese', 'Lavarei suas roupas que ficarão muito bem lavadas depois da lavagem.');

-- tsquery é um array de palavras em caixa baixa, stemmed words com stop words
-- já removidas mais operadores lógicos (&, !, |)
SELECT to_tsquery('english', 'teaching');
SELECT to_tsquery('english', 'teaches');
SELECT to_tsquery('english', 'and');
SELECT to_tsquery('english', 'SQL');
SELECT to_tsquery('english', 'Teach | teaches | teaching | and | the | if');

-- retorna as keywords (palavras que conferem significado à sentença)
SELECT plainto_tsquery('english', 'SQL Python');
SELECT plainto_tsquery('english', 'Teach teaches teaching and the if');

-- ordem das palavras na sentença
SELECT phraseto_tsquery('english', 'SQL Python');

-- @@ verifica se há correspondência entre a consulta textual (tsquery) e o vetor textual (tsvector)
SELECT to_tsquery('english', 'teaching') @@
to_tsvector('english', 'UMSI also teaches Python and also SQL');


CREATE TABLE docs (id SERIAL, doc TEXT, PRIMARY KEY(id));

-- criando um índice invertido na coluna 'doc' utilizando to_tsvector
CREATE INDEX gin1 ON docs USING gin(to_tsvector('english', doc));

INSERT INTO docs (doc) VALUES
('This is SQL and Python and other fun teaching stuff'),
('More people should learn SQL from UMSI'),
('UMSI also teaches Python and also SQL');

INSERT INTO docs (doc) SELECT 'Neon ' || generate_series(10000,20000);

-- procurando algum registro com a palavra learn
SELECT id, doc FROM docs WHERE
    to_tsquery('english', 'learn') @@ to_tsvector('english', doc);

-- procurando registros que tenham 'teach' ou palavras derivadas
SELECT id, doc FROM docs WHERE
    to_tsquery('english', 'teach') @@ to_tsvector('english', doc);

EXPLAIN SELECT id, doc FROM docs WHERE
    to_tsquery('english', 'learn') @@ to_tsvector('english', doc);




-- retornando as funções/operações disponíveis para cada tipo de índice
SELECT version();
SELECT am.amname AS index_method, opc.opcname AS opclass_name
    FROM pg_am am, pg_opclass opc
    WHERE opc.opcmethod = am.oid
    ORDER BY index_method, opclass_name;

-- retorna os idiomas disponíveis (na instalação default)
-- já contém tabelas de stems e de stop words de cada idioma, além de outras coisas
SELECT cfgname FROM pg_ts_config;


