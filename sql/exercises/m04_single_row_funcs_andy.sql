-- ============================================================
-- M4 練習：單列函數（字元 / 數字 / 日期）
-- 檔名：sql/exercises/m04_single_row_funcs_andy.sql
-- 執行：.\run-sql.ps1 -File sql\exercises\m04_single_row_funcs_andy.sql
-- 規則：SQL 寫在「作答區」；涉及 SYSDATE 的題目結果會隨日期變動，不要當固定值
-- ============================================================
SET DEFINE OFF
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK OFF

PROMPT ########## M4-1：大小寫函數 ##########
-- product_name 轉大寫別名 UP_NAME、product_family 轉小寫別名 LOW_FAMILY、
-- technology_node 用 INITCAP 別名 NODE_IC
-- 作答區：
SELECT product_name, UPPER(product_name) AS UP_NAME,
    product_family, LOWER(product_family) AS LOW_FAMILY,
    technology_node, INITCAP(technology_node) AS NODE_IC
    FROM PRODUCT;


PROMPT ########## M4-2：LENGTH 與 SUBSTR ##########
-- 列出 wafer_id、LENGTH(wafer_id) 別名 LEN、SUBSTR(wafer_id, 1, 6) 別名 LOT_PART、
-- SUBSTR(wafer_id, -2) 別名 SLOT_PART（前 5 列即可，用 WHERE ROWNUM <= 5）
-- 作答區：
SELECT wafer_id, LENGTH(wafer_id) AS LEN,
    SUBSTR(wafer_id, 1, 6) AS LOT_PART,
    SUBSTR(wafer_id, -2) AS SLOT_PART
    FROM WAFER
    WHERE ROWNUM <= 5;

PROMPT ########## M4-3：INSTR 找分隔符位置 ##########
-- 列出 wafer_id 與 INSTR(wafer_id,'-') 別名 FIRST_DASH，
-- 再用 INSTR(wafer_id,'-',5) 找第二個連字號 別名 SECOND_DASH（前 5 列）
-- 作答區：
SELECT wafer_id, INSTR(wafer_id, '-') AS FIRST_DASH,
    INSTR(wafer_id, '-', 5) AS SECOND_DASH
    FROM WAFER
    WHERE ROWNUM <= 5;

PROMPT ########## M4-4：LPAD 補零 ##########
-- 把 slot_no 補成 3 位數字字串，別名 SLOT3（前 5 列）
-- 作答區：
SELECT slot_no, LPAD(slot_no, 3, '0') AS SLOT3
    FROM WAFER
    WHERE ROWNUM <= 5;

PROMPT ########## M4-5：數字函數 ##########
-- 對 metrology 的 metric_value 產生四個欄位：原值、ROUND(...,1)、TRUNC(...,1)、ROUND(...,0)
-- 用 WHERE ROWNUM <= 6 限制列數
-- 作答區：
SELECT metric_value, ROUND(metric_value, 1) AS ROUND_1,
    TRUNC(metric_value, 1) AS TRUNC_1,
    ROUND(metric_value, 0) AS ROUND_0
    FROM METROLOGY
    WHERE ROWNUM <= 6;

PROMPT ########## M4-6：日期函數 ##########
-- 列出 lot_id、wafer_start_ts、ADD_MONTHS(wafer_start_ts, 1)、LAST_DAY(wafer_start_ts)
-- 作答區：
SELECT lot_id, wafer_start_ts, ADD_MONTHS(wafer_start_ts, 1) AS NEXT_MONTH,
    LAST_DAY(wafer_start_ts) AS LAST_DAY_OF_MONTH
    FROM LOT;

PROMPT ########## M4-7：日期相差 ##########
-- 用 MONTHS_BETWEEN(SYSDATE, wafer_start_ts) 算每個批次從投片至今幾個月，別名 AGE_MONTHS
-- 作答區：
-- 觀察（會隨執行日期變動，請說明為什麼）：
SELECT lot_id, wafer_start_ts, MONTHS_BETWEEN(SYSDATE, wafer_start_ts) AS AGE_MONTHS
    FROM LOT;

PROMPT ########## M4-8：巢狀函數 ##########
-- 用 UPPER(SUBSTR(product_name, 1, 5)) 取前五個字元並轉大寫，別名 SHORT_NAME
-- 作答區：
SELECT product_name, UPPER(SUBSTR(product_name, 1, 5)) AS SHORT_NAME
    FROM PRODUCT;
EXIT
