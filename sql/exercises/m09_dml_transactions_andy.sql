-- ============================================================
-- M9 練習：DML 與交易控制（INSERT / UPDATE / DELETE / MERGE）
-- 檔名：sql/exercises/m09_dml_transactions_andy.sql
-- 執行：.\run-sql.ps1 -File sql\exercises\m09_dml_transactions_andy.sql
--
-- 【安全規則】基線 8 張表只做「唯讀驗證」；所有寫入都在 stg_ 開頭的暫存表上做。
-- 本檔開頭會先清掉舊暫存表，結尾再清一次，可重複執行。
-- 本檔已開 SET FEEDBACK ON，你才會看到 "1 row created." / "3 rows updated."
-- ============================================================
SET DEFINE OFF
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK ON

-- 清理前次執行的暫存表（PL/SQL 動態 SQL，物件不存在也不報錯）
BEGIN EXECUTE IMMEDIATE 'DROP TABLE stg_event'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE stg_oos';   EXCEPTION WHEN OTHERS THEN NULL; END;
/

PROMPT ########## M9-1：CREATE TABLE AS SELECT（ETL 第一步） ##########
-- 用 CTAS 建立 stg_event，複製 process_event 全部 36 筆
-- 作答區：
CREATE TABLE stg_event AS SELECT * FROM process_event;

PROMPT ########## M9-2：CTAS 會隱式 COMMIT ##########
-- 在觀察區寫：CTAS 是 DDL 還是 DML？它對未提交的交易有什麼影響？
-- 作答區：DDL，會隱式 COMMIT，會把未提交的交易也一起提交
-- 觀察與作答：


PROMPT ########## M9-3：單列 INSERT ##########
-- 對 stg_event 插入一筆 event_id = 9999、wafer_id = 'L-2601-01'、step_no = 40、
-- step_name = 'TEST'、tool_id='T-CMP-01'、chamber_id=9、recipe_id='RCP-TEST'、recipe_ver=1、
-- in_ts = SYSTIMESTAMP、out_ts = NULL
-- 插入後用 SELECT COUNT(*) 確認（應該變 37）
-- 作答區：
INSERT INTO stg_event (event_id, wafer_id, step_no, step_name, tool_id, chamber_id, recipe_id, recipe_ver, in_ts, out_ts)
VALUES (9999, 'L-2601-01', 40, 'TEST', 'T-CMP-01', 9, 'RCP-TEST', 1, SYSTIMESTAMP, NULL);

SELECT COUNT(*) AS cnt
FROM stg_event;

PROMPT ########## M9-4：UPDATE 與受影響列數 ##########
-- 把 stg_event 中 step_name = 'TEST' 的那筆改成 'TEST2'
-- 看 FEEDBACK 顯示 "1 row updated."，再用 SELECT 驗證
-- 作答區：
UPDATE stg_event
SET step_name = 'TEST2'
WHERE step_name = 'TEST';

SELECT step_name
FROM stg_event
WHERE event_id = 9999;

PROMPT ########## M9-5：SAVEPOINT 與部分回滾 ##########
-- (a) SAVEPOINT sp1;
-- (b) UPDATE stg_event SET step_name = 'AAA' WHERE event_id = 1001;
-- (c) ROLLBACK TO sp1;
-- (d) SELECT step_name FROM stg_event WHERE event_id = 1001;   -> 應為原值 LITHO 的 step_name
-- 在觀察區寫：ROLLBACK TO sp1 與 ROLLBACK 的差別
-- 作答區：
SAVEPOINT sp1;

UPDATE stg_event
SET step_name = 'AAA'
WHERE event_id = 1001;

ROLLBACK TO sp1;

SELECT step_name
FROM stg_event
WHERE event_id = 1001;
-- 觀察與作答：ROLLBACK會撤掉所有交易結果；ROOLLBACK TO sp1只會撤掉sp1之後的交易結果，sp1之前的交易結果仍然保留


PROMPT ########## M9-6：交易邊界（ROLLBACK 前後對照） ##########
-- (a) DELETE FROM stg_event WHERE event_id = 9999;   然後 COUNT(*) -> 36
-- (b) ROLLBACK;
-- (c) COUNT(*) -> 應回到 37（刪除被取消）
-- 作答區：
DELETE FROM stg_event
WHERE event_id = 9999;

ROLLBACK;
SELECT COUNT(*) AS cnt
FROM stg_event;
-- 觀察與作答：


PROMPT ########## M9-7：INSERT ... SELECT（複製超規量測到暫存表） ##########
-- 建立 stg_oos：只放「超出規格」的量測，欄位含 meas_id, wafer_id, metric_name,
-- metric_value, lot_id（lot_id 先用 CAST(NULL AS VARCHAR2(12)) 佔位）
-- 預期 1 筆（L-2603-02 的 CD_NM 13.42）
-- 作答區：
CREATE TABLE stg_oos AS
SELECT m.meas_id, m.wafer_id, m.metric_name, m.metric_value,
    CAST(NULL AS VARCHAR2(12)) AS lot_id
FROM metrology m
WHERE m.metric_value < m.spec_lower OR m.metric_value > m.spec_upper;

PROMPT ########## M9-8：用相關子查詢補維度欄位 ##########
-- UPDATE stg_oos，把 lot_id 從 wafer 表查出來填上
-- 預期 "1 row updated."，lot_id 應為 L-2603
-- 作答區：
UPDATE stg_oos o
SET o.lot_id = (SELECT w.lot_id FROM wafer w WHERE w.wafer_id = o.wafer_id)
WHERE o.lot_id IS NULL;

PROMPT ########## M9-9：MERGE（UPSERT） ##########
-- 對 stg_oos 執行 MERGE：
--   來源 = (SELECT 5020 AS meas_id, 99.99 AS metric_value FROM dual)
--   目標 = stg_oos
--   當 meas_id 相符 -> UPDATE metric_value；不相符 -> INSERT（lot_id 給 'MERGED'）
-- 執行後 SELECT * FROM stg_oos 驗證
-- 作答區：
MERGE INTO stg_oos o
USING (SELECT 5020 AS meas_id, 99.99 AS metric_value FROM dual) src
ON (o.meas_id = src.meas_id)
WHEN MATCHED THEN
    UPDATE SET o.metric_value = src.metric_value
WHEN NOT MATCHED THEN
    INSERT (meas_id, wafer_id, metric_name, metric_value, lot_id)
    VALUES (src.meas_id, NULL, NULL, src.metric_value, 'MERGED');

SELECT * FROM stg_oos;

PROMPT ########## M9-10：DELETE 與 TRUNCATE 的差別（只讀觀念，不執行 TRUNCATE） ##########
-- (a) DELETE FROM stg_oos;  然後 COUNT(*) -> 0
-- (b) ROLLBACK; 再 COUNT(*) -> 回到 1 筆
-- 在觀察區寫：為什麼 DELETE 可以救回來，TRUNCATE 不行？
-- 作答區：
DELETE FROM stg_oos;
SELECT COUNT(*) AS cnt
FROM stg_oos;
ROLLBACK;

SELECT COUNT(*) AS cnt
FROM stg_oos;

-- 觀察與作答：


-- 收尾：清掉暫存表，讓基線資料回到乾淨狀態
BEGIN EXECUTE IMMEDIATE 'DROP TABLE stg_event'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE stg_oos';   EXCEPTION WHEN OTHERS THEN NULL; END;
/
PROMPT ########## 收尾驗證：基線表列數應為 3/6/8/5/12/36/36/26 ##########
SELECT 'PRODUCT' AS TBL, COUNT(*) AS CNT FROM product
UNION ALL SELECT 'TOOL', COUNT(*) FROM tool
UNION ALL SELECT 'CHAMBER', COUNT(*) FROM chamber
UNION ALL SELECT 'LOT', COUNT(*) FROM lot
UNION ALL SELECT 'WAFER', COUNT(*) FROM wafer
UNION ALL SELECT 'PROCESS_EVENT', COUNT(*) FROM process_event
UNION ALL SELECT 'METROLOGY', COUNT(*) FROM metrology
UNION ALL SELECT 'WAFER_BIN', COUNT(*) FROM wafer_bin;

EXIT
