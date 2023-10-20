-- Database: s21_Info21_v1.0

-- DROP DATABASE IF EXISTS "s21_Info21_v1.0";

CREATE DATABASE "s21_Info21_v1.0"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

COMMENT ON DATABASE "s21_Info21_v1.0"
    IS 'Database with data about School 21';

CREATE table "Peers" ("Nickname" VARCHAR UNIQUE PRIMARY KEY,
					"Birthday" DATE NOT NULL);

CREATE table "Tasks" ("Title" VARCHAR PRIMARY KEY NOT NULL,
 "ParentTask" VARCHAR DEFAULT NULL,
 "MaxXP" INTEGER NOT NULL,
 FOREIGN KEY ("ParentTask") REFERENCES "Tasks" ("Title"));

CREATE table "Checks" ("ID" SERIAL PRIMARY KEY,
					"Peer" VARCHAR NOT NULL,
					"Task" VARCHAR NOT NULL,
					"Date" DATE NOT NULL,
					FOREIGN KEY ("Peer") REFERENCES "Peers" ("Nickname"),
					FOREIGN KEY ("Task") REFERENCES "Tasks" ("Title"));

CREATE table "XP" ("ID" SERIAL PRIMARY KEY,
				"Check" INTEGER UNIQUE,
				"XPAmount" INTEGER NOT NULL,
				FOREIGN KEY ("Check") REFERENCES "Checks" ("ID"),
				CHECK ("XPAmount" >= 0));

CREATE TYPE CHECK_STATUS AS ENUM ('Start', 'Success', 'Failure');

CREATE table "P2P" ("ID" SERIAL PRIMARY KEY,
				 "Check" INTEGER NOT NULL,
				 "CheckingPeer" VARCHAR NOT NULL,
				 "State" CHECK_STATUS NOT NULL,
				 "Time" TIME without time zone,
				 FOREIGN KEY ("Check") REFERENCES "Checks" ("ID"),
				 FOREIGN KEY ("CheckingPeer") REFERENCES "Peers" ("Nickname"),
				 UNIQUE ("Check", "CheckingPeer", "State"));

CREATE table "Verter" ("ID" SERIAL PRIMARY KEY,
					"Check" INTEGER,
					 "State" CHECK_STATUS,
					"Time" TIME without time zone,
					FOREIGN KEY ("Check") REFERENCES "Checks" ("ID"));

CREATE table "TransferredPoints" ("ID" SERIAL PRIMARY KEY,
							   	"CheckingPeer" VARCHAR NOT NULL,
							   	"CheckedPeer" VARCHAR NOT NULL,
							   	"PointsAmount" INTEGER NOT NULL,
							   	FOREIGN KEY ("CheckingPeer") REFERENCES "Peers" ("Nickname"),
							   	FOREIGN KEY ("CheckedPeer") REFERENCES "Peers" ("Nickname"),
								CHECK ("CheckedPeer" != "CheckingPeer"));

CREATE table "Friends" ("ID" SERIAL PRIMARY KEY,
					 "Peer1" VARCHAR NOT NULL,
					 "Peer2" VARCHAR NOT NULL,
					 FOREIGN KEY ("Peer1") REFERENCES "Peers" ("Nickname"),
					 FOREIGN KEY ("Peer2") REFERENCES "Peers" ("Nickname"),
					 CHECK ("Peer1" != "Peer2"));

CREATE table "Recommendations" ("ID" SERIAL PRIMARY KEY,
							 "Peer" VARCHAR NOT NULL,
							 "RecommendedPeer" VARCHAR NOT NULL,
							 FOREIGN KEY ("Peer") REFERENCES "Peers" ("Nickname"),
							 FOREIGN KEY ("RecommendedPeer") REFERENCES "Peers" ("Nickname"),
							 CHECK ("Peer" != "RecommendedPeer"));

CREATE table "TimeTracking" ("ID" SERIAL PRIMARY KEY,
						 	"Peer" VARCHAR NOT NULL,
						  	"Date" DATE NOT NULL,
						 	"Time" TIME without time zone,
						  	"State" SMALLINT,
						  	FOREIGN KEY ("Peer") REFERENCES "Peers" ("Nickname"),
							CHECK ("State" IN (1, 2)),
							UNIQUE ("Peer", "Date", "Time"));

-- There are at least 5 records in each table

INSERT INTO "Peers" ("Nickname", "Birthday") VALUES ('maelyspe', '1976-05-19'); 
INSERT INTO "Peers" ("Nickname", "Birthday") VALUES ('cathleeb', '1993-03-17');
INSERT INTO "Peers" ("Nickname", "Birthday") VALUES ('littleca', '1990-07-14');
INSERT INTO "Peers" ("Nickname", "Birthday") VALUES ('antoneo', '1974-09-10');
INSERT INTO "Peers" ("Nickname", "Birthday") VALUES ('asajjmal', '1995-02-15');
INSERT INTO "Peers" ("Nickname", "Birthday") VALUES ('barberry', '1990-12-23');
INSERT INTO "Peers" ("Nickname", "Birthday") VALUES ('gerardba', '1985-04-03');
INSERT INTO "Peers" ("Nickname", "Birthday") VALUES ('kathyhan', '1980-10-30');

INSERT INTO "Tasks" ("Title", "ParentTask", "MaxXP") VALUES ('CPP1_s21_matrix+', NULL, 300);
INSERT INTO "Tasks" ("Title", "ParentTask", "MaxXP") VALUES ('CPP2_s21_containers', 'CPP1_s21_matrix+', 350);
INSERT INTO "Tasks" ("Title", "ParentTask", "MaxXP") VALUES ('CPP3_SmartCalc_v2.0', 'CPP2_s21_containers', 600);
INSERT INTO "Tasks" ("Title", "ParentTask", "MaxXP") VALUES ('A1_Maze', 'CPP3_SmartCalc_v2.0', 300);
INSERT INTO "Tasks" ("Title", "ParentTask", "MaxXP") VALUES ('CPP4_3DViewer_v2.0', 'CPP3_SmartCalc_v2.0', 750);
INSERT INTO "Tasks" ("Title", "ParentTask", "MaxXP") VALUES ('A2_SimpleNavigator_v1.0', 'A1_Maze', 400);
INSERT INTO "Tasks" ("Title", "ParentTask", "MaxXP") VALUES ('CPP5_3DViewer_v2.1', 'CPP4_3DViewer_v2.0', 600);
INSERT INTO "Tasks" ("Title", "ParentTask", "MaxXP") VALUES ('A3_Parallels', 'A2_SimpleNavigator_v1.0', 300);

INSERT INTO "Checks" ("Peer", "Task", "Date") VALUES ('maelyspe', 'CPP1_s21_matrix+', '2023-01-10');
INSERT INTO "Checks" ("Peer", "Task", "Date") VALUES ('barberry', 'CPP1_s21_matrix+', '2023-01-22');
INSERT INTO "Checks" ("Peer", "Task", "Date") VALUES ('asajjmal', 'A1_Maze', '2023-02-15');
INSERT INTO "Checks" ("Peer", "Task", "Date") VALUES ('littleca', 'CPP1_s21_matrix+', '2023-02-05');
INSERT INTO "Checks" ("Peer", "Task", "Date") VALUES ('maelyspe', 'CPP2_s21_containers', '2023-03-19');
INSERT INTO "Checks" ("Peer", "Task", "Date") VALUES ('cathleeb', 'CPP2_s21_containers', '2023-03-17');
INSERT INTO "Checks" ("Peer", "Task", "Date") VALUES ('littleca', 'CPP3_SmartCalc_v2.0', '2023-03-17');
INSERT INTO "Checks" ("Peer", "Task", "Date") VALUES ('asajjmal', 'CPP4_3DViewer_v2.0', '2023-03-25');
INSERT INTO "Checks" ("Peer", "Task", "Date") VALUES ('cathleeb', 'CPP3_SmartCalc_v2.0', '2023-04-30');
INSERT INTO "Checks" ("Peer", "Task", "Date") VALUES ('antoneo', 'CPP5_3DViewer_v2.1', '2023-04-25');
INSERT INTO "Checks" ("Peer", "Task", "Date") VALUES ('gerardba', 'A2_SimpleNavigator_v1.0', '2023-04-09');
INSERT INTO "Checks" ("Peer", "Task", "Date") VALUES ('maelyspe', 'CPP3_SmartCalc_v2.0', '2023-05-19');
INSERT INTO "Checks" ("Peer", "Task", "Date") VALUES ('kathyhan', 'A3_Parallels', '2023-05-09');
INSERT INTO "Checks" ("Peer", "Task", "Date") VALUES ('cathleeb', 'CPP4_3DViewer_v2.0', '2023-05-25');

INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (1, 'cathleeb', 'Start', '12:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (1, 'cathleeb', 'Success', '13:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (2, 'cathleeb', 'Start', '09:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (2, 'cathleeb', 'Failure', '10:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (3, 'littleca', 'Start', '10:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (3, 'littleca', 'Failure', '11:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (4, 'antoneo', 'Start', '22:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (4, 'antoneo', 'Success', '23:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (5, 'asajjmal', 'Start', '18:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (5, 'asajjmal', 'Success', '19:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (6, 'gerardba', 'Start', '07:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (6, 'gerardba', 'Success', '08:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (7, 'antoneo', 'Start', '14:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (7, 'antoneo', 'Success', '15:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (8, 'kathyhan', 'Start', '01:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (8, 'kathyhan', 'Failure', '02:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (9, 'maelyspe', 'Start', '22:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (9, 'maelyspe', 'Success', '23:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (10, 'maelyspe', 'Start', '17:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (10, 'maelyspe', 'Success', '18:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (11, 'kathyhan', 'Start', '05:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (11, 'kathyhan', 'Success', '06:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (12, 'littleca', 'Start', '12:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (12, 'littleca', 'Success', '13:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (13, 'gerardba', 'Start', '14:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (13, 'gerardba', 'Failure', '15:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (14, 'maelyspe', 'Start', '21:00:00');
INSERT INTO "P2P" ("Check", "CheckingPeer", "State", "Time") VALUES (14, 'maelyspe', 'Success', '22:00:00');

INSERT INTO "Verter" ("Check", "State", "Time") VALUES (1, 'Start', '13:00:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (1, 'Success', '13:20:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (4, 'Start', '23:00:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (4, 'Failure', '23:20:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (5, 'Start', '19:00:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (5, 'Success', '19:20:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (6, 'Start', '08:00:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (6, 'Success', '08:20:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (7, 'Start', '15:00:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (7, 'Success', '15:20:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (9, 'Start', '23:00:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (9, 'Success', '23:20:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (10, 'Start', '18:00:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (10, 'Success', '18:20:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (11, 'Start', '05:00:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (11, 'Failure', '06:00:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (12, 'Start', '13:00:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (12, 'Success', '13:20:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (14, 'Start', '22:00:00');
INSERT INTO "Verter" ("Check", "State", "Time") VALUES (14, 'Success', '22:20:00');

INSERT INTO "TransferredPoints" ("CheckingPeer", "CheckedPeer", "PointsAmount") VALUES ('cathleeb', 'maelyspe', 1);
INSERT INTO "TransferredPoints" ("CheckingPeer", "CheckedPeer", "PointsAmount") VALUES ('cathleeb', 'barberry', 1);
INSERT INTO "TransferredPoints" ("CheckingPeer", "CheckedPeer", "PointsAmount") VALUES ('littleca', 'asajjmal', 1);
INSERT INTO "TransferredPoints" ("CheckingPeer", "CheckedPeer", "PointsAmount") VALUES ('antoneo', 'littleca', 1);
INSERT INTO "TransferredPoints" ("CheckingPeer", "CheckedPeer", "PointsAmount") VALUES ('asajjmal', 'maelyspe', 1);
INSERT INTO "TransferredPoints" ("CheckingPeer", "CheckedPeer", "PointsAmount") VALUES ('gerardba', 'cathleeb', 1);
INSERT INTO "TransferredPoints" ("CheckingPeer", "CheckedPeer", "PointsAmount") VALUES ('antoneo', 'littleca', 1);
INSERT INTO "TransferredPoints" ("CheckingPeer", "CheckedPeer", "PointsAmount") VALUES ('kathyhan', 'asajjmal', 1);
INSERT INTO "TransferredPoints" ("CheckingPeer", "CheckedPeer", "PointsAmount") VALUES ('maelyspe', 'cathleeb', 1);
INSERT INTO "TransferredPoints" ("CheckingPeer", "CheckedPeer", "PointsAmount") VALUES ('maelyspe', 'antoneo', 1);
INSERT INTO "TransferredPoints" ("CheckingPeer", "CheckedPeer", "PointsAmount") VALUES ('kathyhan', 'gerardba', 1);
INSERT INTO "TransferredPoints" ("CheckingPeer", "CheckedPeer", "PointsAmount") VALUES ('littleca', 'maelyspe', 1);
INSERT INTO "TransferredPoints" ("CheckingPeer", "CheckedPeer", "PointsAmount") VALUES ('gerardba', 'kathyhan', 1);
INSERT INTO "TransferredPoints" ("CheckingPeer", "CheckedPeer", "PointsAmount") VALUES ('maelyspe', 'cathleeb', 1);

INSERT INTO "Friends" ("Peer1", "Peer2") VALUES ('cathleeb', 'littleca');
INSERT INTO "Friends" ("Peer1", "Peer2") VALUES ('littleca', 'maelyspe');
INSERT INTO "Friends" ("Peer1", "Peer2") VALUES ('maelyspe', 'asajjmal');
INSERT INTO "Friends" ("Peer1", "Peer2") VALUES ('maelyspe', 'cathleeb');
INSERT INTO "Friends" ("Peer1", "Peer2") VALUES ('asajjmal', 'antoneo');
INSERT INTO "Friends" ("Peer1", "Peer2") VALUES ('kathyhan', 'barberry');

INSERT INTO "Recommendations" ("Peer", "RecommendedPeer") VALUES ('maelyspe', 'littleca');
INSERT INTO "Recommendations" ("Peer", "RecommendedPeer") VALUES ('littleca', 'cathleeb');
INSERT INTO "Recommendations" ("Peer", "RecommendedPeer") VALUES ('littleca', 'asajjmal');
INSERT INTO "Recommendations" ("Peer", "RecommendedPeer") VALUES ('asajjmal', 'maelyspe');
INSERT INTO "Recommendations" ("Peer", "RecommendedPeer") VALUES ('cathleeb', 'antoneo');

INSERT INTO "XP" ("Check", "XPAmount") VALUES (1, 250);
INSERT INTO "XP" ("Check", "XPAmount") VALUES (5, 200);
INSERT INTO "XP" ("Check", "XPAmount") VALUES (6, 350);
INSERT INTO "XP" ("Check", "XPAmount") VALUES (7, 500);
INSERT INTO "XP" ("Check", "XPAmount") VALUES (9, 600);
INSERT INTO "XP" ("Check", "XPAmount") VALUES (10, 750);
INSERT INTO "XP" ("Check", "XPAmount") VALUES (12, 700);
INSERT INTO "XP" ("Check", "XPAmount") VALUES (14, 750);

INSERT INTO "TimeTracking" ("Peer", "Date", "Time", "State") VALUES ('maelyspe', '2023-01-10', '09:10:00', 1);
INSERT INTO "TimeTracking" ("Peer", "Date", "Time", "State") VALUES ('maelyspe', '2023-01-10', '15:43:00', 2);
INSERT INTO "TimeTracking" ("Peer", "Date", "Time", "State") VALUES ('cathleeb', '2021-03-23', '08:00:00', 1);
INSERT INTO "TimeTracking" ("Peer", "Date", "Time", "State") VALUES ('cathleeb', '2021-03-23', '12:34:00', 2);
INSERT INTO "TimeTracking" ("Peer", "Date", "Time", "State") VALUES ('littleca', '2023-02-04', '11:00:00', 1);
INSERT INTO "TimeTracking" ("Peer", "Date", "Time", "State") VALUES ('littleca', '2023-02-04', '15:40:00', 2);
INSERT INTO "TimeTracking" ("Peer", "Date", "Time", "State") VALUES ('littleca', '2023-02-05', '08:30:00', 1);
INSERT INTO "TimeTracking" ("Peer", "Date", "Time", "State") VALUES ('littleca', '2023-02-05', '14:50:00', 2);
INSERT INTO "TimeTracking" ("Peer", "Date", "Time", "State") VALUES ('littleca', '2023-02-05', '15:56:00', 1);
INSERT INTO "TimeTracking" ("Peer", "Date", "Time", "State") VALUES ('littleca', '2023-02-05', '19:50:00', 2);


-- The procedure for exporting data for each table to a file with the .csv extension.

CREATE OR REPLACE PROCEDURE export_table_csv(TABLE_NAME VARCHAR(50), SOURCE VARCHAR(100), DELIMITER VARCHAR(5) DEFAULT ',')
    LANGUAGE plpgsql
AS $$
BEGIN
    EXECUTE format('COPY %I TO %L WITH DELIMITER %L CSV HEADER', TABLE_NAME, SOURCE, DELIMITER);
END;
$$;


DROP PROCEDURE IF EXISTS export_table_csv CASCADE;


CALL export_table_csv('Checks', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/Checks.csv', ',');
CALL export_table_csv('Friends', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/Friends.csv', ',');
CALL export_table_csv('P2P', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/P2P.csv', ',');
CALL export_table_csv('Peers', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/Peers.csv', ',');
CALL export_table_csv('Recommendations', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/Recommendations.csv', ',');
CALL export_table_csv('Tasks', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/Tasks.csv', ',');
CALL export_table_csv('TimeTracking', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/TimeTracking.csv', ',');
CALL export_table_csv('TransferredPoints', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/TransferredPoints.csv', ',');
CALL export_table_csv('Verter', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/Verter.csv', ',');
CALL export_table_csv('XP', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/XP.csv', ',');


-- A procedure that allows you to import data for each table from a file with the .csv extension.
-- The procedure for exporting data for each table to a file with the .csv extension.

CREATE OR REPLACE PROCEDURE export_table_csv(TABLE_NAME VARCHAR(50), SOURCE VARCHAR(100), DELIMITER VARCHAR(5) DEFAULT ',');
    LANGUAGE plpgsql
AS $$
BEGIN
    EXECUTE format('COPY %I TO %L WITH DELIMITER %L CSV HEADER', TABLE_NAME, SOURCE, DELIMITER);
END;
$$;


DROP PROCEDURE IF EXISTS export_table_csv CASCADE;

CALL export_table_csv('Peers', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/Peers.csv', ',');
CALL export_table_csv('Tasks', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/Tasks.csv', ',');
CALL export_table_csv('Checks', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/Checks.csv', ',');
CALL export_table_csv('P2P', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/P2P.csv', ',');
CALL export_table_csv('Verter', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/Verter.csv', ',');
CALL export_table_csv('TransferredPoints', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/TransferredPoints.csv', ',');
CALL export_table_csv('Friends', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/Friends.csv', ',');
CALL export_table_csv('Recommendations', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/Recommendations.csv', ',');
CALL export_table_csv('XP', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/XP.csv', ',');
CALL export_table_csv('TimeTracking', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/export/TimeTracking.csv', ',');


-- A procedure that allows you to import data for each table from a file with the .csv extension.

CREATE OR REPLACE PROCEDURE import_table_csv(TABLE_NAME VARCHAR(50), SOURCE VARCHAR(100), DELIMITER VARCHAR(5) DEFAULT ',')
    LANGUAGE plpgsql
AS $$
BEGIN
    EXECUTE format('COPY %I FROM %L WITH DELIMITER %L CSV HEADER', TABLE_NAME, SOURCE, DELIMITER);
END;
$$;


DROP PROCEDURE IF EXISTS import_table_csv CASCADE;

-- Удаляем данных из таблиц для "чистого" импорта.

TRUNCATE TABLE "Peers" CASCADE;
TRUNCATE TABLE "Tasks" CASCADE;
TRUNCATE TABLE "Checks" CASCADE;
TRUNCATE TABLE "P2P" CASCADE;
TRUNCATE TABLE "Verter" CASCADE;
TRUNCATE TABLE "TransferredPoints" CASCADE;
TRUNCATE TABLE "Friends" CASCADE;
TRUNCATE TABLE "Recommendations" CASCADE;
TRUNCATE TABLE "TimeTracking" CASCADE;
TRUNCATE TABLE "XP" CASCADE;

CALL import_table_csv('Peers', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/import/Peers.csv');
CALL import_table_csv('Tasks', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/import/Tasks.csv');
CALL import_table_csv('Checks', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/import/Checks.csv');
CALL import_table_csv('P2P', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/import/P2P.csv');
CALL import_table_csv('Verter', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/import/Verter.csv');
CALL import_table_csv('TransferredPoints', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/import/TransferredPoints.csv');
CALL import_table_csv('Friends', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/import/Friends.csv');
CALL import_table_csv('Recommendations', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/import/Recommendations.csv');
CALL import_table_csv('TimeTracking', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/import/TimeTracking.csv');
CALL import_table_csv('XP', '/Users/maelyspe/Desktop/SQL2_Info21_v1.0-1/src/import/XP.csv');
