-- Name & gender of the 10 actors with internal database ID numbers>=2990.
create view Q1 as
select givennames,gender
from Actors
where ID >= 2990
limit 10
;

-- The 10 male actors with the highest database ID numbers.
create view Q2 as
select givenNames, gender
from Actors
where gender = 'm'
order by ID
limit 10
;

-- The ID of the movie with the highest ID number each year since 2000.
create view Q3 as
select max(ID)
from Movies
where year > 2000
group by year
;

-- BelongsTo(left) joined with Movies
create view Q4 as
select *
from BelongsTo b left outer join Movies m on (b.movie = m.ID)
;

-- Movie title and genre of movies that are either Dramas or War movies
create view Q5 as
select title, genre
from Q4
where genre = 'Drama' or genre = 'War'
;

-- Movie title and year of dramas released after 2005.
create view Q6 as
select DISTINCT title,year
from Q4
where year >= 2005 and genre = 'Drama'
;

--Director given & family name(s), and movies directed (with year) in from 1990-2000
create view Q7 as
select d.givenNames,d.familyName, m.title,m.year
from Directors d join directs ds on (d.ID = ds.director)
                 join Movies m on (ds.movie = m.ID)
where m.year > 1990 and m.year < 2000
;

--Movies (with year) directed by Park Chan-wook.
create view Q8 as
select m.title, m.year
from Movies m join Directs ds on (m.ID = ds.movie)
              join Directors d on (ds.director = d.ID)
where d.familyname = "Park" and d.givenNames = "Chan-wook"
;

-- 2 numbers: how many actors do not have a recorded given name, and how many do not have a recorded family name
create view Q9 as
select *
from (select count(*) from Actors where givenNames IS NULL) 
    join (select count(*) from Actors where familyname IS NULL)
;

-- All attributes of the actors relation where the actor in question has an unknown family name
create view Q10 as
select ID,givenNames, gender 
from Actors
where familyname is NULL
;

-- A list of actor pairs with the same last name, but each pair only appears once (so if actors A and B share a last name C, either A C|B C or B C|A C appears in the output but not both. Report the given and family names as a single attribute.
create view Q11 as
select a1.givenNames||' '||a1.familyname,a2.givenNames||' '||a2.familyname
from Actors a1 left outer join Actors a2 on (a1.familyname = a2.familyname)
where a1.givenNames > a2.givenNames
;

-- All actors with a given name Gary and also display any actors who share a last name with a given that Gary. [HINT: Outer join]
create view Q12 as
select a1.garry,a2.other
from (select givenNames||' '||familyName as garry, familyName from Actors where givenNames = "Gary") a1 -- mis Capital A/a so do not use the same name
    left outer join 
     (select givenNames||' '||familyName as other, familyName from Actors where givenNames != 'Gary') a2
on a1.familyName = a2.familyName
;