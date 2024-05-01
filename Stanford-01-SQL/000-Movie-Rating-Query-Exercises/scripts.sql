-- 01
-- Find the titles of all movies directed by Steven Spielberg.
SELECT title
FROM Movie
WHERE director = 'Steven Spielberg';

-- 02
-- Find all years that have a movie that received a rating of 4 or 5, and sort them in increasing order.
SELECT DISTINCT year
FROM Movie M, Rating R
WHERE M.mID = R.mID and (stars = 4 or stars = 5)
ORDER BY year;

-- 03
-- Find the titles of all movies that have no ratings.
SELECT title 
FROM Movie
WHERE mID NOT IN (SELECT mID 
				  FROM Rating);

-- 04
-- Some reviewers didn't provide a date with their rating. Find the names of all reviewers who have ratings with a NULL value for the date.
SELECT DISTINCT name
FROM Reviewer Rev, Rating Rat
WHERE Rev.rID = Rat.rID and ratingDate IS NULL;

-- 05
-- Write a query to return the ratings data in a more readable format: reviewer name, movie title, stars, and ratingDate. Also, sort the data, first by reviewer name, then by movie title, and lastly by number of stars.
SELECT DISTINCT Rev.name as name, M.title as title, Rat.stars as stars, Rat.ratingDate as ratingDate
FROM Reviewer Rev, Rating Rat, Movie M
WHERE Rev.rID = Rat.rID and Rat.mID = M.mID
ORDER By Rev.name, M.title, Rat.stars;

-- 06
-- For all cases where the same reviewer rated the same movie twice and gave it a higher rating the second time, return the reviewer's name and the title of the movie.
SELECT recente.name, recente.title
FROM
    (
     -- selecionando os mais recentes de cada
     SELECT temp2.name, temp2.title, temp2.stars, MAX(temp2.ratingDate)
     FROM
	    (
         -- todo filme que foi avaliado 2 vezes
         SELECT name, title, COUNT(*) AS n_linhas
	     FROM Rating Rat, Movie M, Reviewer Rev
	     WHERE M.mID = Rat.mID and Rat.rID = Rev.rID
	     GROUP BY name, title
	     HAVING n_linhas = 2) temp1,
	
	    (
         -- todo filme
         SELECT name, title, stars, ratingDate
	     FROM Rating Rat, Movie M, Reviewer Rev
	     WHERE M.mID = Rat.mID and Rat.rID = Rev.rID) temp2

     WHERE temp2.name = temp1.name and temp2.title = temp1.title
     GROUP BY temp2.name, temp2.title) recente,
 
    (
     -- selecionando os mais antigos de cada
     SELECT temp2.name, temp2.title, temp2.stars, MIN(temp2.ratingDate)
     FROM
	    (
         -- todo filme que foi avaliado 2 vezes
         SELECT name, title, COUNT(*) AS n_linhas
	     FROM Rating Rat, Movie M, Reviewer Rev
	     WHERE M.mID = Rat.mID and Rat.rID = Rev.rID
	     GROUP BY name, title
	     HAVING n_linhas = 2) temp1,
	
	    (
         -- todo filme
         SELECT name, title, stars, ratingDate
	     FROM Rating Rat, Movie M, Reviewer Rev
	     WHERE M.mID = Rat.mID and Rat.rID = Rev.rID) temp2

     WHERE temp2.name = temp1.name and temp2.title = temp1.title
     GROUP BY temp2.name, temp2.title) antigo
  
-- precisa ser recente E ter melhor avaliação  
WHERE recente.stars > antigo.stars; 

-- 07
-- For each movie that has at least one rating, find the highest number of stars that movie received. Return the movie title and number of stars. Sort by movie title.
SELECT DISTINCT M.title, MAX(R.stars)
FROM Rating R JOIN Movie M
ON M.mID = R.mID
GROUP BY M.title
ORDER BY M.title;

-- 08
-- For each movie, return the title and the 'rating spread', that is, the difference between highest and lowest ratings given to that movie. Sort by rating spread from highest to lowest, then by movie title.
SELECT DISTINCT M.title, MAX(stars) - MIN(stars) as x
FROM Rating R JOIN Movie M
ON M.mID = R.mID
GROUP BY M.title
ORDER BY x DESC, M.title;

-- 09
-- Find the difference between the average rating of movies released before 1980 and the average rating of movies released after 1980. (Make sure to calculate the average rating for each movie, then the average of those averages for movies before 1980 and movies after. Don't just calculate the overall average rating before and after 1980.)
SELECT AVG(before80.avg_stars) - AVG(after80.avg_stars) 
FROM (SELECT title, AVG(stars) AS avg_stars, year
      FROM Rating R, Movie M
      WHERE M.mID = R.mID and M.year < 1980
      GROUP BY title) before80,
     (SELECT title, AVG(stars) AS avg_stars, year
      FROM Rating R, Movie M
      WHERE M.mID = R.mID and M.year > 1980
      GROUP BY title) after80;