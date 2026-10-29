-- ============================================================
-- M8 練習：多表連接（JOIN）
-- 檔名：sql/exercises/m08_joins_andy.sql
-- 執行：.\run-sql.ps1 -File sql\exercises\m08_joins_andy.sql
-- 目標：把 wafer / lot / process_event / chamber / tool 串成一張可分析的寬表
-- ============================================================
SET DEFINE OFF
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK OFF

PROMPT ########## M8-1：笛卡兒乘積（故意製造） ##########
-- SELECT COUNT(*) FROM process_event, wafer;   記下筆數，並在觀察區解釋為什麼
-- 作答區：
SELECT COUNT(*) FROM process_event, wafer;
-- 觀察與作答：


PROMPT ########## M8-2：兩表 INNER JOIN（ANSI 語法） ##########
-- event 與 wafer 連接，列出 event_id, wafer_id, lot_id, step_name（前 5 列）
-- 作答區：
SELECT e.event_id, w.wafer_id, w.lot_id, e.step_name
FROM process_event e
JOIN wafer w ON e.wafer_id = w.wafer_id
WHERE ROWNUM <= 5;

PROMPT ########## M8-3：三表 JOIN（含 lot） ##########
-- event -> wafer -> lot，列出 event_id, lot_id, priority, step_name（前 8 列）
-- 在觀察區確認總筆數是否仍為 36（不應變多）
-- 作答區：
SELECT e.event_id, w.lot_id, l.priority, e.step_name
FROM process_event e
JOIN wafer w ON e.wafer_id = w.wafer_id
JOIN lot l ON w.lot_id = l.lot_id
WHERE ROWNUM <= 8;

PROMPT ########## M8-4：舊式寫法與 ANSI 寫法對照 ##########
-- 用「逗號 + WHERE」重寫 M8-2，結果筆數必須相同
-- 作答區：
SELECT e.event_id, w.wafer_id, w.lot_id, e.step_name
FROM process_event e, wafer w
WHERE e.wafer_id = w.wafer_id;

PROMPT ########## M8-5：LEFT OUTER JOIN 找出沒有生產紀錄的腔體 ##########
-- 列出 chamber_id 與 tool_id，條件是沒有任何 process_event 用到它
-- 作答區：
SELECT c.chamber_id, c.tool_id
FROM chamber c
LEFT JOIN process_event e ON c.chamber_id = e.chamber_id
WHERE e.chamber_id IS NULL;

PROMPT ########## M8-6：Oracle 舊式外連接 (+) ##########
-- 用 (+) 運算子重寫 M8-5（把 (+) 放在 process_event 那一側）
-- 作答區：
SELECT c.chamber_id, c.tool_id
FROM chamber c, process_event e
WHERE c.chamber_id = e.chamber_id(+)
AND e.chamber_id IS NULL;

PROMPT ########## M8-7：每台機台的事件數（含 0 筆的機台） ##########
-- tool LEFT JOIN process_event，列出 tool_id 與事件數，事件數為 0 的機台也要出現
-- 作答區：
SELECT t.tool_id, COUNT(e.event_id) AS event_count
FROM tool t
LEFT JOIN process_event e ON t.tool_id = e.tool_id
GROUP BY t.tool_id
ORDER BY t.tool_id;

PROMPT ########## M8-8：良率報表（wafer_bin + wafer + lot） ##########
-- 依 wafer_id 加總 pass 數與 fail 數，算出良率百分比（小數 2 位）
-- 提示：SUM(CASE WHEN pass_fail = 'P' THEN bin_count ELSE 0 END)
-- 作答區：
SELECT w.wafer_id, w.lot_id,
    SUM(CASE WHEN wb.pass_fail = 'P' THEN wb.die_count ELSE 0 END) AS pass_count,
    SUM(CASE WHEN wb.pass_fail = 'F' THEN wb.die_count ELSE 0 END) AS fail_count,
    ROUND(SUM(CASE WHEN wb.pass_fail = 'P' THEN wb.die_count ELSE 0 END) * 100 / SUM(wb.die_count), 2) AS yield_rate
FROM wafer_bin wb
JOIN wafer w ON wb.wafer_id = w.wafer_id
GROUP BY w.wafer_id, w.lot_id
ORDER BY w.wafer_id;

PROMPT ########## M8-9：非等值連接 ##########
-- 把每筆 metrology 標記為 IN_SPEC / OUT_OF_SPEC（不用 JOIN，先暖身）
-- 再用 JOIN 列出 wafer_id, lot_id, metric_name, metric_value, 標記
-- 作答區：
SELECT m.wafer_id, w.lot_id, m.metric_name, m.metric_value,
    CASE WHEN m.metric_value BETWEEN m.spec_lower AND m.spec_upper THEN 'IN_SPEC' ELSE 'OUT_OF_SPEC' END AS spec_status
FROM metrology m
JOIN wafer w ON m.wafer_id = w.wafer_id
ORDER BY m.wafer_id, m.metric_name;

PROMPT ########## M8-10：自連接（self join） ##########
-- 從 wafer 表找出「同一個 lot 內、slot_no 相差 1」的晶圓配對（w1, w2）
-- 作答區：
SELECT w1.wafer_id AS wafer1, w2.wafer_id AS wafer2, w1.lot_id
FROM wafer w1
JOIN wafer w2 ON w1.lot_id = w2.lot_id AND ABS(w1.slot_no - w2.slot_no) = 1
WHERE w1.wafer_id < w2.wafer_id
ORDER BY w1.lot_id, w1.wafer_id, w2.wafer_id;

EXIT
