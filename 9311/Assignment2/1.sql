create or replace view Q8terms2(id,year,sess,lastend,thisstart,thisend,nextstart) as
select id,year,sess,lag(ending,1) over(order by ending),
		starting,ending,
		lead(starting,1) over(order by starting)
from terms;

create type termtype as (
	id		integer,
	year	CourseYearType,
	sess	char(2),
	lastend	date,
	thisstart	date,
	thisend		date,
	nextstart	date
);

create or replace function Q8(_day date) returns text 
as $$
declare
	term termtype;
	id integer;
begin
	for term in
				select * from Q8terms2
	loop
		--change sess
		if ((term.thisstart-term.lastend) >= 7) then
				term.thisstart := term.thisstart - 7;
				term.lastend := term.thisstart - 1;
		else
				term.thisstart := term.lastend + 1; 
		end if;	
		if ((term.nextstart - term.thisend) >= 7) then
				term.nextstart := term.nextstart - 7;
				term.thisend := term.nextstart - 1;
		else
				term.nextstart := term.thisend + 1;
		end if;
		-- check date
		if(_day < '1950-01-31' or _day > '2012-10-28') then
				id := NULL; 
		else
				if (_day >= term.thisstart and _day <= term.thisend) then
						id := term.id; 
				end if;
		end if;
	end loop;
	return Q3(id);
end;
$$ language plpgsql
;
