DROP DATABASE IF EXISTS "s21_Info21_v1.0";

CREATE DATABASE "s21_Info21_v1.2_meta"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

CREATE TABLE IF NOT EXISTS "TableName_Verter"("id" INTEGER, "name" VARCHAR)
CREATE TABLE IF NOT EXISTS "TableName_P2P"("id" INTEGER, "name" VARCHAR)
CREATE TABLE IF NOT EXISTS "TableName_Friends"("id" INTEGER, "name" VARCHAR)
CREATE TABLE IF NOT EXISTS "Friends"("id" INTEGER, "name" VARCHAR)
CREATE TABLE IF NOT EXISTS "P2P"("id" INTEGER, "name" VARCHAR)
CREATE TABLE IF NOT EXISTS "Verter"("id" INTEGER, "name" VARCHAR)







-- 1. Хранимая процедура для удаления таблиц, начинающихся с фразы 'TableName':
CREATE OR REPLACE PROCEDURE drop_tables_with_prefix(prefix VARCHAR)
AS
    statement TEXT;
BEGIN
    FOR statement IN
        SELECT 'DROP TABLE IF EXISTS ' || table_name || ' CASCADE;'
        FROM information_schema.tables
        WHERE table_schema = current_schema()
            AND table_name LIKE prefix || '%'
    LOOP
        EXECUTE statement;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 2. Хранимая процедура с выходным параметром, которая выводит список имен и параметров всех скалярных SQL функций пользователя в текущей базе данных.
CREATE OR REPLACE PROCEDURE get_scalar_function_info(OUT num_functions INTEGER)
AS
    function_info RECORD;
    function_name TEXT;
BEGIN
    num_functions := 0;
    FOR function_info IN
        SELECT p.proname, pg_get_function_arguments(p.oid) AS parameters
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = current_schema() AND p.prorettype <> 'pg_catalog.cstring'::regtype
    LOOP
        function_name := function_info.proname || function_info.parameters;
        IF function_name NOT LIKE '%(%' THEN
            CONTINUE;
        END IF;
        num_functions := num_functions + 1;
        RAISE NOTICE 'Function: %', function_name;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- 3 Хранимая процедура с выходным параметром, которая уничтожает все SQL DML триггеры в текущей базе данных. Выходной параметр возвращает количество уничтоженных триггеров.
CREATE OR REPLACE PROCEDURE drop_dml_triggers(OUT num_triggers INTEGER)
AS
    trigger_info RECORD;
    trigger_name TEXT;
BEGIN
    num_triggers := 0;
    FOR trigger_info IN
        SELECT trigger_name
        FROM information_schema.triggers
        WHERE trigger_schema = current_schema() AND event_object_table IS NOT NULL
    LOOP
        trigger_name := trigger_info.trigger_name;
        EXECUTE 'DROP TRIGGER IF EXISTS ' || trigger_name || ' ON ' || trigger_info.event_object_table || ';';
        num_triggers := num_triggers + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Хранимая процедура с входным параметром, которая выводит имена и описания типа объектов (только хранимых процедур и скалярных функций), в тексте которых на языке SQL встречается строка, задаваемая параметром процедуры.
CREATE OR REPLACE PROCEDURE search_objects_by_string(search_string TEXT, OUT num_objects INTEGER)
AS
    object_info RECORD;
    object_name TEXT;
    object_description TEXT;
BEGIN
    num_objects := 0;
    FOR object_info IN
        SELECT p.proname AS object_name, pd.description AS object_description
        FROM pg_proc p
        LEFT JOIN pg_description pd ON p.oid = pd.objoid
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = current_schema() AND p.prosrc ILIKE '%' || search_string || '%'
    LOOP
        object_name := object_info.object_name;
        object_description := COALESCE(object_info.object_description, 'No description available');
        num_objects := num_objects + 1;
        RAISE NOTICE 'Object: %, Description: %', object_name, object_description;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
