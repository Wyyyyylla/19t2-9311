.open lab10-db

-- Check actors loaded
SELECT * FROM Actors LIMIT 3;
.print

-- Check directors loaded
SELECT * FROM Directors LIMIT 3;
.print

--.quit

-- Check movies loaded
SELECT * FROM Movies LIMIT 3;
.print

-- Create a list of Movies
.output ex02_movie_list.txt
SELECT title FROM movies;

.output

-- Check AppearsIn loaded
--.output
SELECT * FROM AppearsIn LIMIT 3;
.print

-- Check the BelongsTo loaded
SELEcT * FROM BelongsTo LIMIT 3;
.print

-- Check Directs loaded
SELECT * FROM Directs LIMIT 3;
