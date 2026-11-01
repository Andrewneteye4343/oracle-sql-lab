-- ============================================================
-- M10 練習：視圖與其他資料庫物件（VIEW / SEQUENCE / INDEX / 資料字典）
-- 檔名：sql/exercises/m10_views_objects_andy.sql
-- 執行：.\run-sql.ps1 -File sql\exercises\m10_views_objects_andy.sql
--
-- 【安全規則】基線 8 張表只讀不寫；本檔只在「物件」層面操作，
-- 開頭清掉舊物件、結尾再清一次，可重複執行。
-- ============================================================
SET DEFINE OFF
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK ON

-- 清理舊物件（不存在也不報錯）
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_wafer_yield';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_oos_measurements';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_lot_event_summary'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_event_id';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_pe_wafer';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_pe_lot_prefix';  EXCEPTION WHEN OTHERS THEN NULL; END;
/

PROMPT ########## M10-1：把複雜查詢包成 VIEW（每片晶圓良率） ##########
-- 建立 v_wafer_yield：wafer_id, lot_id, pass_count, fail_count, yield_pct
-- 內容就是 M8-8 那條查詢（良率百分比取 2 位小數）
-- 建立後 SELECT * FROM v_wafer_yield ORDER BY wafer_id;  預期 12 列
-- 作答區：
CREATE OR REPLACE VIEW v_wafer_yield AS
SELECT w.wafer_id, w.lot_id,
    SUM(CASE WHEN wb.pass_fail = 'P' THEN wb.die_count ELSE 0 END) AS pass_count,
    SUM(CASE WHEN wb.pass_fail = 'F' THEN wb.die_count ELSE 0 END) AS fail_count,
    ROUND(SUM(CASE WHEN wb.pass_fail = 'P' THEN wb.die_count ELSE 0 END) * 100 / SUM(wb.die_count), 2) AS yield_pct
FROM wafer_bin wb
JOIN wafer w ON wb.wafer_id = w.wafer_id
GROUP BY w.wafer_id, w.lot_id
ORDER BY w.wafer_id;

SELECT * FROM v_wafer_yield ORDER BY wafer_id;


PROMPT ########## M10-2：只讀視圖（WITH READ ONLY） ##########
-- 建立 v_oos_measurements：只放超規量測（meas_id, wafer_id, metric_name, metric_value）
-- 並加上 WITH READ ONLY
-- 預期 1 列（L-2603-02 CD_NM 13.42）
-- 作答區：
CREATE OR REPLACE VIEW v_oos_measurements AS
SELECT meas_id, wafer_id, metric_name, metric_value, spec_lower, spec_upper
FROM metrology
WHERE metric_value < spec_lower OR metric_value > spec_upper
WITH READ ONLY;

SELECT * FROM V_OOS_MEASUREMENTS ORDER BY meas_id;


PROMPT ########## M10-3：批次事件摘要視圖 ##########
-- 建立 v_lot_event_summary：lot_id, event_cnt, first_in, last_out, still_in_process
-- 提示：still_in_process = COUNT(*) - COUNT(out_ts)
-- 預期 5 列；L-2605 的 still_in_process 應為 2
-- 作答區：
CREATE OR REPLACE VIEW v_lot_event_summary AS
SELECT w.lot_id, COUNT(e.event_id) AS event_cnt,
    MIN(e.in_ts) AS first_in,
    MAX(e.out_ts) AS last_out,
    COUNT(e.event_id) - COUNT(e.out_ts) AS still_in_process
FROM process_event e
JOIN wafer w ON e.wafer_id = w.wafer_id
GROUP BY w.lot_id;

SELECT * FROM V_LOT_EVENT_SUMMARY ORDER BY lot_id;


PROMPT ########## M10-4：對複雜視圖做 DML（故意違規） ##########
-- 執行：UPDATE v_wafer_yield SET pass_count = 0 WHERE wafer_id = 'L-2601-01';
-- 記下錯誤碼，並在觀察區說明為什麼不能改
-- 作答區：
UPDATE v_wafer_yield SET pass_count = 0 WHERE wafer_id = 'L-2601-01';
-- 觀察與作答：v_wafer_yield 是一個複雜的視圖，包含聚合函數和多表聯接，因此不允許直接對其進行 DML 操作。這會導致錯誤 ORA-01732: "data manipulation operation not legal on this view"。


PROMPT ########## M10-5：SEQUENCE 基本用法 ##########
-- 建立 seq_event_id，START WITH 2000、INCREMENT BY 1、NOCACHE
-- 然後查三次 NEXTVAL（分三行列出來），再查一次 CURRVAL
-- 作答區：
CREATE SEQUENCE seq_event_id START WITH 2000 INCREMENT BY 1 NOCACHE;
SELECT seq_event_id.NEXTVAL AS nextval1 FROM dual;
SELECT seq_event_id.NEXTVAL AS nextval2 FROM dual;
SELECT seq_event_id.NEXTVAL AS nextval3 FROM dual;
SELECT seq_event_id.CURRVAL AS currval FROM dual;


PROMPT ########## M10-6：CURRVAL 的前置條件 ##########
-- 建立一個全新序列 seq_test，先直接查 CURRVAL（不先 NEXTVAL）會發生什麼？
-- 記下錯誤碼後把序列刪掉
-- 作答區：
CREATE SEQUENCE seq_test START WITH 1 INCREMENT BY 1 NOCACHE;
SELECT seq_test.CURRVAL AS currval FROM dual;
-- 觀察與作答：尚未呼叫 NEXTVAL 的序列無法使用 CURRVAL，會導致錯誤 ORA-08002: "sequence CURRVAL is not yet defined in this session"。因此，必須先呼叫 NEXTVAL 才能使用 CURRVAL。
DROP SEQUENCE seq_test;


PROMPT ########## M10-7：普通索引 ##########
-- 在 process_event(wafer_id) 上建 idx_pe_wafer
-- 建好後查 user_indexes 確認（index_name, table_name, index_type）
-- 作答區：
CREATE INDEX idx_pe_wafer ON process_event(wafer_id);
SELECT index_name, table_name, index_type FROM user_indexes WHERE index_name = 'IDX_PE_WAFER';


PROMPT ########## M10-8：函數索引 ##########
-- 在 process_event(SUBSTR(wafer_id,1,6)) 上建 idx_pe_lot_prefix
-- 這樣 WHERE SUBSTR(wafer_id,1,6) = 'L-2601' 才能用到索引
-- 建好後一樣用 user_indexes 確認
-- 作答區：
CREATE INDEX idx_pe_lot_prefix ON process_event(SUBSTR(wafer_id,1,6));
SELECT index_name, table_name, index_type FROM user_indexes WHERE index_name = 'IDX_PE_LOT_PREFIX';


PROMPT ########## M10-9：資料字典自我檢查 ##########
-- 用 user_views、user_sequences、user_indexes 列出你剛剛建立的所有物件
-- 作答區：
SELECT view_name FROM user_views WHERE view_name IN ('V_WAFER_YIELD', 'V_OOS_MEASUREMENTS', 'V_LOT_EVENT_SUMMARY');
SELECT sequence_name FROM user_sequences WHERE sequence_name IN ('SEQ_EVENT_ID', 'SEQ_TEST');
SELECT index_name FROM user_indexes WHERE index_name IN ('IDX_PE_WAFER', 'IDX_PE_LOT_PREFIX');

-- 收尾：清掉本檔建立的物件
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_wafer_yield';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_oos_measurements';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_lot_event_summary'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_event_id';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_test';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_pe_wafer';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_pe_lot_prefix';  EXCEPTION WHEN OTHERS THEN NULL; END;
/

PROMPT ########## 收尾驗證：基線列數應為 3/6/8/5/12/36/36/26 ##########
SELECT 'PRODUCT' AS TBL, COUNT(*) AS CNT FROM product
UNION ALL SELECT 'TOOL', COUNT(*) FROM tool
UNION ALL SELECT 'CHAMBER', COUNT(*) FROM chamber
UNION ALL SELECT 'LOT', COUNT(*) FROM lot
UNION ALL SELECT 'WAFER', COUNT(*) FROM wafer
UNION ALL SELECT 'PROCESS_EVENT', COUNT(*) FROM process_event
UNION ALL SELECT 'METROLOGY', COUNT(*) FROM metrology
UNION ALL SELECT 'WAFER_BIN', COUNT(*) FROM wafer_bin;

EXIT
