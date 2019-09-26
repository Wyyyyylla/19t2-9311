-- Schema for simple company database

create table Employees (
	tfn         char(11) check (tfn ~ '\d{3}-\d{3}-\d{3}'),
	givenName   varchar(30) not null,
	familyName  varchar(30),
	hoursPweek  float check (hoursPweek > 0 AND hoursPweek < 168),
	primary key(tfn)
);

create table Departments (
	id          char(3) check (id ~ '\d{3}'),
	"name"        varchar(100),
	manager     char(11) unique,
	primary key(id),
	foreign key(manager) references Employees(tfn)
);

create table DeptMissions (
	department  char(3),
	keyword     varchar(20) not null,
	primary key(department, keyword),
	foreign key (department) references Departments(id)
);

create table WorksFor (
	employee    char(11),
	department  char(3),
	"percentage"  float check ("percentage" > 0 AND "percentage" <= 100) not null,
	foreign key (employee) references Employees(tfn),
	foreign key (department) references Departments(id),
	primary key(employee, department)
);
