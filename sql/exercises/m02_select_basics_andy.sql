-- ============================================================
-- M2 練習：用 SELECT 檢索資料
-- 檔名：sql/exercises/m02_select_basics_andy.sql
-- 執行：.\run-sql.ps1 -File sql\exercises\m02_select_basics_andy.sql
-- 規則：每題把自己的 SQL 寫在「作答區」，不要刪題目註解（我批改時要看你的答案）
-- ============================================================
SET DEFINE OFF
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK OFF
COLUMN 產品 FORMAT A16
COLUMN 節點 FORMAT A8

PROMPT ########## M2-1：列出 product 的所有欄位 ##########
-- 目的：習慣 SELECT *，並觀察欄位出現的順序（與 DDL 宣告順序一致）
-- 作答區：
SELECT * FROM product;

PROMPT ########## M2-2：只取兩欄，並用中文別名 ##########
-- 目的：product_name 顯示為「產品」、technology_node 顯示為「節點」
-- 提示：中文別名一定要用雙引號
-- 作答區：
SELECT product_name AS "產品", technology_node AS "節點" FROM PRODUCT;

PROMPT ########## M2-3：用 || 串出「Alpha SoC (N5)」這種格式 ##########
-- 目的：欄位值 + 中文字串 + 欄位值，別名 label
-- 注意：CROSS JOIN 不適用，只要一列一列串就好
-- 作答區：
SELECT product_name || ' (' || technology_node || ')' AS label FROM PRODUCT;

PROMPT ########## M2-4：別名加引號與不加引號的差別 ##########
-- 目的：先寫 tool_id AS 機台（不加引號，會失敗或出現怪結果，觀察錯誤碼），
--       再改成 tool_id AS "機台"，並列出 vendor_model AS "廠牌"
-- 作答區：
SELECT tool_id AS "機台", vendor_model AS "廠牌" FROM TOOL;

PROMPT ########## M2-5：算術運算式 ##########
-- 目的：假設每片晶圓有 25 顆 die，算每批總顆數 qty_wafers * 25，別名 total_die
-- 輸出欄位：lot_id, qty_wafers, total_die
-- 預期：L-2601=75、L-2602=50、L-2603=75、L-2604=50、L-2605=50
-- 作答區：
SELECT lot_id, qty_wafers, qty_wafers * 25 AS total_die FROM LOT;

PROMPT ########## M2-6：DISTINCT ##########
-- 目的：(a) lot 有幾種 priority？ (b) tool 的 (tool_type, fab_area) 有幾種組合？
-- 預期：(a) 3 種 (b) 4 種
-- 作答區：
SELECT COUNT(*) FROM (SELECT DISTINCT priority FROM lot);
SELECT COUNT(*) FROM (SELECT DISTINCT tool_type, fab_area FROM TOOL);

PROMPT ########## M2-7：字串裡有單引號 ##########
-- 目的：用兩種寫法產生 Andy's SQL lab（一般寫法用兩個單引號、q'[...]' 寫法各一次）
-- 作答區：
SELECT 'Andy''s SQL lab' AS label1 FROM dual;
SELECT q'[Andy's SQL lab]' AS label2 FROM dual;

PROMPT ########## M2-8：NULL 參與運算 ##########
-- 目的：列出 event_id, in_ts, out_ts, 加工時長 out_ts - in_ts（別名 dur）
--       然後回答：有幾列的 dur 是 NULL？為什麼？（兩層原因，寫在下面的註解）
-- 作答區：
SELECT event_id, in_ts, out_ts, out_ts - in_ts AS dur FROM PROCESS_EVENT;
-- 觀察與作答：

EXIT
