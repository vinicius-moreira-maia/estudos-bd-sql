-- 01 
-- Find the names of all students who are friends with someone named Gabriel.
SELECT name
FROM Highschooler
WHERE id IN (SELECT DISTINCT F.ID1
			 FROM Highschooler H JOIN Friend F
			 ON H.ID = F.ID2 
			 WHERE H.name = 'Gabriel');

-- 02 
-- For every student who likes someone 2 or more grades younger than themselves, return that student's name and grade, and the name and grade of the student they like.
SELECT R1.name, R1.grade, H.name, H.grade 
FROM (SELECT *
	  FROM Highschooler H JOIN Likes L
	  ON H.ID = L.ID1
	  ORDER BY H.ID) R1 JOIN Highschooler H
ON R1.ID2 = H.ID
WHERE R1.grade - H.grade >= 2;

-- 03 
-- For every pair of students who both like each other, return the name and grade of both students. Include each pair only once, with the two names in alphabetical order.
-- O join para dar nomes aos envolvidos na tabela Likes
SELECT R1.ID, R1.name, R1.grade, H.ID, H.name, H.grade 
FROM (SELECT *
	  FROM Highschooler H JOIN Likes L
	  ON H.ID = L.ID1
	  ORDER BY H.ID) R1 
JOIN Highschooler H
ON R1.ID2 = H.ID;

-- Essa consulta filtra os ids que tem relacionamento recíproco na tabela Likes
-- e remove 1 dos casos, podendo ser tanto onde o valor da coluna for menor que o da coluna seguinte, na mesma linha,
-- ou ao contrário, no caso optei pela primeira situação.
SELECT DISTINCT L1.ID1, L1.ID2
FROM (SELECT ID1, ID2 FROM Likes) L1,
	 (SELECT ID2, ID1 FROM Likes) L2
WHERE L1.ID1 = L2.ID2 and L1.ID2 = L2.ID1
and L1.ID1 < L1.ID2 -- -> esse teste foi removido da consulta final
;

-- Consulta final
SELECT R1.name, R1.grade, H.name, H.grade 
FROM (SELECT *
	  FROM Highschooler H JOIN (SELECT DISTINCT L1.ID1, L1.ID2
                                FROM (SELECT ID1, ID2 FROM Likes) L1,
	                                 (SELECT ID2, ID1 FROM Likes) L2
                                WHERE L1.ID1 = L2.ID2 and L1.ID2 = L2.ID1) L
	  ON H.ID = L.ID1) R1 
JOIN Highschooler H
ON R1.ID2 = H.ID
WHERE R1.name < H.name -- -> aqui está o novo teste
ORDER BY R1.name, H.name;

-- 04 
-- Find all students who do not appear in the Likes table (as a student who likes or is liked) and return their names and grades. Sort by grade, then by name within each grade.
-- Todos os ids da tabela Likes
SELECT DISTINCT *
FROM (
    SELECT ID1 FROM Likes
    UNION
    SELECT ID2 FROM Likes
);

-- Consulta final
SELECT name, grade
FROM Highschooler 
WHERE ID NOT IN (SELECT DISTINCT *
				 FROM (SELECT ID1 FROM Likes
    				   UNION
    				   SELECT ID2 FROM Likes));

-- 05 
-- For every situation where student A likes student B, but we have no information about whom B likes (that is, B does not appear as an ID1 in the Likes table), return A and B's names and grades.
SELECT H1.name, H1.grade, H2.name, H2.grade
FROM Highschooler H1 JOIN Likes L JOIN Highschooler H2
ON H1.ID = L.ID1 and L.ID2 = H2.ID
WHERE L.ID2 NOT IN (SELECT ID1
					FROM Likes);

-- 06 
-- Find names and grades of students who only have friends in the same grade. Return the result sorted by grade, then by name within each grade.
SELECT H1.name, H1.grade
FROM Highschooler H1 JOIN Friend F JOIN Highschooler H2
ON H1.ID = F.ID1 AND H2.ID = F.ID2
GROUP BY H1.ID
HAVING H1.grade = AVG(H2.grade) and MIN(H2.grade) = MAX(H2.grade) 
ORDER BY H1.grade, H1.name;

-- 07 
-- For each student A who likes a student B where the two are not friends, find if they have a friend C in common (who can introduce them!). For all such trios, return the name and grade of A, B, and C.

-- 3 colunas com IDs numéricos precisam do join com 3 instâncias da mesma tabela
SELECT H1.name, H1.grade, H3.name, H3.grade, H2.name, H2.grade
FROM (SELECT ABC.a AS a, ABC.b AS b, ABC.c AS c
      FROM (-- A|B join B|C -> A|B|C
		    SELECT F1.ID1 AS a, F1.ID2 AS b, F2.ID2 AS c 
            FROM Friend F1 JOIN Friend F2
            ON F1.ID2 = F2.ID1) ABC
      where (ABC.a, ABC.c) IN (SELECT * FROM Likes) -- checa se o par A|C está em Likes
      AND (ABC.a, ABC.c) NOT IN (SELECT * FROM Friend) -- checa se o par A|C não está em Friend
     ) F	
JOIN
Highschooler H1
JOIN
Highschooler H2
JOIN
Highschooler H3
ON F.a = H1.ID AND F.b = H2.ID AND F.c = H3.ID;

-- 08 
-- Find the difference between the number of students in the school and the number of different first names.
-- pra subconsulta funcionar no select ela deve retornar apenas 1 registro
SELECT
(SELECT COUNT(*)
FROM Highschooler)
-
(SELECT COUNT(DISTINCT name)
FROM Highschooler);

-- 09 
-- Find the name and grade of all students who are liked by more than one other student.
SELECT R.name, R.grade
FROM (SELECT COUNT(*) AS count, R1.ID, R1.name, R1.grade 
      FROM (SELECT *
	        FROM Highschooler H JOIN (SELECT ID2 FROM Likes) L
	        ON H.ID = L.ID2
	        ORDER BY H.ID) R1 JOIN Highschooler H
      ON R1.ID2 = H.ID
	  GROUP BY R1.name
      HAVING count >= 2) R;
