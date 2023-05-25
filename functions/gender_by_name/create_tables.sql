--set session search_path = '';
--drop schema if exists depers cascade;
--create schema depers;

------------------------------------------------------------------------------------------------------------------------

create type depers.gender as enum ('male', 'female', 'unknown');
create type depers.name_type as enum ('last_name', 'middle_name', 'first_name');

------------------------------------------------------------------------------------------------------------------------
create table depers.gender_by_ending
(
    id              integer generated always as identity ,
    ending          varchar(50) not null check (ending != '' AND btrim(ending) = ending),
    gender          depers.gender      not null,
    name_type       depers.name_type   not null,
    example         varchar(255),
    ending_translit varchar(50) check (ending_translit != '' AND btrim(ending_translit) = ending_translit)
);

comment on table depers.gender_by_ending is 'Словарь окончаний фамилий для детектирования пола человека';

comment on column depers.gender_by_ending.ending is 'Окончание';
comment on column depers.gender_by_ending.gender is 'Пол';
comment on column depers.gender_by_ending.name_type is 'Тип last_name или middle_name';
comment on column depers.gender_by_ending.example is 'Пример';
comment on column depers.gender_by_ending.ending_translit is 'Транслитерация функцией iuliia_translate_mosmetro()';

\copy depers.gender_by_ending from 'func_utils/gender_by_name/gender_by_ending.csv' with (format csv, header) --without ;

-- создавать индексы после вставки данных гораздо быстрее, чем наоборот
alter table depers.gender_by_ending add primary key (id);
create index on depers.gender_by_ending (name_type);
create unique index on depers.gender_by_ending (lower(ending));

------------------------------------------------------------------------------------------------------------------------
create table depers.person_name_dictionary
(
    id            integer generated always as identity,
    name          varchar(255) not null check (name != '' AND btrim(name) = name),
    gender        depers.gender,
    name_translit varchar(255) check (name_translit != '' AND btrim(name_translit) = name_translit),
    popularity    real check (popularity between 0 AND 1)
);

comment on table depers.person_name_dictionary is 'Словарь имён для детектирования пола человека';

comment on column depers.person_name_dictionary.name is 'Имя';
comment on column depers.person_name_dictionary.gender is 'Пол';
comment on column depers.person_name_dictionary.name_translit is 'Транслитерация функцией iuliia_translate_mosmetro()';
comment on column depers.person_name_dictionary.popularity is 'Популярность всех имён относительно друг-друга. NULL приравнивается к 1';

\copy depers.person_name_dictionary from 'func_utils/gender_by_name/person_name_dictionary.csv' with (format csv, header) --without ;

-- создавать индексы после вставки данных гораздо быстрее, чем наоборот
alter table depers.person_name_dictionary add primary key (id);
create unique index on depers.person_name_dictionary (lower(name));
create index on depers.person_name_dictionary (lower(name_translit));

-- исправления в словаре имён
update person_name_dictionary set gender = 'male' where name = 'Даня' and gender is null;
