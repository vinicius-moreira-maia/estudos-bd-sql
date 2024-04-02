-- A TABELA FOI CRIADA E POPULADA VIA PYTHON

-- Criando índice GIN na coluna body
CREATE INDEX messages_gin ON messages USING gin(to_tsvector('english', body));

SELECT to_tsvector('english', body) FROM messages LIMIT 1;

SELECT to_tsquery('english', 'easier');

SELECT id, to_tsquery('english', 'neon') @@ to_tsvector('english', body)
FROM messages LIMIT 10;

SELECT id, to_tsquery('english', 'easier') @@ to_tsvector('english', body)
FROM messages LIMIT 10;

-- criação de nova coluna
ALTER TABLE messages ADD COLUMN sender TEXT;

-- populando a nova coluna com uma substring de todos os headers, usando expressão regular para se extrair apenas o email
UPDATE messages SET sender=substring(headers, '\nFrom: [^\n]*<([^>]*)');

SELECT subject, sender FROM messages
WHERE to_tsquery('english', 'monday') @@ to_tsvector('english', body) LIMIT 10;

-- checando se o índice está sendo usado
-- Seq Scan é ruim
EXPLAIN ANALYZE SELECT subject, sender FROM messages
WHERE to_tsquery('english', 'monday') @@ to_tsvector('english', body);

-- Índice não será usado (pois não foi criado um em espanhol)
EXPLAIN ANALYZE SELECT subject, sender FROM messages
WHERE to_tsquery('spanish', 'monday') @@ to_tsvector('spanish', body);

-- pode-se usar um índice GIST também 
-- os dois fazem basicamente a mesma coisa, apesar das diferenças
DROP INDEX messages_gin;
CREATE INDEX messages_gist ON messages USING gist(to_tsvector('english', body));
DROP INDEX messages_gist;

----------------------------------------

SELECT subject, sender FROM messages
WHERE to_tsquery('english', 'monday') @@ to_tsvector('english', body);

-- Seq Scan
EXPLAIN ANALYZE SELECT subject, sender
FROM messages WHERE to_tsquery('english', 'monday') @@ to_tsvector('english', body);

-- procura as duas palavras, independente da ordem
SELECT id, subject, sender FROM messages
WHERE to_tsquery('english', 'personal & learning') @@ to_tsvector('english', body);

SELECT id, subject, sender FROM messages
WHERE to_tsquery('english', 'learning & personal') @@ to_tsvector('english', body);

-- ambas as palavras, mas em ordem
SELECT id, subject, sender FROM messages
WHERE to_tsquery('english', 'personal <-> learning') @@ to_tsvector('english', body);

SELECT id, subject, sender FROM messages
WHERE to_tsquery('english', 'learning <-> personal') @@ to_tsvector('english', body);

-- não possui as duas, simultaneamente
SELECT id, subject, sender FROM messages
WHERE to_tsquery('english', '! personal & learning') @@ to_tsvector('english', body);

-- ERRO, faltou o operador lógico da expressão de consulta
SELECT id, subject, sender FROM messages
WHERE to_tsquery('english', '(personal learning)') @@ to_tsvector('english', body);

-- plainto_tsquery() "deixa passar" a ausência do operador lógico da expressão 
SELECT id, subject, sender FROM messages
WHERE plainto_tsquery('english', '(personal learning)') @@ to_tsvector('english', body);

SELECT id, subject, sender FROM messages
WHERE to_tsquery('english', 'I <-> think') @@ to_tsvector('english', body);

-- phraseto_tsquery() assume que o que é passado já possui uma ordem 
SELECT id, subject, sender FROM messages
WHERE phraseto_tsquery('english', 'I think') @@ to_tsvector('english', body);

SELECT id, subject, sender FROM messages
WHERE to_tsquery('english', '! personal & learning') @@ to_tsvector('english', body);

-- websearch_to_tsquery (PostgreSQL > 11)
-- permite usar uma sintaxe específica para buscas online, só que no Postgres
-- o '-' significa que 'personal' não pode estar presente no resultado
SELECT id, subject, sender FROM messages
WHERE websearch_to_tsquery('english', '-personal learning') @@ to_tsvector('english', body)
LIMIT 10;

------------------------------------------

-- rankeamento de resultados mais relevantes
-- Google!

-- ts_rank é uma função do próprio Postgres, que recebe
-- 2 parâmetros: ts_vector, ts_query.
-- A função avalia a correspondência da ts_query em 
-- relação ao ts_vector, e atribui um ranking 
-- de relevância a esta correspondência.

-- Levando em consideração a ordem de execução de um SELECT,
-- o WHERE é executado em segundo momento (depois do FROM), 
-- para que a consulta com o rankeamento seja feita em cima
-- dos dados em que há correspondência de fato.

-- a parte da cláusula WHERE é a parte custosa, e não o rankeamento (ordem de execução do select)
-- faz-se necessário o uso de um índice

-- o DESC vai exibir do mais ao menos relevante

SELECT id, subject, sender,
  ts_rank(to_tsvector('english', body), to_tsquery('english', 'personal & learning')) as ts_rank
FROM messages
WHERE to_tsquery('english', 'personal & learning') @@ to_tsvector('english', body)
ORDER BY ts_rank DESC;

-- ts_rank_cd é apenas um outro algoritmo de rankeamento, mas é meio que a mesma coisa

SELECT id, subject, sender,
  ts_rank_cd(to_tsvector('english', body), to_tsquery('english', 'personal & learning')) as ts_rank
FROM messages
WHERE to_tsquery('english', 'personal & learning') @@ to_tsvector('english', body)
ORDER BY ts_rank DESC;

