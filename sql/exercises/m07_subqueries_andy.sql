-- ============================================================
-- M7 練習：子查詢（Subquery）
-- 檔名：sql/exercises/m07_subqueries_andy.sql
-- 執行：.\run-sql.ps1 -File sql\exercises\m07_subqueries_andy.sql
-- 目標：先算出一個數字，再拿它去篩資料（良率分析的核心招式）
-- ============================================================
SET DEFINE OFF
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK OFF

PROMPT ########## M7-1：單列子查詢（先算平均再比較） ##########
-- 找出 qty_wafers 大於「全部批次平均值」的批次（lot_id, qty_wafers）
-- 作答區：
SELECT lot_id, qty_wafers
FROM lot
WHERE qty_wafers > (SELECT AVG(qty_wafers) FROM lot);

PROMPT ########## M7-2：把子查詢結果也顯示出來 ##########
-- 同時列出每個批次的 qty_wafers 與 (SELECT AVG(qty_wafers) FROM lot) 別名 AVG_QTY
-- 作答區：
SELECT lot_id, qty_wafers, (SELECT AVG(qty_wafers) FROM lot) AS AVG_QTY
FROM lot;

PROMPT ########## M7-3：IN 子查詢（跨表） ##########
-- 找出屬於 priority = 'SUPER' 批次的晶圓（wafer_id, lot_id）
-- 作答區：
SELECT wafer_id, lot_id
FROM wafer
WHERE lot_id IN (SELECT lot_id FROM lot WHERE priority = 'SUPER');

PROMPT ########## M7-4：多列子查詢搭配 =（故意違規） ##########
-- 執行：SELECT lot_id FROM lot WHERE qty_wafers = (SELECT qty_wafers FROM lot);
-- 記下錯誤碼，並在觀察區說明為什麼、怎麼改（改用 IN）
-- 作答區：
SELECT lot_id
FROM lot
WHERE qty_wafers = (SELECT qty_wafers FROM lot);

SELECT lot_id
FROM lot
WHERE qty_wafers IN (SELECT qty_wafers FROM lot);
-- 觀察與作答：


PROMPT ########## M7-5：子查詢回傳 NULL 會發生什麼 ##########
-- 執行：SELECT lot_id FROM lot
--       WHERE qty_wafers > (SELECT MAX(qty_wafers) FROM lot WHERE priority = 'NOPE');
-- 結果幾筆？會不會報錯？在觀察區解釋
-- 作答區：
SELECT lot_id
FROM lot
WHERE qty_wafers > (SELECT MAX(qty_wafers) FROM lot WHERE priority = 'NOPE');
-- 觀察與作答：


PROMPT ########## M7-6：NOT IN 的 NULL 陷阱（對照實驗） ##########
-- (a) SELECT lot_id FROM lot
--     WHERE lot_id NOT IN (SELECT DISTINCT SUBSTR(wafer_id,1,6) FROM process_event);
-- (b) 同上，但子查詢改成 (SELECT ... UNION ALL SELECT NULL FROM dual)
-- 兩者結果差多少？在觀察區說明原因
-- 作答區：
SELECT lot_id
FROM lot
WHERE lot_id NOT IN (SELECT DISTINCT SUBSTR(wafer_id,1,6) FROM process_event);

SELECT lot_id
FROM lot
WHERE lot_id NOT IN (SELECT DISTINCT SUBSTR(wafer_id,1,6) FROM process_event UNION ALL SELECT NULL FROM dual);
-- 觀察與作答：


PROMPT ########## M7-7：ANY 與 ALL ##########
-- (a) qty_wafers > ANY (SELECT qty_wafers FROM lot WHERE priority='NORMAL') 幾筆？
-- (b) qty_wafers > ALL (SELECT qty_wafers FROM lot WHERE priority='NORMAL') 幾筆？
-- 在觀察區寫：> ANY 等於大於什麼？> ALL 等於大於什麼？
-- 作答區：
SELECT lot_id
FROM lot
WHERE qty_wafers > ANY (SELECT qty_wafers FROM lot WHERE priority = 'NORMAL');

SELECT lot_id
FROM lot
WHERE qty_wafers > ALL (SELECT qty_wafers FROM lot WHERE priority = 'NORMAL');
-- 觀察與作答：


PROMPT ########## M7-8：FROM 子句裡的子查詢（inline view） ##########
-- 先算出每個批次的平均事件數，再從中找出事件數最多的批次
-- 提示：外層查詢別名為 t
-- 作答區：
SELECT t.lot_id, t.event_count
FROM (
       SELECT SUBSTR(wafer_id,1,6) AS lot_id, COUNT(*) AS event_count
       FROM process_event
       GROUP BY SUBSTR(wafer_id,1,6)
     ) t
WHERE t.event_count = (
       SELECT MAX(c.event_count)
       FROM ( SELECT COUNT(*) AS event_count
              FROM process_event
              GROUP BY SUBSTR(wafer_id,1,6) ) c
     );

PROMPT ########## M7-9：EXISTS ##########
-- 找出「事件數 > 8」的批次以外的批次，方法用 NOT EXISTS
-- 作答區：
SELECT l.lot_id
FROM lot l
WHERE NOT EXISTS (
    SELECT 1
    FROM process_event e
    WHERE SUBSTR(e.wafer_id,1,6) = l.lot_id
    GROUP BY SUBSTR(e.wafer_id,1,6)
    HAVING COUNT(*) > 8
);

PROMPT ########## M7-10：相關子查詢（correlated subquery） ##########
-- 找出比「同一批次內平均」還要慢出站的 event（用相關係數：e.wafer_id 與外層批次對應）
-- 提示：inner 用 AVG(ou.dur) 不現實，改用 step_no 做比較：
--   找出每個批次中 step_no 大於「該批次平均 step_no」的 event
-- 作答區：
SELECT e.wafer_id, e.step_no
FROM process_event e
WHERE e.step_no > (
    SELECT AVG(o.step_no)
    FROM process_event o
    WHERE SUBSTR(o.wafer_id,1,6) = SUBSTR(e.wafer_id,1,6)
);
EXIT
