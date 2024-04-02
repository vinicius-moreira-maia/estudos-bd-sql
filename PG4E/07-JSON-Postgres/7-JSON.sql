DROP TABLE IF EXISTS jtrack CASCADE;

CREATE TABLE IF NOT EXISTS jtrack (id SERIAL, body JSONB);

-- importando como se fosse csv, mas não é csv
-- basicamente estou dizendo para ignorar as aspas e para não criar delimitador algum, pois cada "dicionário" é uma linha completa
\copy jtrack (body) FROM 'library.jstxt' WITH CSV QUOTE E'\x01' DELIMITER E'\x02';

SELECT * FROM jtrack LIMIT 5;

-- retornando o tipo da coluna
SELECT pg_typeof(body) FROM jtrack LIMIT 1;

-- selecionando o campo name do json (como texto, pois ->>)
SELECT body->>'name' FROM jtrack LIMIT 5;

-- tudo na coluna body é jsonb, incluindo campos específicos
-- é preciso fazer conversões de tipo quando for necessário

-- '->' acessa o campo (sem conversão PARA TEXTO)
-- '->>' acessa o campo (com conversão PARA TEXTO)

SELECT pg_typeof(body->'name') FROM jtrack LIMIT 1;

-- jsonb, pois :: é executado primeiro (precedência)
SELECT pg_typeof(body->'name'::text) FROM jtrack LIMIT 1;

-- jsonb, pois nesse caso a função executa antes que a conversão
SELECT pg_typeof(body->'name')::text FROM jtrack LIMIT 1;

-- text, pois aqui a conversão é realizada logo após o dado ser acessado
SELECT pg_typeof((body->'name')::text) FROM jtrack LIMIT 1;

-- não é preciso converter quando eu quiser apenas texto, o '->>' já faz isso
SELECT pg_typeof(body->>'name') FROM jtrack LIMIT 1;

-- em números a conversão é especialmente importante, pois o operador '->>' converte o campo para texto
SELECT MAX((body->>'count')::int) FROM jtrack;
SELECT body->>'name' AS name FROM jtrack ORDER BY (body->>'count')::int DESC LIMIT 5;

SELECT pg_typeof(body->'count') FROM jtrack LIMIT 1;
SELECT pg_typeof(body->>'count') FROM jtrack LIMIT 1;

SELECT COUNT(*) FROM jtrack WHERE body->>'name' = 'Summer Nights';

-- @> é o operador de 'contém' do JSON
-- a consulta 'pergunta' se o par chave-valor está contido na coluna
SELECT COUNT(*) FROM jtrack WHERE body @> '{"name": "Summer Nights"}';

-- a conversão para jsonb aqui é redundante
SELECT COUNT(*) FROM jtrack WHERE body @> ('{"name": "Summer Nights"}'::jsonb);

-- concatenando mais um par chave-valor nos registros em que o campo 'count' (como inteiro) for maior que 200
UPDATE jtrack SET body = body || '{"favorite": "yes"}' WHERE (body->'count')::int > 200;

SELECT body FROM jtrack WHERE (body->'count')::int > 160 LIMIT 5;

-- o '?' checa se a chave (campo) está presente no JSON
SELECT COUNT(*) FROM jtrack WHERE body ? 'favorite';

--------------------------------------------------------------------

-- populando a tabela...
INSERT INTO jtrack (body) 
SELECT ('{ "type": "Neon", "series": "24 Hours of Lemons", "number": ' || generate_series(1000,5000) || '}')::jsonb;

-- criando alguns índices
DROP INDEX jtrack_btree;
DROP INDEX jtrack_gin;
DROP INDEX jtrack_gin_path_ops;

CREATE INDEX jtrack_btree ON jtrack USING BTREE ((body->>'name'));
CREATE INDEX jtrack_gin ON jtrack USING gin (body);

-- jsonb_path_ops permite a consulta usando pares de chave-valor com índices
CREATE INDEX jtrack_gin_path_ops ON jtrack USING gin (body jsonb_path_ops);

-- essa aparentemente é a única consulta que não usa índice
-- pois não foi criado um índice específico para o campo artist
EXPLAIN SELECT COUNT(*) FROM jtrack WHERE body->>'artist' = 'Queen';

-- usa índice, pois foi criado um para o campo name
-- lembrando que '=' NÃO é um operador usado com índices GIN, mas em BTREEs
EXPLAIN SELECT COUNT(*) FROM jtrack WHERE body->>'name' = 'Summer Nights';

-- nesse caso o GIN simples será usado, pois somente o GIN em toda a coluna só indexa as chaves dos pares chave-valor
EXPLAIN SELECT COUNT(*) FROM jtrack WHERE body ? 'favorite';

-- em todos esses o índice usado é o terceiro, pois estou usando pares chave-valor na consulta, não somente chaves
EXPLAIN SELECT COUNT(*) FROM jtrack WHERE body @> '{"name": "Summer Nights"}';
EXPLAIN SELECT COUNT(*) FROM jtrack WHERE body @> '{"artist": "Queen"}';
EXPLAIN SELECT COUNT(*) FROM jtrack WHERE body @> '{"name": "Folsom Prison Blues", "artist": "Johnny Cash"}';

-- ERRO -> pois tudo é jsonb
SELECT (body->'count') + 1 FROM jtrack LIMIT 1;

-- convertendo antes
SELECT (body->'count')::int + 1 FROM jtrack LIMIT 1;

SELECT (body->>'count')::int FROM jtrack WHERE body->>'name' = 'Summer Nights';
SELECT ( (body->>'count')::int + 1 ) FROM jtrack WHERE body->>'name' = 'Summer Nights';

-- incrementando um inteiro no JSON
-- conversão para inteiro, depois para texto, depois para jsonb
-- jsonb_set() é uma função utilizada para alterar o valor de um campo JSON
UPDATE jtrack SET body = jsonb_set(body, '{ count }', ((body->>'count')::int + 1 )::text::jsonb )
WHERE body->>'name' = 'Summer Nights';

-- deletando, pois muitos dados e índices
DROP TABLE IF EXISTS jtrack CASCADE;

--------------------------------------------------------------------

