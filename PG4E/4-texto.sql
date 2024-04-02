-- GERANDO TEXTO

-- Funções no Postgres são funções como em qualquer outra linguagem de programação

-- random() retorna reais entre 0 e 1.0
-- trunc retorna a parte inteira
SELECT random(), random(), trunc(random()*100);

-- repeat() repete a string horizontalmente (5 vezes no caso)
SELECT repeat('Neon ', 5);

-- generate_series() gera linhas com os números do intervalo passado como argumentos 
SELECT generate_series(1, 5);

-- || é para concatenar strings
SELECT 'https://sql4e.com/neon' ||
        trunc(random() * 1000000) ||
        repeat('Lemon', 5) ||
        generate_series(1, 5);


-----------------------------------------------------


-- FUNÇÕES DE TEXTO

CREATE TABLE textfun (
   content TEXT
);

-- criando índice na coluna
CREATE INDEX textfun_b ON textfun (content);

-- Índices ocupam bastante espaço na memória
SELECT pg_relation_size('textfun'), pg_indexes_size('textfun');

-- alimentando a tabela
-- o generate_series gera uma tabela temporária de uma coluna, por isso posso usar o SELECT logo após o INSERT em um mesmo comando para preencher a tabela (que possui uma só coluna e tipo compatível)
INSERT INTO textfun (content)
SELECT (CASE WHEN (random() < 0.5)
        THEN 'https://www.pg4e.com/Lemon'
        ELSE 'https://www.pg4e.com/Orange'
        END) || generate_series(100000, 200000);

SELECT content FROM textfun LIMIT 5;

-- o índice ocupa mais espaço que os dados em si, nesse caso
SELECT pg_relation_size('textfun'), pg_indexes_size('textfun');

SELECT content FROM textfun WHERE content LIKE '%150000%';
SELECT upper(content) FROM textfun WHERE content LIKE '%150000%';
SELECT lower(content) FROM textfun WHERE content LIKE '%150000%';
SELECT right(content, 4) FROM textfun WHERE content LIKE '%150000%';
SELECT left(content, 4) FROM textfun WHERE content LIKE '%150000%';

-- Performance em Índices B-Tree
-- O foco é criar Consultas com performance "Index Only Scan" -> tempo constante
-- "Seq Scan" não é algo bom! (Não usa índice!) -> tempo aumenta se os dados aumentam

explain analyze SELECT content FROM textfun WHERE content LIKE 'racing%';
explain analyze SELECT content FROM textfun WHERE content LIKE '%racing%';

explain analyze SELECT content FROM textfun
WHERE content
IN (SELECT content FROM textfun WHERE content LIKE '%150000%');

explain analyze select content from textfun where content LIKE 'ht%';

-- select ascii('H'), chr(44);
show server_encoding;


-----------------------------------------------------


-- Regular Expressions
-- O PostgreSQL usa a RegEx POSIX

CREATE TABLE em (id serial, primary key(id), email text);

INSERT INTO em (email) VALUES ('csev@umich.edu');
INSERT INTO em (email) VALUES ('coleen@umich.edu');
INSERT INTO em (email) VALUES ('sally@uiuc.edu');
INSERT INTO em (email) VALUES ('ted79@umuc.edu');
INSERT INTO em (email) VALUES ('glenn1@apple.com');
INSERT INTO em (email) VALUES ('nbody@apple.com');

-- ~ Significa match, e o que está entre aspas simples é a RegEx
-- umich em qualquer canto da string
SELECT email FROM em WHERE email ~'umich';

-- ~'^c' letra c no começo da linha
SELECT email FROM em WHERE email ~'^c';

-- edu no final da linha
SELECT email FROM em WHERE email ~'edu$';

-- g ou n ou t no começo da linha / colchete é um só caractere
SELECT email FROM em WHERE email ~ '^[gnt]';

-- se contém um número
SELECT email FROM em WHERE email ~ '[0-9]';

-- se contém 2 números seguidos
SELECT email FROM em WHERE email ~'[0-9][0-9]';

-- aplicando duas regex para filtrar resultados de um resultado filtrado
SELECT substring(email FROM '[0-9]+') FROM em WHERE email ~'[0-9]';

-- aqui : "qualquer caractere uma ou mais vezes, arroba literal e grupo de captura no fim"
-- ou seja, quando uso () eu especifico o que quero encontrar
SELECT substring(email FROM '.+@(.*)$') FROM em;
SELECT DISTINCT substring(email FROM '.+@(.*)$') FROM em;

-- substring() retorna o primeiro match apenas
SELECT substring(email FROM '.+@(.*)$'),
COUNT(substring(email FROM '.+@(.*)$'))
FROM em GROUP BY substring(email FROM '.+@(.*)$');

CREATE TABLE tw (id serial, primary key(id), tweet text);
INSERT INTO tw (tweet) VALUES ('This is #SQL and #FUN stuff');
INSERT INTO tw (tweet) VALUES ('More people should learn #SQL from #UMSI');
INSERT INTO tw (tweet) VALUES ('#UMSI also teaches #PYTHON');

-- regexp_matches() retorna um array com todos os matches
SELECT DISTINCT regexp_matches(tweet,'#([A-Za-z0-9_]+)', 'g') FROM tw;


-----------------------------------------------------


-- Exercício

CREATE TABLE keyvalue (
  id SERIAL,
  key VARCHAR(128) UNIQUE,
  value VARCHAR(128) UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY(id)
);

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
BEFORE UPDATE ON keyvalue
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

-- aspas simples !!!
INSERT INTO bigtext (content)
SELECT 'This is record number ' || generate_series(100000, 200000)
|| ' of quite a few text records.';






