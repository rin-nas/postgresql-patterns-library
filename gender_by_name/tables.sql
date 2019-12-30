create type gender as enum ('male', 'female');
create type name_type as enum ('last_name', 'middle_name');

create table gender_by_ending
(
    id        serial      not null constraint gender_by_ending_pkey primary key,
    ending    varchar(50) not null,
    gender    gender      not null,
    name_type name_type   not null,
    example   varchar(255)
);
comment on table gender_by_ending is 'Определение пола по окончаниям  фамилий, отчеств';
comment on column gender_by_ending.ending is 'Окончание';
comment on column gender_by_ending.gender is 'Пол';
comment on column gender_by_ending.name_type is 'Тип last_name или middle_name';
comment on column gender_by_ending.example is 'Пример';
create index gender_by_ending_name_type_index on gender_by_ending (name_type);

create table person_name_dictionary
(
    id     serial       not null constraint person_name_dictionary_pkey primary key,
    name   varchar(255) not null,
    gender gender       not null
);
comment on table person_name_dictionary is 'Словарь имен с полом';
comment on column person_name_dictionary.name is 'Имя';
comment on column person_name_dictionary.gender is 'Пол';
create unique index person_name_dictionary_name_uindex on person_name_dictionary (lower(name::text));
