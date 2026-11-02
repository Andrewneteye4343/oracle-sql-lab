-- ============================================================
-- M12 練習：資料字典與執行計畫（收尾章）
-- 檔名：sql/exercises/m12_dictionary_plan_andy.sql
-- 執行：.\run-sql.ps1 -File sql\exercises\m12_dictionary_plan_andy.sql
-- 全部唯讀；EXPLAIN PLAN 只寫入 PLAN_TABLE，不影響業務資料。
-- ============================================================
SET DEFINE OFF
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK ON

PROMPT ########## M12-1：我在哪個容器、哪個 schema ##########
-- 列出 USER、SYS_CONTEXT('USERENV','CON_NAME')、SYS_CONTEXT('USERENV','SERVICE_NAME')
-- 作答區：
SELECT USER, SYS_CONTEXT('USERENV','CON_NAME') AS CONTAINER, SYS_CONTEXT('USERENV','SERVICE_NAME') AS SERVICE FROM DUAL;

PROMPT ########## M12-2：USER_ / ALL_ / DBA_ 三層差異 ##########
-- 分別數 USER_TABLES、ALL_TABLES 的筆數，並說明為什麼不同
-- 作答區：
SELECT COUNT(*) AS USER_TABLES_COUNT FROM USER_TABLES;
SELECT COUNT(*) AS ALL_TABLES_COUNT FROM ALL_TABLES;
-- 觀察與作答：USER_TABLES只顯示目前使用者擁有的表，而ALL_TABLES則顯示使用者有權限訪問的所有表，包括其他使用者的表，因此筆數可能不同。


PROMPT ########## M12-3：我的表與欄位數 ##########
-- 用 USER_TABLES 與 USER_TAB_COLUMNS 列出每張表的欄位數，依表名排序
-- 作答區：
SELECT t.table_name, COUNT(c.column_name) AS column_count
FROM USER_TABLES t
JOIN USER_TAB_COLUMNS c ON t.table_name = c.table_name
GROUP BY t.table_name
ORDER BY t.table_name;

PROMPT ########## M12-4：欄位型別驗證（回填 M5 的疑問） ##########
-- 查 USER_TAB_COLUMNS 中 process_event 的 in_ts / out_ts 型別
-- 作答區：
SELECT column_name, data_type, data_length, data_precision, data_scale
FROM USER_TAB_COLUMNS
WHERE table_name = 'PROCESS_EVENT' AND column_name IN ('IN_TS', 'OUT_TS');

PROMPT ########## M12-5：約束清單（回填 M1 Q3/Q4） ##########
-- 用 USER_CONSTRAINTS 列出 constraint_name, constraint_type, table_name
-- 再數每種類型幾個（P/R/U/C）
-- 作答區：
SELECT constraint_name, constraint_type, table_name
FROM USER_CONSTRAINTS;

SELECT constraint_type, COUNT(*) AS count
FROM USER_CONSTRAINTS
GROUP BY constraint_type;

PROMPT ########## M12-6：索引與索引欄位 ##########
-- 用 USER_INDEXES + USER_IND_COLUMNS 列出所有索引、其表、欄位與唯一性
-- 作答區：
SELECT i.index_name, i.table_name, i.uniqueness, ic.column_name
FROM USER_INDEXES i
JOIN USER_IND_COLUMNS ic ON i.index_name = ic.index_name
ORDER BY i.index_name, ic.column_position;

PROMPT ########## M12-7：看執行計畫（全表掃描） ##########
-- EXPLAIN PLAN FOR SELECT * FROM process_event WHERE wafer_id = 'L-2601-01';
-- 再 SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- 記下 access path（TABLE ACCESS FULL 或 INDEX ...）
-- 作答區：
DELETE FROM plan_table;
COMMIT;

EXPLAIN PLAN FOR SELECT * FROM process_event WHERE wafer_id = 'L-2601-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- 觀察與作答：Predicate Information (identified by operation id): 1 - filter("WAFER_ID"='L-2601-01')


PROMPT ########## M12-8：建索引後的執行計畫 ##########
-- CREATE INDEX idx_pe_wafer ON process_event(wafer_id);
-- 再次 EXPLAIN PLAN 同一條查詢，比較 access path 有沒有變
-- 作答區：
DELETE FROM plan_table;
COMMIT;

CREATE INDEX idx_pe_wafer ON process_event(wafer_id);
EXPLAIN PLAN FOR SELECT * FROM process_event WHERE wafer_id = 'L-2601-01';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- 觀察與作答：Predicate Information (identified by operation id): 2 - access("WAFER_ID"='L-2601-01')


PROMPT ########## M12-9：函數查詢與函數索引 ##########
-- (a) EXPLAIN PLAN FOR SELECT * FROM process_event WHERE SUBSTR(wafer_id,1,6) = 'L-2601';
-- (b) CREATE INDEX idx_pe_lot_prefix ON process_event(SUBSTR(wafer_id,1,6));
-- (c) 再 EXPLAIN 同一條查詢，比較差異
-- 作答區：
EXPLAIN PLAN FOR SELECT * FROM process_event WHERE SUBSTR(wafer_id,1,6) = 'L-2601';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

CREATE INDEX idx_pe_lot_prefix ON process_event(SUBSTR(wafer_id,1,6));
EXPLAIN PLAN FOR SELECT * FROM process_event WHERE SUBSTR(wafer_id,1,6) = 'L-2601';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- 觀察與作答：Predicate Information (identified by operation id): 1 - filter(SUBSTR("WAFER_ID",1,6)='L-2601'), 1 -  SEL$1 / "PROCESS_EVENT"@"SEL$1"; Predicate Information (identified by operation id): 2 - access(SUBSTR("WAFER_ID",1,6)='L-2601'), - dynamic statistics used: dynamic sampling (level=AUTO (SYSTEM))


PROMPT ########## M12-10：收尾清理 ##########
-- DROP INDEX idx_pe_wafer; DROP INDEX idx_pe_lot_prefix;
-- 然後驗證基線列數 3/6/8/5/12/36/36/26
-- 作答區：
DROP INDEX idx_pe_wafer;
DROP INDEX idx_pe_lot_prefix;

SELECT COUNT(*) AS baseline_count FROM process_event;
EXIT
