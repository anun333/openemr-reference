-- openemr-utf8mb4.sql: prints the statements that move an OpenEMR database's old utf8 (utf8mb3)
-- tables and columns to utf8mb4, keeping each column's type, nullability, default and comment.
--
-- Sites installed before OpenEMR 6.0.0 still have utf8mb3 tables: no upgrade converts them, and
-- since OpenEMR connects as utf8mb4, an emoji or other 4-byte character written to them is saved
-- as "?". ALTER TABLE ... CONVERT TO would also widen column types (text -> mediumtext) to keep
-- their capacity in characters, so the schema would no longer match a fresh install; existing data
-- needs no wider type, since a character utf8mb3 can hold takes the same bytes in utf8mb4.
--
-- MariaDB 10.2.7 and later (it relies on MariaDB's information_schema.COLUMNS.COLUMN_DEFAULT
-- format). Back up first; each ALTER rebuilds its table, so it takes time on a large database and
-- needs free space for the largest table. Rehearse it: openemr-rehearse.sh --convert-utf8mb4.
--   mariadb -N -B -r openemr < openemr-utf8mb4.sql > convert.sql    # -r: raw, keeps quoting intact
--   (read convert.sql)
--   mariadb openemr < convert.sql
-- Each utf8mb3 collation maps to its utf8mb4 twin (utf8mb3_general_ci -> utf8mb4_general_ci).
-- Tested on a real OpenEMR 5.0.2 install upgraded to 8.5.0-dev: 230 tables, 37 s, no failures, and
-- afterwards no difference from a fresh install beyond the ones the database had before.
SET SESSION group_concat_max_len = 4194304;
SELECT CONCAT('ALTER DATABASE `', DATABASE(), '` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;')
FROM information_schema.schemata
WHERE schema_name = DATABASE() AND default_character_set_name <> 'utf8mb4'
UNION ALL
SELECT CONCAT(
    'ALTER TABLE `', t.table_name, '` DEFAULT CHARACTER SET utf8mb4 COLLATE ',
    IF(t.table_collation LIKE 'utf8mb4%', t.table_collation,
       REPLACE(REPLACE(t.table_collation, 'utf8mb3_', 'utf8mb4_'), 'utf8_', 'utf8mb4_')),
    IFNULL(CONCAT(', ', (
        SELECT GROUP_CONCAT(CONCAT(
            'MODIFY `', c.column_name, '` ', c.column_type,
            ' CHARACTER SET utf8mb4 COLLATE ', REPLACE(REPLACE(c.collation_name, 'utf8mb3_', 'utf8mb4_'), 'utf8_', 'utf8mb4_'),
            IF(c.is_nullable = 'NO', ' NOT NULL', ' NULL'),
            IF(c.column_default IS NULL, '', CONCAT(' DEFAULT ', c.column_default)),
            IF(c.column_comment = '', '', CONCAT(' COMMENT ', QUOTE(c.column_comment))))
            ORDER BY c.ordinal_position SEPARATOR ', ')
        FROM information_schema.columns c
        WHERE c.table_schema = t.table_schema AND c.table_name = t.table_name
          AND (c.collation_name LIKE 'utf8mb3\_%' OR c.collation_name LIKE 'utf8\_%'))), ''),
    ';')
FROM information_schema.tables t
WHERE t.table_schema = DATABASE() AND t.table_type = 'BASE TABLE'
  AND (t.table_collation LIKE 'utf8mb3\_%' OR t.table_collation LIKE 'utf8\_%'
       OR EXISTS (SELECT 1 FROM information_schema.columns c
                  WHERE c.table_schema = t.table_schema AND c.table_name = t.table_name
                    AND (c.collation_name LIKE 'utf8mb3\_%' OR c.collation_name LIKE 'utf8\_%')));
