-- 1
DELETE FROM Highschooler WHERE grade = 12;

-- 2
-- (ID1, ID2) isso faz com que eu possa checar se o par de atributos não está no conjunto
DELETE FROM Likes 
WHERE (ID1, ID2) NOT IN (SELECT DISTINCT L1.ID1, L1.ID2
                         FROM (SELECT ID1, ID2 
							   FROM Likes) L1,
	                          (SELECT ID2, ID1 
							   FROM Likes) L2
                         WHERE L1.ID1 = L2.ID2 and L1.ID2 = L2.ID1)
AND (ID1, ID2) IN (SELECT * 
				   FROM Friend);
