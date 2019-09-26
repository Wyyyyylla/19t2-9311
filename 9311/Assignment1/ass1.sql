-- Assignment 1 Stage 2
-- Schema for the et.org events/ticketing site
--
-- Written by <<Yang Wang z5220836>>
--
-- Conventions:
-- - all entity table names are plural
-- - most entities have an artifical primary key called "id"
-- - foreign keys are named after the relationship they represent

-- Generally useful domains

create domain URLValue as
	varchar(100) check (value like 'http://%');

create domain EmailValue as
	varchar(100) check (value like '%@%.%');

create domain GenderValue as
	char(1) check (value in ('m','f','n'));

create domain ColourValue as
	char(7) check (value ~ '#[0-9A-Fa-f]{6}');

create domain LocationValue as varchar(40)
	check (value ~ E'^-?\\d+\.\\d+,-?\\d+\.\\d+$');
	-- latitiude and longitude in format used by Google Maps
	-- e.g. '-33.916369,151.23024' (UNSW)

create domain NameValue as varchar(50);

create domain LongNameValue as varchar(100);

-- PLACES: addresses, geographic locations, etc.

create table Places (
	id          serial, -- integer default nextval('some_seq_or_other')
	"name"      LongNameValue not null,
    "address"   text,
    city        NameValue,
    "state"     NameValue,
    country     NameValue not null,
    postalCode  varchar(50) check (postalCode ~ '\d+'), -- postal Code contains digit and larger than 0
    gpsCoords   LocationValue,
    unique ("address", city, "state", postalCode,country),
	primary key (id)
);

-- PEOPLE: information about various kinds of people
-- Users are People who can login to the system
-- Contacts are people about whom we have minimal info
-- Organisers are "entities" who organise Events

create table People (
	id          serial,
	email       EmailValue not null,
    givenNames  NameValue not null,
    familyName  NameValue,
    invitedEvent serial,
    attendedEvent serial,
    contactID   serial not null,
	primary key (id)
);

create table Users (
    id          serial not null,
    gender      GenderValue,
    birthday    date,
    phone       text check (phone ~ '\d+'),
    blog        URLValue,
    showName    LongNameValue not null,
    "password"  text not null,
    website     URLValue,
    billAddID   serial not null,
    homeAddID   serial,
    primary key (id),
    foreign key (id) references People(id),
    foreign key (billAddID) references Places(id),
    foreign key (homeAddID) references Places(id)
);


-- PAGEs: settings for pages in et.org

create table PageColours (
	id          serial,
	"name"      LongNameValue not null,
    isTemplate  boolean default false,
    background  ColourValue,
    links       URLValue,
    boxes       ColourValue,
    borders     ColourValue,
    headtext    ColourValue,
    heading     ColourValue,
    maintext    ColourValue,
	userID      serial,
    primary key (id),
    foreign key (userID) references Users(id)
);

create table Organisers (
	id          serial,
    "name"      LongNameValue not null,
    logo        bytea,
    about       text, -- some descriptive material
    ownedBy     serial not null, -- "front facing" contact for events
    colourScheme serial not null,
    primary key (id),
    foreign key (ownedBy) references Users(id),
    foreign key (colourScheme) references PageColours(id)
);

create table ContactLists (
    id          serial,
    "name"      NameValue not null,
    ownerID      serial not null,
    personID    serial not null,
    primary key (id),
    foreign key (ownerID) references Users(id),
    foreign key (personID) references People(id)
);

alter table People add foreign key (contactID) references ContactLists(id);

create table MembersOf(
    contactID   serial,
    personID    serial,
    nickName    NameValue,
    primary key (contactID, personID),
    foreign key (contactID) references ContactLists(id),
    foreign key (personID) references People(id)
);

-- EVENTS: things that happen and which people attend via tickets

create table EventInfo (
	id          serial,
	title       LongNameValue,
    details     text,
    categories  text,
    startingTime date,
    duration    interval,
    showFee     boolean default false, -- whether the service fee will be included in ticket price
    showLeft    boolean default false, -- whether the page will show the remaining tickets
    isPrivate   boolean default true,
    locationID  serial not null,
    themeID     serial not null,
    organiserID serial not null,
	primary key (id),
    foreign key (locationID) references Places(id),
    foreign key (themeID) references PageColours(id),
    foreign key (organiserID) references Organisers(id),
    unique(locationID, startingTime, duration)
);

create table Events (
	id          serial,
    startDate   date not null,
    startTime   time not null,
    eventinfoID serial not null,
    invitedPeople serial, -- people are invited to the event
    attendedPeople serial, -- people attended to the event
    repeatingID serial,
	primary key (id),
    foreign key (eventinfoID) references EventInfo(id),
    foreign key (invitedPeople) references People(id),
    foreign key (attendedPeople) references People(id)
);

alter table People add foreign key (invitedEvent) references Events(id);
alter table People add foreign key (attendedEvent) references Events(id);

create domain EventRepetitionType as varchar(10)
	check (value in ('daily','weekly','monthly-by-day','monthly-by-date'));

create domain DayOfWeekType as char(3)
	check (value in ('mon','tue','wed','thu','fri','sat','sun'));

create table RepeatingEvents (
	id          serial,
	upperDate   date not null,
    lowerDate   date not null,
    eventinfoID serial not null,
	primary key (id),
    foreign key (eventinfoID) references EventInfo(id),
    check (upperDate - lowerDate >= 0)
);

alter table Events add foreign key (repeatingID) references RepeatingEvents(id);

create table DailyEvent (
    repeatingID serial,
    frequency   integer check (frequency > 0 AND frequency < 32),
    primary key (repeatingID),
    foreign key (repeatingID) references RepeatingEvents(id)
);

create table WeeklyEvent (
    repeatingID serial,
    dayOfWeek   DayOfWeekType,
    frequency   integer check (frequency > 0 AND frequency < 5),
    primary key (repeatingID),
    foreign key (repeatingID) references RepeatingEvents(id)
);

create table MonthlyByDayEvent (
    repeatingID serial,
    dayOfWeek   DayOfWeekType,
    weekInMonth integer check (weekInMonth > 0 AND weekInMonth < 6),
    primary key (repeatingID),
    foreign key (repeatingID) references RepeatingEvents(id)
);

create table MonthlyByDateEvent (
    repeatingID serial,
    dateInMonth integer check (dateInMonth > 0 AND dateInMonth < 32),
    primary key (repeatingID),
    foreign key (repeatingID) references RepeatingEvents(id)
);

-- TICKETS: things that let you attend an event

create table TicketTypes (
	id          serial,
	"type"      NameValue,
    "description" LongNameValue,
    totalNumber integer check (totalNumber >= 0),
    price       numeric not null check (price > 0),
    currency    char(3) check (currency ~ '[A-Z]{3}'),
    maxPerSale  integer,
    eventinfoID serial not null,
	primary key (id),
    foreign key (eventinfoID) references EventInfo(id)
);

create table SoldTickets (
    id          serial,
    quantity    integer,
    ticketTypeID serial unique not null,
    buyer       serial not null,
    eventID     serial not null,
    primary key (id),
    foreign key (ticketTypeID) references TicketTypes(id),  
    foreign key (buyer) references People(id),  
    foreign key (eventID) references Events(id)
);
