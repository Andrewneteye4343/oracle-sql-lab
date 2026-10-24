# 學習里程碑（對齊 Oracle 1Z0-071 考綱）

考試事實（Oracle University 官方頁面）：**63 題選擇題、120 分鐘、通過分數 63%**，
驗證版本 11.2 以上到 19c；費用依地區而定（約 US$245）。考綱共 12 個主題，對應下面的 M1–M12。

| 里程碑 | 主題（1Z0-071 主題） | 你會學到 | 專案產出 | 驗收標準 |
|---|---|---|---|---|
| **M1** | 關聯式資料庫概念 | 關聯模型、主鍵/外鍵、NULL、SQL 語句分類（DDL/DML/DCL/TCL）、schema 與 user、Oracle 識別字規則、資料型別 | 環境跑起來＋8 張表的半導體資料模型 | `sql/verify_m1.sql` 六段輸出全部吻合預期值；repo 推上 GitHub |
| M2 | 用 SELECT 檢索資料 | 欄位別名、算術運算式、`||` 串接、`q'[]'`、DISTINCT、`dual`、NULL 在運算中的行為 | `sql/exercises/m02_*.sql` | 10 題全對 |
| M3 | 限制與排序資料 | WHERE、比較運算子、BETWEEN/IN/LIKE、NULL 判斷、ORDER BY（多鍵/ASC-DESC/NULLS FIRST）、替代變數 `&` | m03 練習 | 10 題全對 |
| M4 | 單列函數 | 字元（UPPER/SUBSTR/INSTR/LPAD/TRIM/REPLACE）、數字（ROUND/TRUNC/MOD）、日期（MONTHS_BETWEEN/ADD_MONTHS/NEXT_DAY）、ROUND/TRUNC 對日期 | m04 練習 | 10 題全對 |
| M5 | 轉換函數與條件運算式 | 隱式/顯式轉換、TO_CHAR/TO_DATE/TO_NUMBER、NVL/NVL2/COALESCE/NULLIF、CASE/DECODE | m05 練習 | 10 題全對 |
| M6 | 群組函數與分組 | COUNT/SUM/AVG/MIN/MAX、GROUP BY、HAVING、群組與 NULL | 良率/腔體統計報表 | 10 題全對 |
| M7 | 多表查詢（Join） | INNER/OUTER/自連、CROSS、NATURAL/USING/ON、非等值 join、外連接的 NULL 陷阱 | 履歷查詢：wafer × event × tool × chamber | 10 題全對 |
| M8 | 子查詢與集合運算 | 單列/多列（IN/ANY/ALL）、多欄、相關子查詢、EXISTS/NOT EXISTS、WITH、UNION/UNION ALL/INTERSECT/MINUS | 「哪些腔體沒生產紀錄」「同批內異常」 | 10 題全對 |
| M9 | 用 DML 管理資料 | INSERT（含子查詢）、UPDATE、DELETE、MERGE、交易控制 COMMIT/ROLLBACK/SAVEPOINT | 增量載入（MERGE upsert）腳本 | 10 題全對 |
| M10 | DDL 與結構管理 | CREATE/ALTER/DROP、TRUNCATE vs DELETE、資料型別選擇、約束、VIEW、SEQUENCE、INDEX、SYNONYM、暫存表 | 建 view + sequence + index 供儀表板使用 | 10 題全對 |
| M11 | ETL 實作 | 外部檔 → staging（外部表或 sqlldr）→ 資料品質檢查 → MERGE 到正式表 → 失敗回滾；分批與可重跑 | `etl/` 一支可重跑的載入程式 | 重跑兩次結果一致（冪等）＋品質報表 |
| M12 | 資料字典與總驗收 | USER_/ALL_/DBA_ 視圖、查看表/欄位/約束、EXPLAIN PLAN 與 index 差異、模擬考 | 專案文件、README 完稿 | 模擬考 ≥ 63%；repo 有 tag |

## 節奏
一次一個里程碑：我講概念 → 你動手 → 我出題批改 → 你回報驗收輸出 → 才進下一個。
