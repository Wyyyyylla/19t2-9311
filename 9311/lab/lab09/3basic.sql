-- All actors with a given name Gary and also display any actors who share a last name with a given that Gary. [HINT: Outer join]
create view Q12 as
select a1.garry,a2.other
from (select givenNames||' '||familyName as garry, familyName from Actors where givenNames = "Gary") a1 -- mis Capital A/a so do not use the same name
    left outer join 
     (select givenNames||' '||familyName as other, familyName from Actors where givenNames != 'Gary') a2
on a1.familyName = a2.familyName
;