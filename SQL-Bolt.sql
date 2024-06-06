-- Constraints

-- BETWEEN ... AND ...
-- NOT BETWEEN ... AND ...

-- exercícios
SELECT * FROM movies WHERE year NOT BETWEEN 2000 AND 2010;
SELECT title, year FROM movies WHERE id BETWEEN 1 AND 5;

-- IN() -> checa se o valor está na lista 
-- NOT IN() -> checa se o valor não está na lista

-- = -> case sensitive
-- LIKE -> case insensitive

-- != / <> -> case sensitive
-- NOT LIKE -> case insensitive

-- % e _ -> placeholders para, respectivamente, 0 ou mais e exatamente um caractere (somente para LIKE e NOT LIKE)

-- lembrar que Like é uma operação custosa

-- Há ferramentas melhores que Bancos Relacionais para fazer busca em textos (linguagem natural), apesar de ser possível usar índices invertidos (PG4E)

-- exercícios
SELECT * FROM north_american_cities 
    WHERE longitude < 
        (SELECT longitude 
        FROM north_american_cities 
        WHERE city = 'Chicago') 
    ORDER BY longitude;

SELECT * FROM north_american_cities WHERE country = 'Mexico' ORDER BY population DESC LIMIT 2;

SELECT * FROM north_american_cities WHERE country = 'United States' ORDER BY population DESC LIMIT 2 OFFSET 2;

/*
Inner Join (ou somente Join) -> interseção entre dois conjuntos (tabelas)
Full Join -> junção entre dois conjuntos (tabelas)
Left Join -> tabela da "esquerda"
Right Join -> tabela da "direita"
*/

-- inner join
SELECT * FROM 
movies INNER JOIN boxoffice 
ON movies.id = boxoffice.movie_id ORDER BY rating DESC;

-- left join
SELECT DISTINCT building_name, role FROM buildings LEFT JOIN employees 
ON buildings.building_name = employees.building;

------------------------------------------------------

-- valores nulos
-- nao e boa pratica usar valores nulos em bases de dados
-- e sempre melhor usar valores do tipo da propria coluna como default para nulos (tipo 0 ou "", por exemplo)
-- IS NULL / IS NOT NULL

SELECT name, role FROM employees WHERE building IS NULL;

-- com subconsulta
SELECT building_name FROM buildings WHERE building_name NOT IN 
(SELECT building FROM employees AS e WHERE building IS NOT NULL);

-- com left join
SELECT b.building_name
FROM buildings AS b
LEFT JOIN employees AS e ON b.building_name = e.building
WHERE e.building IS NULL;

-- consultas com expressoes
-- e possivel aplicar expressoes matematicas ou funcoes matematicas / de string / de data em uma consulta (valores de colunas)
-- as funcoes dependem do SGBD que esta sendo usado 
-- e sempre boa pratica usar um alias (AS) quando escrever expressoes em consultas

SELECT m.title, 
(box.domestic_sales + box.international_sales) / 1000000 
AS 'millions of dollars' 
FROM movies AS m JOIN boxoffice AS box
ON m.id = box.movie_id;

SELECT m.title, 
round((box.rating * 100) / 10)
AS 'ratings in percent' 
FROM movies AS m JOIN boxoffice AS box
ON m.id = box.movie_id;

SELECT title, year
FROM movies WHERE year % 2 = 0;

------------------------------------------------------

-- Consultas com valores agregados
-- aplicacao de funcoes ou expressoes em um GRUPO DE LINHAS 

/*
COUNT(*)
COUNT(column) -> conta valores nao nulos (NULL)

MIN(column)
MAX(column)
AVG(column)
SUM(column)
*/

-- GROUP BY agrupa os valores iguais na coluna especificada

-- exercicios
SELECT MAX(years_employed) FROM employees;
SELECT AVG(years_employed), role FROM employees GROUP BY role;
SELECT SUM(years_employed), building FROM employees GROUP BY building;

-- HAVING e uma clausula para ser usada somente com o GROUP BY, ou seja, e uma condicao para valores agregados
-- GROUP BY e HAVING sao usados na mesma coluna

-- exercicios
SELECT COUNT(*) FROM employees WHERE role = 'Artist';
SELECT role, COUNT(*) FROM employees GROUP BY role;
SELECT role, SUM(years_employed) AS total_years FROM employees GROUP BY role HAVING role = 'Engineer';

-- Ordem de execucao das consultas
/*
1 - FROM e JOIN
2 - WHERE
3 - GROUP BY -> so faz sentido usar com funcoes agregadoras
4 - HAVING

1, 2, 3 e 4 fazem com que o conjunto de dados seja localizado e filtrado, apos isso estes dados podem ser selecionados

** Notar que tudo que vem ANTES do FROM, que faz parte do SELECT, é executado depois dos passos acima descritos

5 - SELECT
6 - DISTINCT -> apos a selecao, os valores duplicados para uma determinada coluna serao descartados (coluna marcada com DISTINCT)

7 - ORDER BY
8 - LIMIT / OFFSET

obs.: em muitos sgbd's, os alias so podem ser acessados a partir do ORDER BY
*/

-- exercicios
SELECT 
   director, 
   SUM(domestic_sales) + SUM(international_sales) AS total_sales 
FROM 
   movies AS m
   INNER JOIN 
   boxoffice AS box
   ON
   m.id = box.movie_id
GROUP BY director;

------------------------------------------------------

INSERT INTO movies (title, director, year) VALUES 
('Toy Story 4', 'Zé do Caixão', '2024');

-- inserindo em todas as colunas
INSERT INTO boxoffice VALUES 
(15, 8.7, 340000000, 270000000);

UPDATE movies SET director = 'John Lasseter' WHERE id = 2;
UPDATE movies SET year = 1999 WHERE id = 3;
UPDATE movies SET 
title = 'Toy Story 3',
director = 'Lee Unkrich'
WHERE id = 11;

DELETE FROM movies WHERE year < 2005;
DELETE FROM movies WHERE director = 'Andrew Stanton';

------------------------------------------------------

-- o if no exists é útil para evitar erros
/*
CREATE TABLE IF NOT EXISTS mytable (
    column DataType TableConstraint DEFAULT default_value,
    another_column DataType TableConstraint DEFAULT default_value
);
*/

-- Constraints / Restricoes
-- PRIMARY KEY
-- AUTOINCREMENT (SERIAL no Postgres)
-- UNIQUE
-- NOT NULL
-- CHECK (expressao)
-- FOREIGN KEY
-- (...)

CREATE TABLE IF NOT EXISTS database (
    name TEXT,
    version FLOAT,
    download_count INTEGER
);

------------------------------------------------------

/*
ALTER TABLE mytable
ADD column DataType OptionalTableConstraint 
    DEFAULT default_value;

ALTER TABLE mytable
DROP column_to_be_deleted;

ALTER TABLE mytable
RENAME TO new_table_name;
*/

ALTER TABLE movies
ADD Aspect_ratio FLOAT;

ALTER TABLE movies
ADD Language TEXT DEFAULT 'English';

DROP TABLE movies;
DROP TABLE boxoffice;