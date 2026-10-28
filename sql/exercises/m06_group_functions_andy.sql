-- ============================================================
-- M6 練習：群組函數（GROUP BY / HAVING）
-- 檔名：sql/exercises/m06_group_functions_andy.sql
-- 執行：.\run-sql.ps1 -File sql\exercises\m06_group_functions_andy.sql
-- 目標：第一次做出產線真正要的報表（每批幾片、每站幾筆、最早最晚時間）
-- ============================================================
SET DEFINE OFF
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK OFF

PROMPT ########## M6-1：COUNT 的三種寫法 ##########
-- 對 process_event 同時產生：COUNT(*) 別名 C_ALL、COUNT(out_ts) 別名 C_OUT、
-- COUNT(DISTINCT wafer_id) 別名 C_WAFER
-- 在觀察區說明三者為什麼不同
-- 作答區：
SELECT COUNT(*) AS C_ALL, COUNT(out_ts) AS C_OUT, COUNT(DISTINCT wafer_id) AS C_WAFER
FROM process_event;
-- 觀察與作答：


PROMPT ########## M6-2：每個批次有幾片晶圓 ##########
-- 從 wafer 表，依 lot_id 分組，數片數 別名 WAFER_CNT，依 lot_id 排序
-- 作答區：
SELECT lot_id, COUNT(*) AS WAFER_CNT
FROM wafer
GROUP BY lot_id
ORDER BY lot_id;

PROMPT ########## M6-3：每個站別有幾筆事件 ##########
-- 依 step_name 分組，COUNT(*)
-- 作答區：
SELECT step_name, COUNT(*) AS EVENT_CNT
FROM process_event
GROUP BY step_name
ORDER BY step_name;

PROMPT ########## M6-4：GROUP BY 放函數運算式 ##########
-- 用 SUBSTR(wafer_id,1,6) 當批次代號分組，數每個批次的事件數
-- 作答區：
SELECT SUBSTR(wafer_id,1,6) AS LOT_ID, COUNT(*) AS EVENT_CNT
FROM process_event
GROUP BY SUBSTR(wafer_id,1,6)
ORDER BY LOT_ID;

PROMPT ########## M6-5：單峰統計 ##########
-- 對 metrology 全表：MIN、MAX、AVG(metric_value)，AVG 取到小數 4 位
-- 作答區：
SELECT MIN(metric_value) AS MIN_VALUE, MAX(metric_value) AS MAX_VALUE, ROUND(AVG(metric_value),4) AS AVG_VALUE
FROM METROLOGY;

PROMPT ########## M6-6：WHERE 與 HAVING 的分工 ##########
-- (a) 先 WHERE out_ts IS NOT NULL，再依 step_name 分組 COUNT(*)
-- (b) 只列出 COUNT(*) >= 8 的 step_name（用 HAVING）
-- 在觀察區寫：什麼條件放 WHERE、什麼條件放 HAVING
-- 作答區：
SELECT step_name, COUNT(*) AS EVENT_CNT
FROM process_event
GROUP BY step_name;

SELECT step_name, COUNT(*) AS EVENT_CNT
FROM process_event
WHERE out_ts IS NOT NULL
GROUP BY step_name
HAVING COUNT(*) >= 8
ORDER BY step_name;
-- 觀察與作答：


PROMPT ########## M6-7：多欄分組 ##########
-- 依 tool_type, fab_area 分組，數機台數 別名 TOOL_CNT
-- （注意：這跟 M2-6 的 DISTINCT 結果列數要一致，但多了計數）
-- 作答區：
SELECT tool_type, fab_area, COUNT(DISTINCT tool_id) AS TOOL_CNT
FROM tool
GROUP BY tool_type, fab_area
ORDER BY tool_type, fab_area;


PROMPT ########## M6-8：每個批次的時間範圍 ##########
-- 依 SUBSTR(wafer_id,1,6) 分組，列出 MIN(in_ts) 別名 FIRST_IN、MAX(out_ts) 別名 LAST_OUT
-- 作答區：
SELECT SUBSTR(wafer_id,1,6) AS lot_id,
       MIN(in_ts)  AS first_in,
       MAX(out_ts) AS last_out,
       COUNT(*) - COUNT(out_ts) AS still_in_process   -- 1, 2 片未出站
FROM process_event
GROUP BY SUBSTR(wafer_id,1,6);


PROMPT ########## M6-9：故意違規（記下錯誤碼） ##########
-- 試著寫：SELECT lot_id, COUNT(*) FROM wafer;
-- 記下錯誤碼，然後在觀察區寫正確寫法
-- 作答區：
SELECT lot_id, COUNT(*) FROM wafer;

-- 觀察與作答：


PROMPT ########## M6-10：良率報表（綜合題） ##########
-- 從 wafer_bin 表：依 wafer_id 分組，加總 bin 數量 別名 TOTAL_BIN，
-- 只列出 TOTAL_BIN >= 1 的前幾筆（用 HAVING，並自行排序）
-- 作答區：
SELECT wafer_id, SUM(DIE_COUNT) AS TOTAL_BIN
FROM wafer_bin
GROUP BY wafer_id
HAVING SUM(DIE_COUNT) >= 1
ORDER BY wafer_id;

EXIT
