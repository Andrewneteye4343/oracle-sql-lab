-- ============================================================
-- M1 驗收查詢：把輸出跟我給你的「預期值」逐項比對
-- 執行：docker compose exec -T oracle sqlplus -s sqluser/SqlDev#2026@//localhost:1521/FREEPDB1 @/sql/verify_m1.sql
-- ============================================================
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK OFF
COLUMN object_name FORMAT A18
COLUMN object_type FORMAT A12

PROMPT ===== [1] 我建立了哪些物件（預期 8 張表） =====
SELECT object_name, object_type
FROM   user_objects
WHERE  object_type = 'TABLE'
ORDER  BY object_name;

PROMPT ===== [2] 每張表的列數（預期值：3/6/8/5/12/36/36/26） =====
SELECT 'PRODUCT'       AS tbl, COUNT(*) AS cnt FROM product
UNION ALL SELECT 'TOOL',          COUNT(*) FROM tool
UNION ALL SELECT 'CHAMBER',       COUNT(*) FROM chamber
UNION ALL SELECT 'LOT',           COUNT(*) FROM lot
UNION ALL SELECT 'WAFER',         COUNT(*) FROM wafer
UNION ALL SELECT 'PROCESS_EVENT', COUNT(*) FROM process_event
UNION ALL SELECT 'METROLOGY',     COUNT(*) FROM metrology
UNION ALL SELECT 'WAFER_BIN',     COUNT(*) FROM wafer_bin
ORDER BY 1;

PROMPT ===== [3] 具名約束清單（預期：P 8 / R 8 / U 2 / C 32） =====
SELECT constraint_type, COUNT(*) AS cnt
FROM   user_constraints
GROUP  BY constraint_type
ORDER  BY constraint_type;

PROMPT ===== [4] 約束名稱分解（預期：PK_ 8 / FK_ 8 / UQ_ 2 / CK_ 5 / NN_ 27，合計 50） =====
SELECT SUBSTR(constraint_name, 1, INSTR(constraint_name, '_') - 1) AS prefix
     , COUNT(*) AS cnt
FROM   user_constraints
GROUP  BY SUBSTR(constraint_name, 1, INSTR(constraint_name, '_') - 1)
ORDER  BY 1;

PROMPT ===== [5] 外鍵孤兒列檢查（必須全部 0） =====
SELECT (SELECT COUNT(*) FROM chamber c WHERE NOT EXISTS (SELECT 1 FROM tool t WHERE t.tool_id = c.tool_id))       AS orphan_chamber_tool,
       (SELECT COUNT(*) FROM lot l     WHERE NOT EXISTS (SELECT 1 FROM product p WHERE p.product_id = l.product_id)) AS orphan_lot_product,
       (SELECT COUNT(*) FROM wafer w   WHERE NOT EXISTS (SELECT 1 FROM lot l WHERE l.lot_id = w.lot_id))            AS orphan_wafer_lot,
       (SELECT COUNT(*) FROM process_event e WHERE NOT EXISTS (SELECT 1 FROM wafer w WHERE w.wafer_id = e.wafer_id)) AS orphan_event_wafer,
       (SELECT COUNT(*) FROM process_event e WHERE NOT EXISTS (SELECT 1 FROM chamber c WHERE c.chamber_id = e.chamber_id)) AS orphan_event_chamber,
       (SELECT COUNT(*) FROM process_event e WHERE NOT EXISTS (SELECT 1 FROM tool t    WHERE t.tool_id    = e.tool_id))    AS orphan_event_tool,
       (SELECT COUNT(*) FROM metrology m WHERE NOT EXISTS (SELECT 1 FROM wafer w WHERE w.wafer_id = m.wafer_id))    AS orphan_meas_wafer,
       (SELECT COUNT(*) FROM wafer_bin b WHERE NOT EXISTS (SELECT 1 FROM wafer w WHERE w.wafer_id = b.wafer_id))    AS orphan_bin_wafer
FROM   dual;

PROMPT ===== [6] 刻意埋的資料特徵（M2 起會用到） =====
SELECT '尚未出站的 event（out_ts IS NULL）' AS what, COUNT(*) AS cnt FROM process_event WHERE out_ts IS NULL
UNION ALL
SELECT '超出規格的量測值', COUNT(*) FROM metrology
 WHERE (spec_upper IS NOT NULL AND metric_value > spec_upper)
    OR (spec_lower IS NOT NULL AND metric_value < spec_lower)
UNION ALL
SELECT '沒有生產紀錄的腔體（outer join 練習用）', COUNT(*)
  FROM chamber c WHERE NOT EXISTS (SELECT 1 FROM process_event e WHERE e.chamber_id = c.chamber_id)
ORDER BY 1;
