-- ============================================================
-- M13（補充章）：視窗函數 Window Functions
-- 檔名：sql/exercises/m13_window_functions_andy.sql
-- 執行：.\run-sql.ps1 -File sql\exercises\m13_window_functions_andy.sql
--
-- 為什麼補這一章：1Z0-071 考綱不含視窗函數，但產線分析幾乎每天都在用
-- （算同機台前後兩筆間隔、每批排名、累計產量、移動平均、佔比）。
-- 全部唯讀，不會動資料。
-- ============================================================
SET DEFINE OFF
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK ON

PROMPT ########## M13-1：ROW_NUMBER 基本用法 ##########
-- 依 wafer_id 分區、step_no 排序，給每片晶圓的 event 編號
-- 列出 event_id, wafer_id, step_no, rn（依 wafer_id, step_no 排序）
-- 預期 36 列，每片晶圓的 rn 是 1,2,3
-- 作答區：
SELECT event_id, wafer_id, step_no, ROW_NUMBER() OVER (PARTITION BY wafer_id ORDER BY step_no) AS rn
FROM process_event
ORDER BY wafer_id, step_no;

PROMPT ########## M13-2：每批次「最後出站」的那一筆（Top-N per group） ##########
-- 用 ROW_NUMBER() OVER (PARTITION BY 批次 ORDER BY out_ts DESC NULLS LAST) 取 rn = 1
-- 批次 = SUBSTR(wafer_id,1,6)
-- 預期 5 列（每批次一列）；注意 L-2605 的兩筆 NULL out_ts 要怎麼處理
-- 提示：視窗函數不能寫在 WHERE，要用子查詢或 CTE
-- 作答區：
SELECT event_id, wafer_id, step_no, out_ts
FROM (
    SELECT event_id, wafer_id, step_no, out_ts, ROW_NUMBER() OVER (PARTITION BY SUBSTR(wafer_id,1,6) ORDER BY out_ts DESC NULLS LAST) AS rn
    FROM process_event
)
WHERE rn = 1
ORDER BY wafer_id;

PROMPT ########## M13-3：ROW_NUMBER vs RANK vs DENSE_RANK ##########
-- 對全部 event 依 step_no 排名，三種函數一次列出
-- 列出 event_id, step_no, ROW_NUMBER/RANK/DENSE_RANK 三個別名（前 8 列，依 event_id）
-- 在觀察區寫：三者對「同分」的處理差異，以及 step_no = 20 的 RANK 值為什麼是 13
-- 作答區：
SELECT event_id, step_no,
    ROW_NUMBER() OVER (ORDER BY step_no) AS rn,
    RANK() OVER (ORDER BY step_no) AS rnk,
    DENSE_RANK() OVER (ORDER BY step_no) AS drnk
FROM process_event
ORDER BY event_id
FETCH FIRST 8 ROWS ONLY;
-- 觀察與作答：因為在那之前有許多同分的結果，在RANK()中會跳過想同分數的排名，這點可以從step_no = 20的RANK值為13可以看出。


PROMPT ########## M13-4：LAG —— 同片晶圓相鄰兩站的間隔 ##########
-- 依 wafer_id 分區、step_no 排序，取前一筆的 in_ts
-- 列出 event_id, wafer_id, step_no, prev_in, 以及兩者相差的分鐘數 mins
-- （TIMESTAMP 相減是 INTERVAL，換分鐘請用
--   EXTRACT(DAY FROM d)*1440 + EXTRACT(HOUR FROM d)*60 + EXTRACT(MINUTE FROM d)）
-- 預期：有 24 列 mins 有值（每片晶圓的第 2、3 站），值都是 360
-- 作答區：
SELECT event_id, wafer_id, step_no,
    LAG(in_ts) OVER (PARTITION BY wafer_id ORDER BY step_no) AS prev_in,
    EXTRACT(DAY FROM (in_ts - LAG(in_ts) OVER (PARTITION BY wafer_id ORDER BY step_no)))*1440 +
    EXTRACT(HOUR FROM (in_ts - LAG(in_ts) OVER (PARTITION BY wafer_id ORDER BY step_no)))*60 +
    EXTRACT(MINUTE FROM (in_ts - LAG(in_ts) OVER (PARTITION BY wafer_id ORDER BY step_no))) AS mins
FROM process_event
ORDER BY wafer_id, step_no;

PROMPT ########## M13-5：LEAD —— 看下一站 ##########
-- 同一個分區與排序，取下一筆的 step_name
-- 在觀察區寫：最後一站（step_no = 30）的 next_step 是什麼
-- 作答區：
SELECT event_id, wafer_id, step_no, step_name,
    LEAD(step_name) OVER (PARTITION BY wafer_id ORDER BY step_no) AS next_step
FROM process_event
ORDER BY wafer_id, step_no;
-- 觀察與作答：step_no = 30 的 next_step是NULL，因為它是最後一站，沒有下一站。


PROMPT ########## M13-6：累計（Running Total） ##########
-- 依 in_ts 排序，用 SUM(1) OVER (ORDER BY in_ts ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
-- 產生累計事件數 running_cnt（前 10 列）
-- 作答區：
SELECT event_id, in_ts,
    SUM(1) OVER (ORDER BY in_ts ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_cnt
FROM process_event
ORDER BY in_ts
FETCH FIRST 10 ROWS ONLY;

PROMPT ########## M13-7：移動平均 ##########
-- 對 metrology 的 metric_value，依 meas_id 排序，算「前後各一筆」的移動平均
-- 框用 ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
-- 列出 meas_id, metric_name, metric_value, mov_avg（前 8 列）
-- 作答區：
SELECT meas_id, metric_name, metric_value,
    AVG(metric_value) OVER (ORDER BY meas_id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS mov_avg
FROM metrology
ORDER BY meas_id
FETCH FIRST 8 ROWS ONLY;

PROMPT ########## M13-8：佔比（Partition 總和當分母） ##########
-- 每片晶圓的事件數 / 全部事件數，算成百分比（2 位小數）
-- 提示：COUNT(*) OVER (PARTITION BY wafer_id) / COUNT(*) OVER ()
-- 預期：每片晶圓 3/36 = 8.33
-- 作答區：
SELECT event_id, wafer_id,
       ROUND(COUNT(*) OVER (PARTITION BY wafer_id) / COUNT(*) OVER () * 100, 2) AS pct
FROM process_event;


PROMPT ########## M13-9：FIRST_VALUE / LAST_VALUE ##########
-- 每批次第一個與最後一個站名（依 step_no 排序）
-- 注意 LAST_VALUE 的預設框只到當前列，要寫 ROWS BETWEEN UNBOUNDED PRECEDING
-- AND UNBOUNDED FOLLOWING 才會拿到真正的最後一筆
-- 預期：每個批次 first_step = LITHO、last_step = CVD
-- 作答區：
SELECT SUBSTR(wafer_id,1,6) AS lot_id,
    FIRST_VALUE(step_name) OVER (PARTITION BY SUBSTR(wafer_id,1,6) ORDER BY step_no) AS first_step,
    LAST_VALUE(step_name) OVER (PARTITION BY SUBSTR(wafer_id,1,6) ORDER BY step_no ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_step
FROM process_event
GROUP BY SUBSTR(wafer_id,1,6), step_no, step_name
ORDER BY lot_id, step_no;

PROMPT ########## M13-10：NTILE —— 分級 ##########
-- 把 12 片晶圓依良率（wafer_bin 的 pass 比率）分成 3 級，每級 4 片
-- 提示：先算出每片良率（可參考 M10 的 v_wafer_yield 寫法），再用 NTILE(3) OVER (ORDER BY yield_pct)
-- 作答區：
SELECT wafer_id,
       ROUND(SUM(CASE WHEN pass_fail = 'P' THEN die_count ELSE 0 END) * 100 / SUM(die_count), 2) AS yield_pct,
       NTILE(3) OVER (ORDER BY ROUND(SUM(CASE WHEN pass_fail = 'P' THEN die_count ELSE 0 END) * 100 / SUM(die_count), 2)) AS yield_level
FROM wafer_bin
GROUP BY wafer_id
ORDER BY yield_level, yield_pct;


PROMPT ########## M13-11：視窗函數不能寫在 WHERE（故意違規） ##########
-- 執行：SELECT event_id, ROW_NUMBER() OVER (ORDER BY in_ts) AS rn
--       FROM process_event WHERE ROW_NUMBER() OVER (ORDER BY in_ts) <= 5;
-- 記下錯誤碼，並在觀察區寫正確做法
-- 作答區：
SELECT event_id, ROW_NUMBER() OVER (ORDER BY in_ts) AS rn
FROM process_event
WHERE ROW_NUMBER() OVER (ORDER BY in_ts) <= 5;  
-- 觀察與作答：ORA-30483: window  functions are not allowed here，正確做法是將視窗函數放在子查詢或 CTE 中，然後在外層查詢中使用 WHERE 條件來篩選結果。 

EXIT
