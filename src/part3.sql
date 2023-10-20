/* Part 3.1
Написать функцию, возвращающую таблицу TransferredPoints в более человекочитаемом виде.
Peer's nickname 1, Peer's nickname 2, number of transferred peer points. 
The number is negative if peer 2 received more points from peer 1.
*/

CREATE OR REPLACE FUNCTION return_modified_transferredpoints() RETURNS TABLE (Peer1 VARCHAR, Peer2 VARCHAR, PointsAmount INTEGER)
AS $$
BEGIN
    RETURN QUERY
        WITH tmp AS (SELECT DISTINCT t1."ID", t1."CheckingPeer" "Checking", t1."CheckedPeer"  "Checked", t1."PointsAmount" "Points"
					 FROM "TransferredPoints" t1 JOIN "TransferredPoints" t2 ON t1."CheckingPeer" = t2."CheckedPeer"
					 WHERE (t1."CheckingPeer", t1."CheckedPeer") = (t2."CheckedPeer", t2."CheckingPeer")),
					 RESULT AS (SELECT "CheckingPeer", "CheckedPeer", "PointsAmount" FROM "TransferredPoints" EXCEPT ALL
								SELECT "Checking", "Checked", "Points" FROM tmp UNION ALL
								SELECT t1."Checking", t1."Checked", "Points_1" - "Points_2" AS "Points"
								FROM (SELECT "Checking", "Checked", SUM("Points") "Points_1" FROM tmp GROUP BY 1, 2) t1
								JOIN (SELECT "Checking", "Checked", SUM("Points") "Points_2" FROM tmp GROUP BY 1, 2) t2
								ON (t1."Checking", t1."Checked") = (t2."Checked", t2."Checking")
								WHERE t1."Checking" > t1."Checked") SELECT "CheckingPeer" AS Peer1, "CheckedPeer" AS Peer2,
								SUM("PointsAmount")::INTEGER "PointsAmount"
								FROM RESULT GROUP BY 1, 2 ORDER BY 1, 2;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS return_modified_transferredpoints();

-- Проверка
SELECT * FROM "TransferredPoints";
SELECT * FROM return_modified_transferredPoints();


/* Part 3.2
Написать функцию, которая возвращает таблицу: user name, name of the checked task, number of XP received.
В таблицу включать только задания, успешно прошедшие проверку (определять по таблице Checks). 
Одна задача может быть успешно выполнена несколько раз. В таком случае в таблицу включать все успешные проверки.
*/

CREATE OR REPLACE FUNCTION tasks_passed_test() RETURNS TABLE (Peer VARCHAR, Task TEXT, XP INTEGER)
AS $$
BEGIN
    RETURN QUERY SELECT "Checks"."Peer", SPLIT_PART("Checks"."Task", '_', 1) AS Task,
	"XP"."XPAmount" AS XP FROM "Checks" JOIN "XP" ON "Checks"."ID" = "XP"."Check" ORDER BY 1, 2, 3 DESC;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS tasks_passed_test();

-- Проверка
SELECT * FROM tasks_passed_test();


/* Part 3.3
Написать функцию, определяющую пиров, которые не выходили из кампуса в течение всего дня.
Function parameters: day, for example 12.05.2022. The function returns only a list of peers.
*/

CREATE OR REPLACE FUNCTION peers_have_not_left_campus_all_day(Peer_date date) RETURNS TABLE (Peer VARCHAR(50))
AS $$
SELECT "Peer" FROM "TimeTracking" WHERE "Date" = Peer_date AND "State" = '1' 
GROUP BY "Peer" HAVING SUM("State") = 1
$$ LANGUAGE sql;


DROP FUNCTION IF EXISTS peers_have_not_left_campus_all_day(peer_date date);

-- Проверка
SELECT * FROM peers_have_not_left_campus_all_day('2023-03-03');
INSERT INTO TimeTracking (Peer, "Date", "Time", State) VALUES ('littleca', '2023-03-03', '08:30:00', 1);
SELECT * FROM peers_have_not_left_campus_all_day('2023-03-03');


/* Part 3.4
Посчитать изменение в количестве пир поинтов каждого пира по таблице TransferredPoints.
Output the result sorted by the change in the number of points.
Output format: peer's nickname, change in the number of peer points.
*/


CREATE OR REPLACE FUNCTION changes_quantity_points() RETURNS TABLE (Peer VARCHAR, Points INTEGER )
AS $$
SELECT tmp."CheckingPeer" AS peer, SUM(sum) AS Points
FROM (SELECT tp."CheckingPeer", SUM(tp."PointsAmount") AS sum
	  FROM "TransferredPoints" tp GROUP BY tp."CheckingPeer" UNION
	  SELECT tp."CheckedPeer" AS peer, SUM(-1 * tp."PointsAmount") AS sum
      FROM "TransferredPoints" tp GROUP BY tp."CheckedPeer") tmp
	  GROUP BY tmp."CheckingPeer" ORDER BY Points;
$$ LANGUAGE sql;


DROP FUNCTION IF EXISTS changes_quantity_points();

-- Проверка
select * from "TransferredPoints";
SELECT * FROM changes_quantity_points();


/* Part 3.5
Посчитать изменение в количестве пир поинтов каждого пира по таблице, возвращаемой первой функцией из Part 3.
Output the result sorted by the change in the number of points. 
Output format: peer's nickname, change in the number of peer points.
*/

CREATE OR REPLACE FUNCTION change_points_from_first_function() RETURNS TABLE (Peer VARCHAR, PointsChange REAL)
AS $$
    BEGIN
        RETURN QUERY (WITH answer_1 AS (SELECT Peer1, SUM(PointsAmount)::REAL AS SUM FROM return_modified_transferredPoints() GROUP BY Peer1),
                           answer_2 AS (SELECT Peer2, SUM(PointsAmount)::REAL AS SUM FROM return_modified_transferredPoints() GROUP BY Peer2)
                      SELECT COALESCE(Peer1, Peer2), (COALESCE(answer_1.SUM, 0) - COALESCE(answer_2.SUM, 0)) AS points
                      FROM answer_1 FULL JOIN answer_2 ON answer_1.Peer1 = answer_2.Peer2 ORDER BY points);
    END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS change_points_from_first_function();

-- Проверка
SELECT * FROM change_points_from_first_function();


/* Part 3.6
Определить самое часто проверяемое задание за каждый день.
Output format: day, task name. If there is the same number of checks for some tasks in a certain day, output all of them. 
*/

CREATE OR REPLACE FUNCTION most_checked_task_every_day() RETURNS TABLE (Day TEXT, Task VARCHAR)
AS $$
    BEGIN
        RETURN QUERY (WITH answer_1 AS (SELECT "Checks"."Task", "Checks"."Date", COUNT(*) AS counts
										FROM "Checks"  GROUP BY "Checks"."Task", "Checks"."Date"),
                           answer_2 AS (SELECT answer_1."Task", answer_1."Date", RANK()
										OVER (PARTITION BY answer_1."Date" ORDER BY counts DESC) AS RANK FROM answer_1)
                      SELECT TO_CHAR("Date", 'dd.mm.yyyy'), answer_2."Task" FROM answer_2 WHERE rank = 1);
    END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS most_checked_task_every_day();

-- Проверка
SELECT * FROM most_checked_task_every_day();


/* Part 3.7
Найти всех пиров, выполнивших весь заданный блок задач и дату завершения последнего задания.
Procedure parameters: name of the block, for example “CPP”. The result is sorted by the date of completion. 
Output format: peer's name, date of completion of the block (i.e. the last completed task from that block)
*/

CREATE OR REPLACE PROCEDURE peers_completed_block_tasks(ref refcursor, IN name VARCHAR)
AS $$
BEGIN
    OPEN ref FOR
        WITH Block AS (SELECT DISTINCT "Title" AS "Title" FROM "Tasks" WHERE "Title" SIMILAR TO (Name || '[0-9]%')),
		tmp_1 AS (SELECT "Peer", COUNT(*) AS count, MAX("Date") AS day
				FROM (SELECT DISTINCT "Peer", "Task", "Date" FROM "Checks"
					  JOIN "XP" ON "Checks"."ID" = "XP"."Check" JOIN Block ON "Checks"."Task" = Block."Title") tmp_2 GROUP BY "Peer")
					  SELECT "Peer", TO_CHAR(Day, 'DD.MM.YYYY') AS day
					  FROM tmp_1 WHERE count = (SELECT COUNT(*) FROM block);
END;
$$ LANGUAGE plpgsql;


DROP PROCEDURE IF EXISTS peers_completed_block_tasks;

-- Проверка
BEGIN;
CALL peers_completed_block_tasks('ref', 'CPP');
FETCH ALL IN "ref";
CLOSE ref;
END;


/* Part 3.8
Определить, к какому пиру стоит идти на проверку каждому обучающемуся.
You should determine it according to the recommendations of the peer's friends, i.e. you need to find the peer with the greatest number of friends who recommend to be checked by him. 
Output format: peer's nickname, nickname of the checker found
*/

CREATE OR REPLACE FUNCTION recommended_check() RETURNS TABLE (Peer VARCHAR, RecommendedPeer VARCHAR)
AS $$
    BEGIN
        RETURN QUERY (WITH answer AS (SELECT "Nickname", (CASE WHEN "Nickname" = "Friends"."Peer1" THEN "Peer2" ELSE "Peer1" END) AS tmp
                                   FROM "Peers" JOIN "Friends" ON "Peers"."Nickname" = "Friends"."Peer1" OR "Peers"."Nickname" = "Friends"."Peer2"),
                           answer_1 AS (SELECT answer."Nickname", "Recommendations"."RecommendedPeer",
									COUNT("Recommendations"."RecommendedPeer") AS count
                                    FROM answer JOIN "Recommendations" ON answer.tmp = "Recommendations"."Peer"
                                    WHERE answer."Nickname" != "Recommendations"."RecommendedPeer"
									GROUP BY answer."Nickname", "Recommendations"."RecommendedPeer"),
                           answer_2 AS (SELECT "Nickname" FROM answer_1 GROUP BY "Nickname")
                      SELECT answer_1."Nickname", answer_1."RecommendedPeer"
                      FROM answer_1 JOIN answer_2 ON answer_1."Nickname" = answer_2."Nickname"
					  WHERE answer_1.count = (SELECT MAX(count) FROM answer_1));
    END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS recommended_check();

-- Проверка
SELECT * FROM recommended_check();


/* Part 3.9
Определить процент пиров, которые: приступили только к блоку 1, приступили только к блоку 2,
приступили к обоим блокам, не приступили ни к одному блоку.
Пир считается приступившим к блоку, если он проходил хоть одну проверку любого задания из этого блока (по таблице Checks)
Procedure parameters: name of block 1, for example SQL, name of block 2, for example A. 
Output format: percentage of those who started only the first block,
percentage of those who started only the second block, percentage of those who started both blocks,
percentage of those who did not started any of them.
*/

CREATE OR REPLACE PROCEDURE completion_task_blocks_percentage(IN name1 TEXT, IN name2 TEXT, OUT StartedBlock1 REAL,
															  OUT StartedBlock2 REAL, OUT StartedBothBlock REAL, OUT DidntStartAnyBlock REAL)
AS $$
    BEGIN
        CREATE TABLE answer_1 (name1_tmp VARCHAR, name2_tmp VARCHAR);
        INSERT INTO answer_1 VALUES (name1, name2);
        CREATE VIEW answer_2 AS (WITH first_arg AS (SELECT DISTINCT "Peer" FROM "Checks"
					WHERE "Checks"."Task" SIMILAR TO CONCAT((SELECT name1_tmp FROM answer_1), '[0-7]%')),
                 second_arg AS (SELECT DISTINCT "Peer" FROM "Checks"
					WHERE "Checks"."Task" SIMILAR TO CONCAT((SELECT name2_tmp FROM answer_1), '[0-7]%')),
                 started_block1 AS (SELECT "Peer" FROM first_arg EXCEPT SELECT "Peer" FROM second_arg),
                 started_block2 AS (SELECT "Peer" FROM second_arg EXCEPT SELECT "Peer" FROM first_arg),
                 started_both_block AS (SELECT "Peer" FROM first_arg INTERSECT SELECT "Peer" FROM second_arg),
                 didnt_start_any_block AS (SELECT "Nickname" FROM "Peers" JOIN "Checks" ON "Peers"."Nickname" = "Checks"."Peer"
                    EXCEPT SELECT "Peer" FROM started_block1
					EXCEPT SELECT "Peer" FROM started_block2
					EXCEPT SELECT "Peer" FROM started_both_block),
                 didnt_start_any_block2 AS (SELECT "Nickname" FROM "Peers" LEFT JOIN "Checks" ON "Peers"."Nickname" = "Checks"."Peer" WHERE "Peer" IS NULL)
            SELECT (((SELECT COUNT(*) FROM started_block1)::REAL * 100) / (SELECT COUNT("Peers"."Nickname") FROM "Peers")::REAL) AS first,
                   (((SELECT COUNT(*) FROM started_block2)::REAL * 100) / (SELECT COUNT("Peers"."Nickname") FROM "Peers")::REAL) AS second,
                   (((SELECT COUNT(*) FROM started_both_block)::REAL * 100) / (SELECT COUNT("Peers"."Nickname") FROM "Peers")::REAL) AS third,
                   (((SELECT COUNT(*) FROM didnt_start_any_block)::REAL * 100) / (SELECT COUNT("Peers"."Nickname") FROM "Peers")::REAL) AS fourth,
                   (((SELECT COUNT(*) FROM didnt_start_any_block2)::REAL * 100) / (SELECT COUNT("Peers"."Nickname") FROM "Peers")::REAL) AS fifth);
        StartedBlock1 = (SELECT first FROM answer_2);
        StartedBlock2 = (SELECT second FROM answer_2);
        StartedBothBlock = (SELECT third FROM answer_2);
        DidntStartAnyBlock = (SELECT fourth + fifth FROM answer_2);
        DROP VIEW answer_2 CASCADE;
        DROP TABLE answer_1 CASCADE;
    END;
$$ LANGUAGE plpgsql;


DROP PROCEDURE IF EXISTS completion_task_blocks_percentage;

-- Проверка
CALL completion_task_blocks_percentage('Linux', 'C', NULL, NULL, NULL, NULL);
CALL completion_task_blocks_percentage('Linux', 'CPP', NULL, NULL, NULL, NULL);
CALL completion_task_blocks_percentage('CPP', 'C', NULL, NULL, NULL, NULL);


/* Part 3.10
Определить процент пиров, которые когда-либо успешно проходили проверку в свой день рождения.
Также определите процент пиров, которые хоть раз проваливали проверку в свой день рождения. 
Output format: percentage  of peers who have ever successfully passed a check on their birthday,
percentage of peers who have ever failed a check on their birthday
*/

CREATE OR REPLACE FUNCTION birthday_checks()
    RETURNS TABLE (SuccessfulChecks REAL, UnsuccessfulChecks REAL)
AS $$
    BEGIN
        RETURN QUERY (WITH tmp_1 AS (SELECT "Nickname", EXTRACT(day FROM "Birthday") AS x_1,
								EXTRACT(month FROM "Birthday") AS X_2 FROM "Peers"),
					  tmp_2 AS (SELECT "Checks"."ID", "Peer", EXTRACT(day FROM "Date") AS y_1,
								EXTRACT(month FROM "Date") AS y_2, "P2P"."State" AS "P2P", "Verter"."State" AS "Verter" FROM "Checks"
							   	JOIN "P2P" ON "Checks"."ID" = "P2P"."Check" LEFT JOIN "Verter" ON "Checks"."ID" = "Verter"."Check"
							  	WHERE "P2P"."State" IN ('Success', 'Failure') AND ("Verter"."State" IN ('Success', 'Failure') OR "Verter"."State" IS NULL)),
					  tmp_3 AS (SELECT * FROM tmp_1 JOIN tmp_2 ON tmp_1.x_1 = tmp_2.y_1 AND tmp_1.x_2 = tmp_2.y_2),
					  success AS (SELECT COUNT(*) AS s FROM tmp_3 WHERE "P2P" = 'Success' AND ("Verter" = 'Success' OR "Verter" IS NULL)),
					  fail AS (SELECT COUNT(*) AS f FROM tmp_3 WHERE "P2P" = 'Failure' OR "Verter" = 'Failure'),
					  last_chance_1 AS (SELECT round(((SELECT s FROM success)::REAL * 100) / (SELECT COUNT("Nickname") FROM tmp_3))::REAL AS last_1),
					  last_chance_2 AS (SELECT round(((SELECT f FROM fail)::REAL * 100) / (SELECT COUNT("Nickname") FROM tmp_3))::REAL AS last_2)
                      SELECT last_1, last_2 FROM last_chance_1 CROSS JOIN last_chance_2);
    END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS birthday_checks();

-- Проверка
SELECT * FROM birthday_checks();


/* Part 3.11
Определить всех пиров, которые сдали заданные задания 1 и 2, но не сдали задание 3
Параметры процедуры: названия заданий 1, 2 и 3. 
Output format: list of peers.
*/
CREATE OR REPLACE PROCEDURE find_peers_with_task_conditions(task1 VARCHAR, task2 VARCHAR, task3 VARCHAR, OUT peer VARCHAR)
AS $$
BEGIN
    SELECT DISTINCT c1."Peer" INTO peer
    FROM "Checks" c1
    LEFT JOIN "Checks" c2 ON c1."Peer" = c2."Peer" AND c2."Task" = task3
    WHERE c1."Task" = task1 AND c2."Task" IS NULL;

    IF peer IS NULL THEN
        SELECT DISTINCT c1."Peer" INTO peer
        FROM "Checks" c1
        LEFT JOIN "Checks" c2 ON c1."Peer" = c2."Peer" AND c2."Task" = task3
        WHERE c1."Task" = task2 AND c2."Task" IS NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

/* Part 3.12
Используя рекурсивное обобщенное табличное выражение, для каждой задачи вывести кол-во предшествующих ей задач,
то есть сколько задач нужно выполнить, исходя из условий входа, чтобы получить доступ к текущей. 
Output format: task name, number of preceding tasks
*/

CREATE OR REPLACE FUNCTION number_previous_tasks() RETURNS TABLE(Task VARCHAR, PrevCount INTEGER)
AS $$
WITH RECURSIVE r AS (SELECT CASE WHEN ("Tasks"."ParentTask" IS NULL)
					 THEN 0 ELSE 1 END AS counter, "Tasks"."Title", "Tasks"."ParentTask" AS current_tasks, "Tasks"."ParentTask"
					 FROM "Tasks" UNION ALL
					 SELECT (CASE WHEN child."ParentTask" IS NOT NULL THEN counter + 1 ELSE counter END)
					 AS counter, child."Title" AS "Title", child."ParentTask" AS current_tasks, parrent."Title" AS "ParentTask"
					 FROM "Tasks" AS child CROSS JOIN r AS parrent WHERE parrent."Title" LIKE child."ParentTask") SELECT "Title" AS Task,
					 MAX(counter) AS PrevCount FROM r GROUP BY "Title" ORDER BY 1;
$$ LANGUAGE sql;


DROP FUNCTION IF EXISTS number_previous_tasks();

-- Проверка
SELECT * FROM number_previous_tasks();

/* Part 3.13
Найти "удачные" для проверок дни. День считается "удачным", если в нем есть хотя бы N идущих подряд успешных проверки
Параметры процедуры: количество идущих подряд успешных проверок N. Временем проверки считать время начала P2P этапа. 
Под идущими подряд успешными проверками подразумеваются успешные проверки, между которыми нет неуспешных. 
При этом кол-во опыта за каждую из этих проверок должно быть не меньше 80% от максимального.
Output format: list of days
*/
CREATE OR REPLACE PROCEDURE find_lucky_check_days(N INTEGER, OUT days DATE)
AS $$
BEGIN
    SELECT DISTINCT c1."Date" INTO days
    FROM "Checks" c1
    WHERE c1."Result" = 'Success' AND c1."XP" >= 0.8 * (SELECT MAX(c2."XP") FROM "Checks" c2 WHERE c2."Date" = c1."Date")
    AND EXISTS (
        SELECT *
        FROM "Checks" c2
        WHERE c2."Date" = c1."Date" AND c2."Result" = 'Success' AND c2."XP" >= 0.8 * (SELECT MAX(c3."XP") FROM "Checks" c3 WHERE c3."Date" = c2."Date" AND c3."Time" < c2."Time")
        AND c2."Time" - c1."Time" BETWEEN INTERVAL '1 minute' * (N - 1) AND INTERVAL '1 minute' * N
    );
END;
$$ LANGUAGE plpgsql;

/* Part 3.14
Определить пира с наибольшим количеством XP
Output format: peer's nickname, amount of XP
*/
CREATE OR REPLACE FUNCTION find_peer_with_highest_xp()
    RETURNS TABLE (peer VARCHAR, xp_amount INTEGER)
AS $$
BEGIN
    RETURN QUERY
    SELECT "Peer", "XPAmount"
    FROM "XP"
    ORDER BY "XPAmount" DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;



/* Part 3.15
Определить пиров, приходивших раньше заданного времени не менее N раз за всё время
Output format: list of peers
*/
CREATE OR REPLACE FUNCTION find_peers_with_early_arrivals(N INTEGER)
    RETURNS TABLE (peer VARCHAR)
AS $$
BEGIN
    RETURN QUERY
    SELECT "Peer"
    FROM (
        SELECT "Peer", COUNT(*) AS arrival_count
        FROM "TimeTracking"
        WHERE "Time" < TIME '12:00:00'
        GROUP BY "Peer"
    ) sub
    WHERE arrival_count >= N;
END;
$$ LANGUAGE plpgsql;


/* Part 3.16
Параметры процедуры: количество дней N, количество раз M.
Output format: list of peers
*/
CREATE OR REPLACE PROCEDURE find_peers_with_specific_arrivals(N INTEGER, M INTEGER, OUT peers VARCHAR[])
AS $$
BEGIN
    SELECT ARRAY_AGG("Peer") INTO peers
    FROM (
        SELECT "Peer", COUNT(DISTINCT "Date") AS arrival_days
        FROM "TimeTracking"
        WHERE "Date" BETWEEN CURRENT_DATE - INTERVAL '1 day' * N AND CURRENT_DATE
        GROUP BY "Peer"
        HAVING COUNT(DISTINCT "Date") = M
    ) sub;
END;
$$ LANGUAGE plpgsql;



/* Part 3.17
Определить для каждого месяца процент ранних входов
Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, приходили в кампус за всё время (число входов). 
Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, приходили в кампус раньше 12:00 за всё время (число ранних входов). 
Для каждого месяца посчитать процент ранних входов в кампус относительно общего числа входов.
Output format: month, percentage of early entries
*/
CREATE OR REPLACE FUNCTION calculate_early_entry_percentage()
    RETURNS TABLE (month TEXT, percentage REAL)
AS $$
BEGIN
    RETURN QUERY
    SELECT EXTRACT(MONTH FROM "Birthday") AS month,
        COUNT(DISTINCT CASE WHEN "Time" < TIME '12:00:00' THEN "Peer" END) * 100.0 / COUNT(DISTINCT "Peer") AS percentage
    FROM "TimeTracking"
    GROUP BY month;
END;
$$ LANGUAGE plpgsql;
