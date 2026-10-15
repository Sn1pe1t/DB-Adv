do $$ 
begin


    -- Транзакция 1: структура таблиц и счётчики (sequence)


    begin

    drop table if exists "Параметры", "Пачки", "Пользователи", "Типы параметров",
                         "Единицы измерения", "Базовые единицы", "Типы оборудования", "Должности",
                         "Виртуальные поправки" cascade;
 
    drop sequence if exists seq_parameters, seq_batches, seq_users, seq_parameter_types,
                            seq_units, seq_base_units, seq_equipment_types, seq_positions;
 
    create sequence seq_positions;
    create sequence seq_equipment_types;
    create sequence seq_base_units;
    create sequence seq_units;
    create sequence seq_parameter_types;
    create sequence seq_users;
    create sequence seq_batches;
    create sequence seq_parameters;
 
    create table "Должности" (
        "Код"      integer      primary key default nextval('seq_positions'),
        "Название" varchar(100) not null
    );
 
    create table "Типы оборудования" (
        "Код"      integer      primary key default nextval('seq_equipment_types'),
        "Название" varchar(100) not null
    );
 
    create table "Базовые единицы" (
        "Код"      integer      primary key default nextval('seq_base_units'),
        "Название" varchar(100) not null,
        "Символ"   varchar(12)  not null
    );
 
    create table "Единицы измерения" (
        "Код"                 integer      primary key default nextval('seq_units'),
        "Название"            varchar(100) not null,
        "Символ"              varchar(12)  not null,
        "Код базовой единицы" integer      not null
    );
 
    create table "Типы параметров" (
        "Код"                   integer      primary key default nextval('seq_parameter_types'),
        "Название"              varchar(100) not null,
        "Код единицы измерения" integer      not null,
        "Мин значение"          numeric,
        "Макс значение"         numeric
    );
 
    create table "Пользователи" (
        "Код"           integer     primary key default nextval('seq_users'),
        "Фамилия"       varchar(50) not null,
        "Имя"           varchar(50) not null,
        "Логин"         varchar(50) not null,
        "Код должности" integer     not null
    );
 
    create table "Пачки" (
        "Код"              integer      primary key default nextval('seq_batches'),
        "Название"         varchar(100) not null,
        "Код пользователя" integer      not null,
        "Код оборудования" integer      not null,
        "Дата измерения"   timestamp    not null default current_timestamp
    );
 
    create table "Параметры" (
        "Код"                integer      primary key default nextval('seq_parameters'),
        "Значение"           numeric      not null,
        "Код пачки"          integer      not null,
        "Код типа параметра" integer      not null
    );
 
    create table "Виртуальные поправки" (
        "Температура"      numeric      not null,
        "Поправка"         numeric      not null
    );
 
    end;
    commit;

    -- Транзакция 2: тестовые данные


    begin

    insert into "Должности" ("Код", "Название") values
        (1, 'Оператор'),
        (2, 'Метеоролог'),
        (3, 'Администратор');
 
    insert into "Типы оборудования" ("Код", "Название") values
        (1, 'ДМК'),
        (2, 'ВР');
 
    insert into "Базовые единицы" ("Код", "Название", "Символ") values
        (1, 'Длина',       'м'),
        (2, 'Температура', 'C'),
        (3, 'Давление',    'мм рт. ст.'),
        (4, 'Угол',        'д.у.'),
        (5, 'Скорость',    'м/с');
 
    insert into "Единицы измерения" ("Код", "Название", "Символ", "Код базовой единицы") values
        (1, 'Метр',                      'м',          1),
        (2, 'Градус Цельсия',            'C',          2),
        (3, 'Миллиметр ртутного столба', 'мм рт. ст.', 3),
        (4, 'Деление угломера',          'д.у.',       4),
        (5, 'Метр в секунду',            'м/с',        5);
 
    insert into "Типы параметров" ("Код", "Название", "Код единицы измерения", "Мин значение", "Макс значение") values
        (1, 'Высота метеопоста',    1, null, null),
        (2, 'Температура',          2, -58,  58),
        (3, 'Давление',             3, 500,  900),
        (4, 'Направление ветра',    4, 0,    59),
        (5, 'Скорость ветра',       5, 0,    15),
        (6, 'Дальность сноса пуль', 1, 0,    150);
 
    insert into "Пользователи" ("Код", "Фамилия", "Имя", "Логин", "Код должности") values
        (1, 'Иванов',  'Иван',    'ivanov',  1),
        (2, 'Петров',  'Алексей', 'petrov',  2),
        (3, 'Сидоров', 'Дмитрий', 'sidorov', 3);
 
    insert into "Пачки" ("Код", "Название", "Код пользователя", "Код оборудования", "Дата измерения") values
        (1, 'Метеопост №1',      1, 1, '2026-10-01 09:00:00'),
        (2, 'Метеопост №2',      1, 1, '2026-10-01 12:00:00'),
        (3, 'Ветровое ружье №1', 1, 2, '2026-10-02 09:00:00'),
        (4, 'Метеопост №3',      2, 1, '2026-10-02 12:00:00'),
        (5, 'Ветровое ружье №2', 2, 2, '2026-10-03 09:00:00'),
        (6, 'Метеопост №4',      2, 1, '2026-10-03 12:00:00'),
        (7, 'Ветровое ружье №3', 3, 2, '2026-10-04 09:00:00'),
        (8, 'Метеопост №5',      3, 1, '2026-10-04 12:00:00'),
        (9, 'Ветровое ружье №4', 3, 2, '2026-10-05 09:00:00');
 
    insert into "Параметры" ("Код", "Значение", "Код пачки", "Код типа параметра") values
        (1,  100,  1, 1),
        (2,  15,   1, 2),
        (3,  750,  1, 3),
        (4,  5,    1, 4),
        (5,  3,    1, 5),
 
        (6,  120,  2, 1),
        (7,  12.5, 2, 2),
        (8,  748,  2, 3),
        (9,  15,   2, 4),
        (10, 4,    2, 5),
 
        (11, 100,  3, 1),
        (12, 18,   3, 2),
        (13, 752,  3, 3),
        (14, 10,   3, 4),
        (15, 20,   3, 6),
 
        (16, 80,   4, 1),
        (17, -5,   4, 2),
        (18, 760,  4, 3),
        (19, 30,   4, 4),
        (20, 6,    4, 5),
 
        (21, 150,  5, 1),
        (22, 22.5, 5, 2),
        (23, 745,  5, 3),
        (24, 45,   5, 4),
        (25, 35,   5, 6),
 
        (26, 60,   6, 1),
        (27, 8,    6, 2),
        (28, 755,  6, 3),
        (29, 59,   6, 4),
        (30, 2,    6, 5),
 
        (31, 200,  7, 1),
        (32, -12,  7, 2),
        (33, 765,  7, 3),
        (34, 20,   7, 4),
        (35, 60,   7, 6),
 
        (36, 90,   8, 1),
        (37, 25,   8, 2),
        (38, 740,  8, 3),
        (39, 0,    8, 4),
        (40, 10,   8, 5),
 
        (41, 110,  9, 1),
        (42, 3.5,  9, 2),
        (43, 758,  9, 3),
        (44, 40,   9, 4),
        (45, 15,   9, 6);
 
    -- таблица 1 алгоритма расчёта: виртуальная поправка по температуре t0
    insert into "Виртуальные поправки" ("Температура", "Поправка") values
        (0, 0.5),
        (5, 0.5),
        (10, 1),
        (20, 1.5),
        (25, 2),
        (30, 3.5),
        (40, 4.5);

    end;
    commit;


    -- Транзакция 3: связи между таблицами и ограничения


    begin

    alter table "Единицы измерения" add constraint fk_units_base
        foreign key ("Код базовой единицы") references "Базовые единицы" ("Код");
 
    alter table "Типы параметров" add constraint fk_parameter_types_unit
        foreign key ("Код единицы измерения") references "Единицы измерения" ("Код");
 
    alter table "Пользователи" add constraint fk_users_position
        foreign key ("Код должности") references "Должности" ("Код");
 
    alter table "Пачки" add constraint fk_batches_user
        foreign key ("Код пользователя") references "Пользователи" ("Код");
 
    alter table "Пачки" add constraint fk_batches_equipment
        foreign key ("Код оборудования") references "Типы оборудования" ("Код");
 
    alter table "Параметры" add constraint fk_parameters_batch
        foreign key ("Код пачки") references "Пачки" ("Код");
 
    alter table "Параметры" add constraint fk_parameters_type
        foreign key ("Код типа параметра") references "Типы параметров" ("Код");
 
    alter table "Пользователи" add constraint uq_users_login
        unique ("Логин");
 
    alter table "Типы параметров" add constraint uq_parameter_types_name
        unique ("Название");
 
    alter table "Параметры" add constraint uq_parameters_batch_type
        unique ("Код пачки", "Код типа параметра");
 
    alter table "Типы параметров" add constraint ck_parameter_types_range
        check ("Мин значение" <= "Макс значение");

    end;
    commit;

end $$;