-- ============================================================
-- M3 練習：限制與排序資料（WHERE / ORDER BY）
-- 檔名：sql/exercises/m03_where_order_andy.sql
-- 執行：.\run-sql.ps1 -File sql\exercises\m03_where_order_andy.sql
-- 規則：SQL 寫在「作答區」，不要刪題目註解
-- 注意：本檔已有 SET DEFINE OFF，所以 & 不會被 sqlplus 當成替代變數
-- ============================================================
SET DEFINE OFF
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK OFF

PROMPT ########## M3-1：priority 是 HOT 或 SUPER 的批次 ##########
-- 輸出：lot_id, priority　預期 2 筆
-- 提示：IN 或 OR
-- 作答區：
SELECT lot_id, priority FROM LOT
WHERE priority IN ('HOT', 'SUPER');


PROMPT ########## M3-2：qty_wafers 介於 2 到 3（含邊界） ##########
-- 輸出：lot_id, qty_wafers　預期 5 筆
-- 提示：BETWEEN ... AND ...
-- 作答區：
SELECT lot_id, qty_wafers FROM LOT
WHERE qty_wafers BETWEEN 2 AND 3;

PROMPT ########## M3-3：lot_id 符合兩個樣式 ##########
-- (a) 以 L-26 開頭　(b) 第 5 個字元是 3（用 _ 萬用字元）　各幾筆？
-- 作答區：
SELECT lot_id FROM LOT
WHERE lot_id LIKE 'L-26%';

SELECT lot_id FROM LOT
WHERE lot_id LIKE '____3%';

PROMPT ########## M3-4：out_ts 是 NULL 的加工事件 ##########
-- 輸出：event_id, wafer_id, step_name　預期 2 筆
-- 作答區：
SELECT event_id, wafer_id, step_name FROM PROCESS_EVENT
WHERE out_ts IS NULL;

PROMPT ########## M3-5：超出規格的量測 ##########
-- 條件：metric_value > spec_upper 或 metric_value < spec_lower
-- 輸出：meas_id, wafer_id, metric_name, metric_value, spec_upper　預期 1 筆
-- 作答區：
SELECT meas_id, wafer_id, metric_name, metric_value, spec_upper FROM METROLOGY
WHERE (metric_value > spec_upper) OR (metric_value < spec_lower);

PROMPT ########## M3-6：L-2601 這一堆 slot_no >= 2 的晶圓 ##########
-- 輸出：wafer_id, slot_no　預期 2 筆
-- 注意：兩個條件要用 AND
-- 作答區：
SELECT wafer_id, slot_no FROM WAFER
WHERE lot_id = 'L-2601' AND slot_no >= 2;

PROMPT ########## M3-7：多鍵排序 ##########
-- 依 priority 升冪排，priority 相同時依 lot_id 降冪
-- 輸出：lot_id, priority, qty_wafers
-- 作答區：
SELECT lot_id, priority, qty_wafers FROM LOT
ORDER BY priority ASC, lot_id DESC;

PROMPT ########## M3-8：ORDER BY 的三種寫法 ##########
-- (a) 用欄位名 (b) 用 SELECT 的別名 (c) 用欄位位置編號
-- 三者對 qty_wafers 排序的結果要完全相同
-- 作答區：
SELECT lot_id, qty_wafers AS wafers FROM LOT
ORDER BY qty_wafers;

PROMPT ########## M3-9：時間範圍的邊界陷阱 ##########
-- (a) 先寫 WHERE in_ts BETWEEN DATE '2026-08-20' AND DATE '2026-08-22' → 數幾筆？
-- (b) 再寫「8/20 起、不到 8/23」的半開區間 → 數幾筆？
-- 在下面的觀察區說明為什麼 (a) 比較少
-- 作答區：
SELECT * FROM PROCESS_EVENT
WHERE in_ts BETWEEN DATE '2026-08-20' AND DATE '2026-08-22';
-- 觀察與作答：
SELECT * FROM PROCESS_EVENT
WHERE in_ts >= DATE '2026-08-20' AND in_ts < DATE '2026-08-23';


PROMPT ########## M3-10：NULL 不能用 = 比較 ##########
-- (a) WHERE out_ts = NULL 會幾筆？ (b) WHERE out_ts IS NULL 會幾筆？
-- 在觀察區用一句話說明
-- 作答區：
SELECT * FROM PROCESS_EVENT
WHERE out_ts = NULL;

SELECT * FROM PROCESS_EVENT
WHERE out_ts IS NULL;
-- 觀察與作答：

EXIT
