-- Part 2.1
-- Написать процедуру добавления P2P проверки
-- Параметры: ник проверяемого, ник проверяющего, название задания, статус P2P проверки, время. 
-- Если задан статус "начало", добавить запись в таблицу Checks (в качестве даты использовать сегодняшнюю). Добавить запись в таблицу P2P. 
-- Если задан статус "начало", в качестве проверки указать только что добавленную запись, иначе указать проверку с незавершенным P2P этапом.
							 
CREATE OR REPLACE PROCEDURE check_p2p(peer_checked VARCHAR(50), peer_checking VARCHAR(50),
								   task_name VARCHAR(100), state check_status, time_p2p time)
AS $$ DECLARE id_check INTEGER := 0;
BEGIN
    IF state = 'Start'
    THEN
        id_check = (SELECT MAX("ID") FROM "Checks") + 1;
        INSERT INTO "Checks" ("ID", "Peer", "Task", "Date")
        VALUES (id_check, peer_checked, task_name, (SELECT CURRENT_DATE));
    ELSE
        id_check = (SELECT "Checks"."ID"
                    FROM "P2P" INNER JOIN "Checks" ON "Checks"."ID" = "P2P"."Check"
                    WHERE "CheckingPeer" = peer_checking AND "Peer" = peer_checked AND "Task" = task_name
                    ORDER BY "Checks"."ID" DESC LIMIT 1);
    END IF;
    INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (id_check, peer_checking, state, time_p2p);
END
$$ LANGUAGE plpgsql;


DROP PROCEDURE IF EXISTS check_p2p(peer_checked VARCHAR(50), peer_checking VARCHAR(50),
								   task_name VARCHAR(200), state check_status, time_p2p time);

-- Проверка
CALL check_p2p('littleca', 'cathleeb', 'A1_Maze', 'Start', '12:00:00');
CALL check_p2p('littleca', 'cathleeb', 'A1_Maze', 'Success', '13:00:00');


-- Part 2.2
-- Написать процедуру добавления проверки Verter'ом Параметры: ник проверяемого, название задания, статус проверки Verter'ом, время. 
-- Добавить запись в таблицу Verter (в качестве проверки указать проверку соответствующего задания с самым поздним (по времени) успешным P2P этапом)

CREATE OR REPLACE PROCEDURE check_verter(nickname VARCHAR(50), task_name VARCHAR(100), verter_state check_status, verter_time time)
AS $$ DECLARE
    id_check INTEGER = (SELECT "Checks"."ID" FROM "P2P" INNER JOIN "Checks"
    ON "Checks"."ID" = "P2P"."Check" AND "P2P"."State" = 'Success' AND "Checks"."Task" = task_name AND "Checks"."Peer" = nickname
    ORDER BY "P2P"."Time" LIMIT 1);
BEGIN
    INSERT INTO "Verter" ("Check", "State", "Time") VALUES (id_check, verter_state, verter_time);
END
$$ LANGUAGE plpgsql;


DROP PROCEDURE IF EXISTS check_verter(nickname VARCHAR(50), task_name VARCHAR(100), verter_state check_status, verter_time time);

-- Проверка
CALL check_verter('antoneo', 'CPP5_3DViewer_v2.1', 'Start', '22:00:00');
CALL check_verter('antoneo', 'CPP5_3DViewer_v2.1', 'Failure', '22:20:00');
CALL check_verter('antoneo', 'CPP5_3DViewer_v2.1', 'Start', '23:30:00');
CALL check_verter('antoneo', 'CPP5_3DViewer_v2.1', 'Success', '00:00:00');


-- Part 2.3
-- Написать триггер: после добавления записи со статутом "начало" в таблицу P2P, изменить соответствующую запись в таблице TransferredPoints

CREATE OR REPLACE FUNCTION change_transferredpoints_after_add_p2p() RETURNS TRIGGER
AS $$
BEGIN
	IF (NEW."State" = 'Start') THEN INSERT INTO "TransferredPoints"
	VALUES((SELECT COALESCE((MAX("ID") + 1), 1) FROM "TransferredPoints"),
	NEW."CheckingPeer", (SELECT "Peer" FROM "Checks" WHERE "ID" = NEW."Check"), 1);
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER change_transferredpoints AFTER INSERT ON "P2P"
FOR EACH ROW EXECUTE PROCEDURE change_transferredpoints_after_add_p2p();


DROP TRIGGER  change_transferredpoints  ON "P2P" CASCADE;
DROP FUNCTION change_transferredpoints_after_add_p2p() CASCADE;

-- Проверка
CALL check_p2p('cathleeb', 'antoneo', 'CPP4_3DViewer_v2.0', 'Start', '12:00:00');
CALL check_p2p('cathleeb', 'antoneo', 'CPP4_3DViewer_v2.0', 'Success', '13:00:00');


select * from "P2P";
delete from "P2P" where "ID" = 45;
select * from "TransferredPoints";
delete from "TransferredPoints" where "ID" = 15;


-- Part 2.4
-- Написать триггер: перед добавлением записи в таблицу XP, проверить корректность добавляемой записи, 
-- если запись не прошла проверку, не добавлять её в таблицу
-- Запись считается корректной, если: количество XP не превышает максимальное доступное для проверяемой задачи;
-- поле Check ссылается на успешную проверку.

CREATE OR REPLACE FUNCTION check_MaxXP() RETURNS TRIGGER AS $check_insert_xp$
    BEGIN
        IF ((SELECT "MaxXP" FROM "Checks"
            JOIN "Tasks" ON "Checks"."Task" = "Tasks"."Title"
            WHERE NEW."Check" = "Checks"."ID") < NEW."XPAmount") THEN
            RAISE EXCEPTION 'Quantity of XPAmount is over maximal value';
        ELSEIF (SELECT "State" FROM "P2P"
                WHERE NEW."Check" = "P2P"."Check" AND "P2P"."State" = 'Failure') = 'Failure' THEN
                RAISE EXCEPTION 'Verification failure P2P';
        ELSEIF (SELECT "State" FROM "Verter"
                WHERE NEW."Check" = "Verter"."Check" AND "Verter"."State" = 'Failure') = 'Failure' THEN
                RAISE EXCEPTION 'Verification failure Verter';
        END IF;
    RETURN (NEW."ID", NEW."Check", NEW."XPAmount");
    END;
$check_insert_xp$
LANGUAGE plpgsql;

CREATE TRIGGER check_insert_xp BEFORE INSERT ON "XP"
FOR EACH ROW EXECUTE FUNCTION check_MaxXP();


DROP TRIGGER  check_insert_xp  ON "XP" CASCADE;
DROP FUNCTION check_MaxXP() CASCADE;

-- Проверка
-- Запись в таблицу XP вносится
INSERT INTO "XP" VALUES (9, 20, 600);
-- Запись в таблицу XP не вносится, т.к. превышено max значение XPAmount
INSERT INTO "XP" VALUES (9, 20, 1000);
-- Запись в таблицу XP не вносится, т.к. проверка P2P Failure
INSERT INTO "XP" VALUES (10, 13, 300); 
-- Запись в таблицу XP не вносится, т.к. проверка Verter-ом Failure
INSERT INTO "XP" VALUES (10, 11, 400);
