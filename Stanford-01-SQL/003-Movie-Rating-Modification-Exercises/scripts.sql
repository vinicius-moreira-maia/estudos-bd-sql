-- 1
INSERT INTO Reviewer VALUES(209, 'Roger Ebert');

-- 2
UPDATE Movie
SET year = year + 25
WHERE mID IN (
    SELECT M.mID
    FROM Movie M
    JOIN Rating R ON M.mID = R.mID
    GROUP BY M.mID
    HAVING AVG(R.stars) >= 4
);

-- 3
DELETE FROM Rating
WHERE mID IN (
    SELECT M.mID
    FROM (SELECT * 
          FROM Movie 
          WHERE year < 1970 OR year > 2000) M
          JOIN Rating R ON M.mID = R.mID
) AND stars < 4;