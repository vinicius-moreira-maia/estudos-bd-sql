CREATE TABLE comentarios (id SERIAL, texto TEXT, PRIMARY KEY(id));

INSERT INTO comentarios (texto) VALUES
('Isto é Python e SQL e outros ensinamentos bastante divertidos de serem estudados!'),
('Mais pessoas deviam estudar Python e SQL de forma autodidata.'),
('Eu sei que autodidatismo não é pra todo mundo'),
('Ensinamos uns aos outros.');

-- preenchendo a tabela com muitas linhas, para que o índice GIN possa ser usado
-- concatenando a palavra Governança de Dados com os números do intervalo 10000, 20000
-- generate_series cria uma tabela temporária (10000 registros, no caso)
INSERT INTO comentarios (texto) SELECT 'Governança de Dados ' || generate_series(10000,20000);

-- criando um índice invertido na coluna 'texto' utilizando to_tsvector
-- to_tsvector retorna um "vetor textual", que armazena as palavras de um campo de texto na forma de vetor de palavras
-- essas palavras são todas minúsculas
-- derivações são armazenadas (ensinar, ensinarei, ensinando -> ensin)
-- palavras que não dão sentido à sentença são descartadas (e, de, para ...)
CREATE INDEX indice_gin ON comentarios USING gin(to_tsvector('portuguese', texto));

-- procurando algum registro com a palavra estudar
-- to_tsquery é uma "consulta textual", onde a palavra passada é convertida para o formato adequado para comparação com o to_tsvector
-- @@ avalia a correspondência entre a consulta e o vetor
SELECT * FROM comentarios WHERE
    to_tsquery('portuguese', 'estudar') @@ to_tsvector('portuguese', texto);

SELECT * FROM comentarios WHERE
    to_tsquery('portuguese', 'autodidata') @@ to_tsvector('portuguese', texto);

-- verificando se o índice está sendo usado na consulta
-- Seq Scan não é bom sinal
EXPLAIN SELECT * FROM comentarios WHERE
    to_tsquery('portuguese', 'autodidata') @@ to_tsvector('portuguese', texto);

---------------------------------------------------

-- versão do Postgres
SELECT version();

-- retornando os módulos de operações disnponíveis para cada índice
SELECT am.amname AS index_method, opc.opcname AS opclass_name
    FROM pg_am am, pg_opclass opc
    WHERE opc.opcmethod = am.oid
    ORDER BY index_method, opclass_name;

-- retorna os idiomas disponíveis (na instalação default)
SELECT cfgname FROM pg_ts_config;