# oracle-sql-lab

Oracle SQL 紮實訓練場：以 **Oracle 1Z0-071（SQL Certified Associate）考綱**為骨架，
在一個真實感的**半導體製造資料模型**（批次 lot／晶圓 wafer／機台履歷 process_event／量測 metrology）
上把 SQL 從零練到能寫產線報表，並全程版本化。

- **12 章**（M1–M12）、**11 份練習檔**、**約 100 題實作 + 60 題問答測驗**
- 每章都附**可驗收的預期值**（筆數、良率、錯誤碼），不是「看起來對」而是「數字對得上」
- 綜合模擬考（20 題、涵蓋 M1–M12）：**第二次作答 100/100**

---

## 為什麼是這個題目

目標職缺是智慧製造（IMC）的資料分析／AI 應用工程師。與其做一個「電商訂單」的教學資料庫，
不如用**晶圓廠的資料形狀**練 SQL——因為半導體資料的特性剛好逼出 SQL 的所有難點：

| 產線的真實狀況 | 逼你練到的 SQL |
|---|---|
| 事件表只認得 `wafer_id`，批次維度在別張表 | JOIN、`SUBSTR` 前綴鍵、inline view |
| 「還沒出站」的晶圓（`out_ts IS NULL`） | NULL 三值邏輯、`NVL`／`COALESCE`、`COUNT(欄位)` vs `COUNT(*)` |
| 良率要按規格逐筆判斷，不是固定門檻 | `CASE`、相關子查詢、視圖 |
| 負載曲線要按小時／按日分桶 | `TRUNC(timestamp,'HH24')`、`TO_CHAR` 分桶粒度 |
| 小計／總計要出現在同一張表 | `ROLLUP`、`GROUPING()` |
| 報表要快 | 索引、函數索引、`EXPLAIN PLAN` |

---

## 環境

- Oracle Database **23ai Free**（社群映像 `gvenzl/oracle-free:23`），跑在 Docker
- 資料庫 service name `FREEPDB1`，應用 schema `sqluser`
- 資料卷 `oradata`：容器重啟資料還在；要整個重建就 `docker compose down -v`

## 快速開始（PowerShell，於專案根目錄）

```powershell
Copy-Item .env.example .env
docker compose up -d
docker compose ps          # 等到 STATUS 顯示 healthy（首次約 2–4 分鐘）
```

驗收基線資料（8 表、132 筆、約束、外鍵孤兒、刻意埋的資料特徵）：

```powershell
.\run-sql.cmd -File sql\verify_m1.sql
```

> `run-sql.cmd` 是 `run-sql.ps1` 的包裝，內含 `-ExecutionPolicy Bypass`，
> 所以不必改 Windows 執行原則就能跑。

跑任一練習檔：

```powershell
.\run-sql.cmd -File sql\exercises\m08_joins_andy.sql
```

---

## 資料模型（8 張表、132 筆基線資料）

```
product ──< lot ──< wafer ──< process_event >── tool ──< chamber
                        └────< metrology
                        └────< wafer_bin
```

| 表 | 列數 | 說明 |
|---|---:|---|
| `product` | 3 | 產品（N5 / N3 / 40nm） |
| `tool` | 6 | 機台（黃光、蝕刻、薄膜、CMP） |
| `chamber` | 8 | 腔體（一台機台有多個腔體） |
| `lot` | 5 | 批次（半導體廠的基本生產單位，≤25 片，含 HOT / SUPER 急件） |
| `wafer` | 12 | 晶圓（lot × slot） |
| `process_event` | 36 | **晶圓履歷**：哪片晶圓、哪一站、哪台機台／腔體／recipe；`out_ts IS NULL` = 還在機台上 |
| `metrology` | 36 | 量測值與規格上下限 |
| `wafer_bin` | 26 | 晶圓測試（CP）bin 分佈，總 die 數 13,498 |

刻意埋進去的資料特徵（後續章節都要用到）：

- **2 筆未出站**的 event（同一批 L-2605）→ 練 NULL 語意與 `still_in_process`
- **1 筆超規**量測（`L-2603-02` 的 `CD_NM` = 13.42 > 上限 13.0）→ 練 Spec 判定
- **5 個腔體**沒有任何生產紀錄 → 練 `LEFT JOIN` 與 anti-join
- 產品 `P-CHARLIE` 的 `product_family` 為 NULL → 練 NULL 與 `DISTINCT`

---

## 章節地圖（對應 1Z0-071 考綱）

| 章 | 主題 | 關鍵能力 | 練習檔 |
|---|---|---|---|
| M1 | 關聯式基礎與 DDL | 8 張表、具名約束、主外鍵、NULL 三值邏輯、schema／PDB | `verify_m1.sql` |
| M2 | SELECT 基礎 | 別名與引號規則、字串串接運算子、`DISTINCT`、`dual` | `m02_select_basics` |
| M3 | 限制與排序 | `WHERE`、`IN`、`BETWEEN`、`LIKE`／`ESCAPE`、`ORDER BY`、NULL 排序 | `m03_where_order` |
| M4 | 單列函數 | `UPPER`／`SUBSTR`／`INSTR`／`LPAD`、`ROUND`／`TRUNC`、`ADD_MONTHS`／`LAST_DAY` | `m04_single_row_funcs` |
| M5 | 轉換與條件運算 | `TO_CHAR`／`TO_DATE` 格式模型、`NVL`／`NVL2`／`NULLIF`／`COALESCE`、`CASE` vs `DECODE`、`RR` vs `YY` | `m05_conversion_case` |
| M6 | 群組函數 | `COUNT(*)`／`COUNT(col)`／`COUNT(DISTINCT)`、`GROUP BY`、`HAVING` | `m06_group_functions` |
| M7 | 子查詢 | 單列／多列、`ANY`／`ALL`、`EXISTS`、相關子查詢、inline view、`NOT IN` 的 NULL 陷阱 | `m07_subqueries` |
| M8 | 多表連接 | `INNER`／`LEFT`／`FULL`、Oracle `(+)`、自連接、非等值連接 | `m08_joins` |
| M9 | DML 與交易 | CTAS、`INSERT`／`UPDATE`／`DELETE`／`MERGE`、`SAVEPOINT`、DDL 隱式 COMMIT | `m09_dml_transactions` |
| M10 | 視圖與物件 | `VIEW`（含 `WITH READ ONLY`）、`SEQUENCE`、普通索引與函數索引、字典查詢 | `m10_views_objects` |
| M11 | 時間與時區 | `TIMESTAMP` 家族、`SYSDATE` vs `CURRENT_DATE`、`EXTRACT` 拆 INTERVAL、`TRUNC` 分桶、`ROLLUP`／`GROUPING SETS` | `m11_time_rollup` |
| M12 | 資料字典與執行計畫 | `USER_`／`ALL_`／`DBA_`、容器確認、`EXPLAIN PLAN`、綜合模擬考 | `m12_dictionary_plan` + `docs/mock_exam_1z0-071.md` |

每章的固定節奏：**教學 → 8–10 題實作（附預期值）→ 6 題問答測驗 → 批改 → commit**。

---

## 三個代表性成果

### 1. 每片晶圓良率（GROUP BY + CASE + 視圖）

```sql
CREATE OR REPLACE VIEW v_wafer_yield AS
SELECT w.wafer_id, w.lot_id,
       SUM(CASE WHEN wb.pass_fail = 'P' THEN wb.die_count ELSE 0 END) AS pass_count,
       SUM(CASE WHEN wb.pass_fail = 'F' THEN wb.die_count ELSE 0 END) AS fail_count,
       ROUND(SUM(CASE WHEN wb.pass_fail = 'P' THEN wb.die_count ELSE 0 END) * 100
             / SUM(wb.die_count), 2) AS yield_pct
FROM wafer_bin wb
JOIN wafer w ON wb.wafer_id = w.wafer_id
GROUP BY w.wafer_id, w.lot_id;
```

結果：12 片晶圓，最低 90.67%（L-2602-01）、最高 100%（L-2601-01）。

### 2. 批次事件摘要（含「還在機上」的片數）

```sql
CREATE OR REPLACE VIEW v_lot_event_summary AS
SELECT w.lot_id,
       COUNT(e.event_id)                    AS event_cnt,
       MIN(e.in_ts)                         AS first_in,
       MAX(e.out_ts)                        AS last_out,
       COUNT(e.event_id) - COUNT(e.out_ts)  AS still_in_process
FROM process_event e
JOIN wafer w ON e.wafer_id = w.wafer_id
GROUP BY w.lot_id;
```

關鍵在 `COUNT(*) - COUNT(out_ts)`：群組函數**忽略 NULL**，所以 `MAX(out_ts)` 會悄悄漏掉
還沒出站的晶圓；補上這一欄，報表語意才正確（L-2605 = **2 片未出站**）。

### 3. 函數索引讓 `filter()` 變成 `access()`

同一個條件，建索引前後的執行計畫：

```sql
-- 建索引前：SUBSTR 無法使用索引
EXPLAIN PLAN FOR
SELECT * FROM process_event WHERE SUBSTR(wafer_id,1,6) = 'L-2601';
--  1 - filter(SUBSTR("WAFER_ID",1,6)='L-2601')

-- 建函數索引後
CREATE INDEX idx_pe_lot_prefix ON process_event(SUBSTR(wafer_id,1,6));
EXPLAIN PLAN FOR
SELECT * FROM process_event WHERE SUBSTR(wafer_id,1,6) = 'L-2601';
--  2 - access(SUBSTR("WAFER_ID",1,6)='L-2601')   ← INDEX RANGE SCAN
```

`filter` 是「每列都要算一次」，`access` 才是「用索引定位」。這一格差異就是查詢效能的全部。

---

## 驗收方式

```powershell
# 基線資料完整性（表數、列數、約束、外鍵孤兒、埋入特徵）
.\run-sql.cmd -File sql\verify_m1.sql
```

預期輸出摘錄：

| 檢查 | 預期 |
|---|---|
| 資料表數 | 8 |
| 列數 | 3 / 6 / 8 / 5 / 12 / 36 / 36 / 26 |
| 具名約束 | P 8 / R 8 / U 2 / C 32 |
| 外鍵孤兒 | 全部 0 |
| 未出站 event | 2 |
| 超規量測 | 1 |
| 無生產紀錄腔體 | 5 |

各章練習檔的預期值寫在檔案內的註解中（例如「預期 9 筆」「錯誤碼請實測後回報」）。

---

## 踩過的地雷（都留在程式碼裡）

| 問題 | 原因 | 解法 |
|---|---|---|
| `run-sql.ps1` 出現亂碼與 ParserError | UTF-8 無 BOM 的 `.ps1` 被 Windows PowerShell 5.1 以 Big5 解讀 | 腳本一律**純 ASCII** |
| `@/schema/003_seed.sql` 報 `UnrecognizedToken` | PowerShell 把開頭的 `@` 當 splatting 運算子 | 整串加引號，或改用 `bash -lc` |
| 未提交的 UPDATE 卻被永久寫入 | **SQL\*Plus 的 `EXITCOMMIT` 預設 ON**，`EXIT` 會 commit | `SET EXITCOMMIT OFF`（已寫進 runner） |
| 資料字典查不到自己剛建的索引 | 未加引號的識別字轉大寫，字典存的也是大寫 | 字典查詢一律用大寫字面值 |
| 字典裡冒出 22 筆 `BIN$…` 約束 | `DROP TABLE` 進回收筒，不是真刪 | `PURGE RECYCLEBIN` 或查詢時排除 `BIN%` |
| `DBMS_XPLAN.DISPLAY` 顯示不是剛跑的那條查詢 | `PLAN_TABLE` 保留舊計畫 | `EXPLAIN PLAN SET STATEMENT_ID=…` 或先 `DELETE FROM plan_table` |
| 容器初始化卡在 `Comment created.` | 有 TTY 時 sqlplus 讀完腳本停在 stdin | 每個 sqlplus 呼叫加 `< /dev/null`，`.sql` 結尾加 `EXIT` |
| `.ps1` 被執行原則擋掉 | 重開終端後 `Process` scope 的原則消失 | `run-sql.cmd` 包裝（內建 `-ExecutionPolicy Bypass`） |

---

## 目錄結構

```
docker-compose.yml          Oracle 23ai 容器
.env.example                schema／密碼範本（.env 不進版控）
db/001_load_schema.sh       容器首次初始化：以 APP_USER 身分載入 schema + seed
schema/002_schema.sql       DDL（所有約束都具名，方便字典驗證）
schema/003_seed.sql         基線資料（132 筆，單列單 INSERT）
sql/verify_m1.sql           基線驗收查詢
sql/show_schema.sql         表／欄位／鍵／樣本資料速查
sql/exercises/              M2–M12 練習檔（每檔含題目、作答區、預期值）
docs/ROADMAP.md             M1–M12 課綱與驗收標準
docs/mock_exam_1z0-071.md   20 題綜合模擬考（含答案與解析）
run-sql.ps1 / run-sql.cmd   送 SQL 進容器的自製工具
```

---

## 環境需求

- Windows 11 + PowerShell 5.1（或 WSL2）
- Docker Desktop
- 約 2 GB 磁碟空間（Oracle 映像）

## 授權

本專案為個人學習作品，程式與 SQL 可自由參考使用。
