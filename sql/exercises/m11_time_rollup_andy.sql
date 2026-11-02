-- ============================================================
-- M11 練習：時間與時區、日期區間分析、GROUP BY 進階
-- 檔名：sql/exercises/m11_time_rollup_andy.sql
-- 執行：.\run-sql.ps1 -File sql\exercises\m11_time_rollup_andy.sql
--
-- 【安全規則】全部唯讀，不動任何資料。
-- 注意：含 SYSDATE / SESSIONTIMEZONE 的題目結果會隨環境與時間變動，
--       驗收只看「結構與量級」，不看絕對值。
-- ============================================================
SET DEFINE OFF
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK ON

PROMPT ########## M11-1：五個「現在時間」與兩個時區設定 ##########
-- 一次列出：SYSDATE、SYSTIMESTAMP、CURRENT_DATE、CURRENT_TIMESTAMP、
--           SESSIONTIMEZONE、DBTIMEZONE
-- 在觀察區寫：SYSDATE 與 CURRENT_DATE 的差別是什麼？
-- 作答區：
SELECT SYSDATE, SYSTIMESTAMP, CURRENT_DATE, CURRENT_TIMESTAMP, SESSIONTIMEZONE, DBTIMEZONE
FROM dual;
-- 觀察與作答：SYSDATE與CURRENT_DATE的差別在於SYSDATE返回的是資料伺服器的日期與時間，而CURRENT_DATE返回的是使用者會話的日期與時間

PROMPT ########## M11-2：EXTRACT 拆解時間 ##########
-- 從 process_event 的 in_ts 取出 YEAR / MONTH / DAY（前 3 列）
-- 作答區：
SELECT event_id, EXTRACT(YEAR FROM in_ts) AS year, EXTRACT(MONTH FROM in_ts) AS month, EXTRACT(DAY FROM in_ts) AS day
FROM process_event
ORDER BY event_id
FETCH FIRST 3 ROWS ONLY;


PROMPT ########## M11-3：EXTRACT 拆解 INTERVAL ##########
-- 對 process_event 的 (out_ts - in_ts) 取出 HOUR / MINUTE，並算出總秒數
-- 總秒數 = EXTRACT(DAY FROM d)*86400 + EXTRACT(HOUR FROM d)*3600
--         + EXTRACT(MINUTE FROM d)*60 + EXTRACT(SECOND FROM d)
-- 列出 event_id、HOUR、MINUTE、TOTAL_SEC（前 5 列）
-- 作答區：
SELECT event_id,
    EXTRACT(HOUR FROM (out_ts - in_ts)) AS hout,
    EXTRACT(MINUTE FROM (out_ts - in_ts)) AS minute,
    EXTRACT(DAY FROM (out_ts - in_ts))*86400 +
    EXTRACT(HOUR FROM (out_ts - in_ts))*3600 +
    EXTRACT(MINUTE FROM (out_ts - in_ts))*60 +
    EXTRACT(SECOND FROM (out_ts - in_ts)) AS total_sec
FROM process_event
ORDER BY event_id
FETCH FIRST 5 ROWS ONLY;

PROMPT ########## M11-4：時區轉換 ##########
-- (a) 查 TZ_OFFSET('Asia/Taipei')
-- (b) 把 in_ts 轉成「台北時間」的 TIMESTAMP WITH TIME ZONE
--     提示：FROM_TZ(CAST(in_ts AS TIMESTAMP), 'Asia/Taipei')
-- (c) 再 AT TIME ZONE 'UTC' 轉成 UTC
-- 列出 event_id 與 (b)(c) 兩個值（前 5 列）
-- 作答區：
SELECT TZ_OFFSET('Asia/Taipei') AS taipei_offset FROM dual;

SELECT event_id,
    FROM_TZ(CAST(in_ts AS TIMESTAMP), 'Asia/Taipei') AS taipei_time,
    FROM_TZ(CAST(in_ts AS TIMESTAMP), 'Asia/Taipei') AT TIME ZONE 'UTC' AS utc_time
FROM process_event
ORDER BY event_id
FETCH FIRST 5 ROWS ONLY;

PROMPT ########## M11-5：每小時事件數（產線負載曲線） ##########
-- 依 TRUNC(in_ts,'HH24') 分組，數事件數，依時間排序
-- 作答區：
SELECT TRUNC(in_ts,'HH24') AS hour_start, COUNT(*) AS event_count
FROM process_event
GROUP BY TRUNC(in_ts,'HH24')
ORDER BY hour_start;

PROMPT ########## M11-6：每日事件數 ##########
-- 依 TRUNC(in_ts,'DD') 分組，數事件數
-- 作答區：
SELECT TRUNC(in_ts,'DD') AS day_start, COUNT(*) AS event_count
FROM process_event
GROUP BY TRUNC(in_ts,'DD')
ORDER BY day_start;

PROMPT ########## M11-7：ROLLUP 小計與總計 ##########
-- 依 step_name 分組並加 ROLLUP，數事件數
-- 預期 4 列（三個站別各 12 + 總計 36，總計列的 STEP_NAME 為 NULL）
-- 作答區：
SELECT step_name, COUNT(*) AS event_count
FROM process_event
GROUP BY ROLLUP(step_name)
ORDER BY step_name NULLS LAST;

PROMPT ########## M11-8：GROUPING() 標記小計列 ##########
-- 同上，但多一欄 GROUPING(step_name)：小計/總計列為 1，明細列為 0
-- 作答區：
SELECT step_name, COUNT(*) AS event_count, GROUPING(step_name) AS is_rollup
FROM process_event
GROUP BY ROLLUP(step_name)
ORDER BY step_name NULLS LAST;

PROMPT ########## M11-9：ROLLUP 兩層 ##########
-- GROUP BY ROLLUP(step_name, tool_id)，數事件數
-- 觀察哪些列是小計、哪些是總計
-- 作答區：
SELECT step_name, tool_id, COUNT(*) AS event_count
FROM process_event
GROUP BY ROLLUP(step_name, tool_id)
ORDER BY step_name NULLS LAST, tool_id NULLS LAST;

PROMPT ########## M11-10：GROUPING SETS ##########
-- 用 GROUPING SETS ((step_name), (tool_id), ()) 同時產出
-- 「按站別」「按機台」「總計」三種彙總
-- 作答區：
SELECT step_name, tool_id, COUNT(*) AS event_count
FROM process_event
GROUP BY GROUPING SETS ((step_name), (tool_id), ())
ORDER BY step_name NULLS LAST, tool_id NULLS LAST;

EXIT
