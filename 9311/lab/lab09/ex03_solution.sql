-- 1
CREATE VIEW q1 AS
SELECT givenNames, gender FROM Actors WHERE id >= 2990;

-- 2
CREATE VIEW q2 AS
SELECT givenNames, gender FROM Actors WHERE gender = 'm' ORDER BY id LIMIT 10;

-- 3
CREATE VIEW q3 AS
SELECT max(id) AS maxID FROM Movies WHERE year > 2000 GROUP BY year;

-- 4
CREATE VIEW q4 AS
SELECT * FROM BelongsTo LEFT JOIN Movies WHERE BelongsTo.movie = Movies.id;

-- 5
CREATE VIEW q5 AS
SELECT Movies.title, BelongsTo.genre FROM BelongsTo LEFT JOIN Movies WHERE BelongsTo.movie = Movies.id AND (BelongsTo.genre = 'Drama' OR BelongsTo.genre = 'War');

-- 6
CREATE VIEW q6 AS
SELECT Movies.title, Movies.year FROM BelongsTo LEFT JOIN Movies WHERE BelongsTo.movie = Movies.id AND genre = 'Drama' AND year >= 2005;

-- 7
CREATE VIEW q7 AS
SELECT Directors.givenNames, Directors.familyName, Movies.title, Movies.year FROM Directs LEFT JOIN Directors LEFT JOIN Movies WHERE Directs.director = Directors.id AND Directs.movie = Movies.id AND year < 2000 AND year > 1990;

-- 8
CREATE VIEW q8 AS
SELECT Movies.title, Movies.year FROM Directs LEFT JOIN Directors LEFT JOIN Movies WHERE Directs.director = Directors.id AND Directs.movie = Movies.id AND Directors.givenNames = 'Chan-wook' AND Directors.familyName = 'Park';

-- 9
CREATE VIEW q9 AS
SELECT * FROM (SELECT count(*) AS null_given FROM actors WHERE givenNames IS NULL) JOIN (SELECT count(*) AS null_family FROM Actors WHERE familyName IS NULL);

-- 10
CREATE VIEW q10 AS
SELECT * FROM Actors WHERE familyName IS NULL;

-- 11
CREATE VIEW q11 AS
SELECT
        a.givenNames || ' ' || a.familyName AS Actor1,
        b.givenNames || ' ' || a.familyName AS Actor2
FROM
        Actors a
        LEFT JOIN Actors b
WHERE
        a.familyName = b.familyName
        AND a.givenNames > b.givenNames
;

CREATE VIEW q12 AS
SELECT
        garys.name, others.match
FROM
        (SELECT givenNames || ' ' || familyName AS name, familyName from Actors where givenNames = 'Gary') garys
        LEFT OUTER JOIN (SELECT givenNames || ' ' || familyName AS match, familyName from Actors WHERE givenNames != 'Gary') others
ON
        garys.familyName = others.familyName
;
