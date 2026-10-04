

-- Удаление таблиц


DROP TABLE IF EXISTS "Пользователи" CASCADE;
DROP TABLE IF EXISTS "Пачки" CASCADE;
DROP TABLE IF EXISTS "Параметры" CASCADE;
DROP TABLE IF EXISTS "Должности" CASCADE;
DROP TABLE IF EXISTS "Типы оборудования" CASCADE;


-- Создание таблиц


CREATE TABLE "Должности" (
    "Код" INTEGER PRIMARY KEY,
    "Название" VARCHAR(100) NOT NULL
);

CREATE TABLE "Типы оборудования" (
    "Код" INTEGER PRIMARY KEY,
    "Название" VARCHAR(100) NOT NULL
);

CREATE TABLE "Параметры" (
    "Код" INTEGER PRIMARY KEY,
    "Название" VARCHAR(100) NOT NULL,
    "Значение" VARCHAR(100) NOT NULL
);

CREATE TABLE "Пользователи" (
    "Код" INTEGER PRIMARY KEY,
    "Фамилия" VARCHAR(50) NOT NULL,
    "Имя" VARCHAR(50) NOT NULL,
    "Логин" VARCHAR(50) UNIQUE NOT NULL,
    "Код должности" INTEGER NOT NULL
);

CREATE TABLE "Пачки" (
    "Код" INTEGER PRIMARY KEY,
    "Название" VARCHAR(100) NOT NULL,
    "Код пользователя" INTEGER NOT NULL,
    "Код оборудования" INTEGER NOT NULL,
    "Код параметра" INTEGER NOT NULL,
    "Дата измерения" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Тестовые данные


INSERT INTO "Должности" ("Код", "Название") VALUES
(1, 'Оператор'),
(2, 'Метеоролог'),
(3, 'Администратор');

INSERT INTO "Типы оборудования" ("Код", "Название") VALUES
(1, 'ДМК'),
(2, 'ВР');

INSERT INTO "Параметры" ("Код", "Название", "Значение") VALUES
(1, 'Высота метеопоста', '100 м'),
(2, 'Температура', '15 C'),
(3, 'Давление', '750 мм рт. ст.'),
(4, 'Направление ветра', '00'),
(5, 'Скорость ветра', '0 м/с'),
(6, 'Дальность сноса пуль', '0 м');

INSERT INTO "Пользователи"
    ("Код", "Фамилия", "Имя", "Логин", "Код должности")
VALUES
(1, 'Иванов', 'Иван', 'ivanov', 1),
(2, 'Петров', 'Алексей', 'petrov', 2),
(3, 'Сидоров', 'Дмитрий', 'sidorov', 3);

INSERT INTO "Пачки"
    ("Код", "Название", "Код пользователя",
     "Код оборудования", "Код параметра")
VALUES
(1, 'Метеопост №1', 1, 1, 1),
(2, 'Метеопост №2', 2, 1, 2),
(3, 'Ветровое ружье №1', 3, 2, 6);


-- Select с объединением


SELECT
    p."Код" AS "Код пачки",
    p."Название" AS "Пачка",
    u."Фамилия",
    u."Имя",
    d."Название" AS "Должность",
    t."Название" AS "Тип оборудования",
    par."Название" AS "Параметр",
    par."Значение"
FROM "Пачки" p
JOIN "Пользователи" u
    ON p."Код пользователя" = u."Код"
JOIN "Должности" d
    ON u."Код должности" = d."Код"
JOIN "Типы оборудования" t
    ON p."Код оборудования" = t."Код"
JOIN "Параметры" par
    ON p."Код параметра" = par."Код";