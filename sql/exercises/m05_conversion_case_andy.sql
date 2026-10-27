-- ============================================================
-- M5 練習：轉換函數與條件運算式
-- 檔名：sql/exercises/m05_conversion_case_andy.sql
-- 執行：.\run-sql.ps1 -File sql\exercises\m05_conversion_case_andy.sql
-- 規則：SQL 寫在「作答區」；遇錯先抄下錯誤碼再修，錯誤碼本身就是教材
-- ============================================================
SET DEFINE OFF
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK OFF

PROMPT ########## M5-1：隱式轉換（故意製造錯誤） ##########
-- (a) SELECT '123' + 1 AS implicit_ok FROM dual;
-- (b) SELECT 'abc' + 1 AS implicit_fail FROM dual;   <- 記下錯誤碼
-- 在觀察區寫：為什麼 Oracle 允許 (a) 卻拒絕 (b)？隱式轉換靠什麼判斷？
-- 作答區：
SELECT '123' + 1 AS implicit_ok FROM dual;
SELECT 'abc' + 1 AS implicit_fail FROM dual;
-- 觀察與作答：


PROMPT ########## M5-2：TO_CHAR 的數字格式 ##########
-- 對 metrology 前 6 列，列出 metric_value 與 TO_CHAR(metric_value,'990.99') 別名 FMT
-- 作答區：
SELECT metric_value, TO_CHAR(metric_value, '990.99') AS FMT
FROM metrology
WHERE ROWNUM <= 6;

PROMPT ########## M5-3：TO_CHAR 的日期格式 ##########
-- 列出 lot_id 與 TO_CHAR(wafer_start_ts,'YYYY/MM/DD HH24:MI:SS DAY') 別名 START_FMT
-- 作答區：
SELECT lot_id, TO_CHAR(wafer_start_ts, 'YYYY/MM/DD HH24:MI:SS DAY') AS START_FMT
FROM LOT;

PROMPT ########## M5-4：TO_DATE 與時間範圍 ##########
-- 用 TO_DATE 表達「2026-08-20 00:00:00 起、2026-08-23 00:00:00 之前」的 in_ts
-- 列出 event_id 與 in_ts　預期 9 筆
-- 作答區：
SELECT event_id, in_ts
FROM process_event
WHERE in_ts >= TO_DATE('2026-08-20 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
    AND in_ts < TO_DATE('2026-08-23 00:00:00', 'YYYY-MM-DD HH24:MI:SS');

PROMPT ########## M5-5：NVL 的型別陷阱 ##########
-- (a) 先跑：SELECT event_id, NVL(out_ts,'IN PROGRESS') FROM process_event WHERE out_ts IS NULL;
--     記下錯誤碼。
-- (b) 再改成 TO_CHAR 版本，讓 1033、1036 顯示 IN PROGRESS　預期 2 筆
-- 作答區：
SELECT event_id, NVL(out_ts, 'IN_PROGRESS') AS status
FROM process_event
WHERE out_ts IS NULL;

SELECT event_id, (NVL(TO_CHAR(out_ts), 'IN_PROGRESS')) AS status
FROM process_event
WHERE out_ts IS NULL;
-- 觀察與作答（為什麼 NVL 會失敗、怎麼修）：


PROMPT ########## M5-6：NVL2 ##########
-- 用 NVL2(out_ts,'DONE','RUNNING') 產生旗標 別名 STATE，列出 event_id, out_ts, STATE
-- 只要前 3 列與 1033、1036 這兩筆（分兩次查或挑條件）
-- 作答區：
SELECT event_id, out_ts, NVL2(out_ts, 'DONE', 'RUNNING') AS STATE
FROM process_event
WHERE ROWNUM <= 3 OR event_id IN (1033, 1036);


PROMPT ########## M5-7：COALESCE ##########
-- COALESCE(out_ts, in_ts) 別名 LAST_TS：有出站就用 out_ts，NULL 則退回 in_ts
-- 列出 event_id, LAST_TS　預期 2 筆的 LAST_TS 等於 in_ts
-- 作答區：
SELECT event_id, COALESCE(out_ts, in_ts) AS LAST_TS
FROM process_event
WHERE out_ts IS NULL;

PROMPT ########## M5-8：CASE（簡單式） ##########
-- priority 轉中文：HOT->急件, SUPER->特急, 其他->一般　別名 PRIORITY_ZH
-- 列出 lot_id, priority, PRIORITY_ZH
-- 作答區：
SELECT lot_id, priority,
    CASE priority
        WHEN 'HOT' THEN '急件'
        WHEN 'SUPER' THEN '特急'
        ELSE '一般'
    END AS PRIORITY_ZH
FROM lot;


PROMPT ########## M5-9：DECODE（Oracle 專有，做同一件事） ##########
-- 用 DECODE 產生與 M5-8 相同的 PRIORITY_ZH，比較兩個寫法的行數差異
-- 作答區：
SELECT lot_id, priority,
    DECODE(priority,
        'HOT', '急件',
        'SUPER', '特急',
        '一般') AS PRIORITY_ZH
FROM lot;


PROMPT ########## M5-10：NULLIF ##########
-- NULLIF(step_no, 10)：step_no 等於 10 時回 NULL，否則回原值 別名 STEP_NULLIF
-- 列出 event_id, step_no, STEP_NULLIF（前 6 列）
-- 作答區：
-- 觀察（NULLIF 與 CASE 的等價寫法是什麼）：
SELECT event_id, step_no, NULLIF(step_no, 10) AS STEP_NULLIF
FROM process_event
WHERE ROWNUM <= 6;

PROMPT ########## M5-11：RR 與 YY 的世紀規則 ##########
-- SELECT TO_CHAR(TO_DATE('01-01-51','DD-MM-RR'),'YYYY') AS RR_YEAR,
--        TO_CHAR(TO_DATE('01-01-51','DD-MM-YY'),'YYYY') AS YY_YEAR FROM dual;
-- 在觀察區寫：兩者為何差 100 年？判斷依據是什麼？
-- 作答區：
SELECT TO_CHAR(TO_DATE('01-01-51','DD-MM-RR'),'YYYY') AS RR_YEAR,
    TO_CHAR(TO_DATE('01-01-51','DD-MM-YY'),'YYYY') AS YY_YEAR;
-- 觀察與作答：

EXIT
