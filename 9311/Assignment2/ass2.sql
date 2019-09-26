-- COMP9311 Assignment 2
-- Written by Yang Wang z5220836, August 2019

-- Q1: get details of the current Heads of Schools

create or replace view Q1(name, school, starting)
as
select p.name, o.longname, a.starting
from People p 
        full outer join Staff s on (p.id = s.id) 
        full outer join Affiliation a on (s.id = a.staff)
        full outer join Staffroles r on (a.role = r.id)       
        full outer join OrgUnits o on (o.id = a.orgunit)
        full outer join OrgUnitTypes t on (o.utype = t.id)
where   t.name = 'School' 
    and a.isprimary = 'true'
    and a.ending is null
    and r.description like 'Head of School'
;

-- Q2: longest-serving and most-recent current Heads of Schools

create or replace view Q2_1
as
select starting,
case 
when starting = (select max(starting) from Q1) then 'Most recent'
when starting = (select min(starting) from Q1) then 'Longest serving'
END
from Q1
;

create or replace view Q2(status, name, school, starting)
as
select q.case, q1.name, q1.school, q1.starting
from Q1 q1 join Q2_1 q on (q1.starting = q.starting)
where q.case is not null 
;

-- Q3: term names

create or replace function
	Q3(integer) returns text
as
$$
    select
    case when id is not null then right(lower(year::text||sess),4)
    end
    from terms
    where id = $1
$$ language sql;

-- Q4: percentage of international students, S1 and S2, 2005..2011

-- All students view
create or replace view Q4stu(id,syear,sess,type)
as
select t.id,t.year,t.sess,s.stype
from Students s
    full outer join Programenrolments p on (s.id = p.student)
    full outer join Terms t on (p.term = t.id)
where t.year >= 2005 and t.sess like 'S%' and s.stype is not null
;

-- International students view
create or replace view Q4intl(id, syear, sess, num)
as
select id,syear,sess,count(type)
from q4stu
where type = 'intl'
group by id,syear,sess
;

create or replace view Q4(term,percent)
as
select Q3(s.id),round(i.num::numeric/count(s.id)::numeric,2)
from Q4stu s left outer join Q4intl i on (s.id = i.id)
group by s.id,i.num
order by Q3(s.id)
;

-- Q5: total FTE students per term since 2005

-- students' e.stu, c.term, e.course, s.uoc
create or replace view Q5stu(stu,term,courseid,stuuoc) 
as
select e.student, c.term, e.course, s.uoc
from courses c 
    join courseenrolments e on (c.id = e.course)
    join subjects s on (c.subject = s.id)
;

-- whole uoc for a term
create or replace view Q5termuocs(term, sumuoc)
as 
select q.term,sum(q.stuuoc) 
from q5stu q join Terms t on (q.term = t.id)
where t.year >= 2000 and t.year <= 2010 and t.sess like 'S_'
group by q.term;
;

-- the number of students
create or replace view Q5nstus(term, stunum)
as
select u.term,count(distinct(s.stu))
from Q5stu s
    join Q5termuocs u on (s.term = u.term)
group by u.term
;

create or replace view Q5(term, nstudes, fte)
as
select Q3(t.id), n.stunum, round(u.sumuoc::numeric / 24,1)
from Q5termuocs u
    join Q5nstus n on (u.term = n.term)
    join Terms t on (u.term = t.id)
;

-- Q6: subjects with > 30 course offerings and no staff recorded

-- times of this course has been offered
create or replace view Q6offertimes(code,offertimes)       
as                                                                              
select s.code,count(s.firstoffer)
from courses c                                                                      
    join subjects s on (c.subject = s.id)
group by s.code
;

-- the courses that have staffs
create or replace view Q6staffcourse(code)
as
select sub.code
from coursestaff s 
    join courses c on (s.course = c.id) 
    join subjects sub on (c.subject = sub.id)
where s.staff is not null
;

create or replace view Q6(subject, nOfferings)
as
select distinct concat(s.code,' ',s.name), ot.offertimes
from Q6offertimes ot
    full outer join subjects s on (ot.code = s.code)
    full outer join courses c on (s.id = c.subject)
where ot.offertimes > 30 and not exists (select * from Q6staffcourse sc where sc.code = ot.code)
order by ot.offertimes desc
;

-- Q7:  which rooms have a given facility

create or replace function
	Q7(text) returns setof FacilityRecord
as 
$$
    select r.longname as room, f.description as facility
    from rooms r 
        join roomfacilities rf on (r.id = rf.room)
        join facilities f on (rf.facility = f.id)
    where lower(f.description) like lower(concat('%',$1,'%'))
$$ language sql
;

-- Q8: semester containing a particular day

-- new session view
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
		-- change sess
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

-- Q9: transcript with variations

create type externalType as (
    code        text,
    vtype       variationType,
    intequiv    integer,
    extequiv    integer,
    institution LongName,
    uoc         integer 
);

create or replace function q9code(_id integer) returns char(8)
as
$$
        select code
        from subjects
        where id = _id
$$ language sql;

create or replace function
	q9(_sid integer) returns setof TranscriptRecord
as $$
declare
        rec TranscriptRecord;
        ex externalType;
        UOCtotal integer := 0;
        UOCpassed integer := 0;
        wsum integer := 0;
        wam integer := 0;
        x integer;
begin
        select s.id into x
        from   Students s join People p on (s.id = p.id)
        where  s.id = _sid or p.unswid = _sid;
        if (not found) then
                raise EXCEPTION 'Invalid student %',_sid;
        end if;
        for rec in
                select su.code, substr(t.year::text,3,2)||lower(t.sess),
                        su.name, e.mark, e.grade, su.uoc
                from   CourseEnrolments e join Students s on (e.student = s.id)
                        join People p on (s.id = p.id)
                        join Courses c on (e.course = c.id)
                        join Subjects su on (c.subject = su.id)
                        join Terms t on (c.term = t.id)
                where  s.id = _sid or p.unswid = _sid
                order by t.starting,su.code
        loop
                if (rec.grade = 'SY') then
                        UOCpassed := UOCpassed + rec.uoc;
                elsif (rec.mark is not null) then
                        if (rec.grade in ('PT','PC','PS','CR','DN','HD')) then
                                -- only counts towards creditted UOC
                                -- if they passed the course
                                UOCpassed := UOCpassed + rec.uoc;
                        end if;
                        -- we count fails towards the WAM calculation
                        UOCtotal := UOCtotal + rec.uoc;
                        -- weighted sum based on mark and uoc for course
                        wsum := wsum + (rec.mark * rec.uoc);
                end if;
                return next rec;
        end loop;

        for ex in
                select sb.code, v.vtype, v.intequiv, v.extequiv, e.institution,sb.uoc
                from Variations v join Students s on (v.student = s.id)
                    full outer join People p on (s.id = p.id)
                    full outer join Subjects sb on (v.subject = sb.id)
                    full outer join Externalsubjects e on (v.extequiv = e.id)
                where (s.id = _sid or p.unswid = _sid) 
        loop
                if(ex.vtype = 'advstanding') then
                        UOCpassed := UOCpassed + ex.uoc;
                        rec := (ex.code,null,'Advanced standing, based on ...',null,null,ex.uoc);
                elsif (ex.vtype = 'substitution') then
                        rec := (ex.code,null,'Substitution, based on ...',null,null,null);
                elsif (ex.vtype = 'exemption') then
                        rec := (ex.code,null,'Exemption, based on ...',null,null,null);
                end if;
                return next rec;
                
                if(ex.intequiv is not null) then
                        --select s.code from Variations v full outer join subjects s on (v.subject = s.id) where s.id = v.intequiv);
                        rec := (null,null,concat('studying ',q9code(ex.intequiv),' at UNSW'),null,null,null);
                elsif(ex.extequiv is not null) then
                        rec := (null,null,concat('study at ',ex.institution),null,null,null);
                end if;
                return next rec;
        end loop;
        
        if (UOCtotal = 0) then
                rec := (null,null,'No WAM available',null,null,null);
        else
                wam := wsum / UOCtotal; 
                rec := (null,null,'Overall WAM',wam,null,UOCpassed);
        end if;
        -- append the last record containing the WAM
        return next rec;
        return;
end;
$$ language plpgsql
;