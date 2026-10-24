-- ============================================================
-- 看整個資料庫長什麼樣：資料表、欄位、外鍵關係、樣本資料
-- 執行：.\run-sql.ps1 -File sql\show_schema.sql
-- ============================================================
SET LINESIZE 200
SET PAGESIZE 300
SET FEEDBACK OFF
COLUMN table_name FORMAT A16
COLUMN column_name FORMAT A22
COLUMN data_type FORMAT A14
COLUMN nullable FORMAT A3
COLUMN fk FORMAT A34

PROMPT ===== [1] 資料表與列數 =====
SELECT 'PRODUCT'       AS table_name, COUNT(*) AS row_cnt FROM product
UNION ALL SELECT 'TOOL',          COUNT(*) FROM tool
UNION ALL SELECT 'CHAMBER',       COUNT(*) FROM chamber
UNION ALL SELECT 'LOT',           COUNT(*) FROM lot
UNION ALL SELECT 'WAFER',         COUNT(*) FROM wafer
UNION ALL SELECT 'PROCESS_EVENT', COUNT(*) FROM process_event
UNION ALL SELECT 'METROLOGY',     COUNT(*) FROM metrology
UNION ALL SELECT 'WAFER_BIN',     COUNT(*) FROM wafer_bin
ORDER BY 1;

PROMPT ===== [2] 每張表的欄位（名稱／型別／可為 NULL／預設值） =====
SELECT table_name, column_id, column_name, data_type,
       CASE WHEN nullable = 'Y' THEN 'YES' ELSE 'NO' END AS nullable,
       data_length, data_precision, data_scale, data_default
FROM   user_tab_columns
ORDER  BY table_name, column_id;

PROMPT ===== [3] 主鍵與外鍵關係（誰指向誰） =====
SELECT c.table_name, c.constraint_type AS tp, c.constraint_name,
       cc.column_name
     , CASE WHEN c.constraint_type = 'R' THEN
         (SELECT r.table_name || '.' || rcc.column_name
          FROM   user_constraints r
                 JOIN user_cons_columns rcc ON rcc.constraint_name = r.constraint_name
          WHERE  r.constraint_name = c.r_constraint_name AND rcc.position = cc.position)
       END AS references_to
FROM   user_constraints c
       JOIN user_cons_columns cc ON cc.constraint_name = c.constraint_name
WHERE  c.constraint_type IN ('P','R')
ORDER  BY c.table_name, c.constraint_type DESC, c.constraint_name, cc.position;

PROMPT ===== [4] 樣本資料（每張表前 5 列） =====
PROMPT --- product ---
SELECT * FROM product WHERE ROWNUM <= 5;
PROMPT --- tool ---
SELECT * FROM tool WHERE ROWNUM <= 5;
PROMPT --- chamber ---
SELECT * FROM chamber WHERE ROWNUM <= 5;
PROMPT --- lot ---
SELECT * FROM lot WHERE ROWNUM <= 5;
PROMPT --- wafer ---
SELECT * FROM wafer WHERE ROWNUM <= 5;
PROMPT --- process_event（晶圓履歷） ---
SELECT * FROM process_event WHERE ROWNUM <= 5;
PROMPT --- metrology ---
SELECT * FROM metrology WHERE ROWNUM <= 5;
PROMPT --- wafer_bin ---
SELECT * FROM wafer_bin WHERE ROWNUM <= 5;
