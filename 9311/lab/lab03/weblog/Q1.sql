create view Q1(nacc) as select count(page) from Accesses where accTime = '2005-03-02'::timestamp;

