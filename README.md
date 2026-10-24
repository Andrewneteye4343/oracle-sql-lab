# oracle-sql-lab

Oracle SQL 紮實訓練場：跟著 **Oracle 1Z0-071（SQL Certified Associate）考綱**走，
每一步都在一個真實感的**半導體製造資料模型**（批次 lot / 晶圓 wafer / 機台履歷 process_event / 量測 metrology）
上動手，最後長出一條可重跑的 **ETL** 管線。

## 環境
- Oracle Database **23ai Free**（社群映像 `gvenzl/oracle-free:23`），跑在 Docker
- 資料庫 `FREEPDB1`，應用 schema = `APP_USER`（預設 `sqluser`）
- 資料卷 `oradata`：容器重啟資料還在；要重建就跑 `docker compose down -v`

## 快速開始（PowerShell，於專案根目錄）
```powershell
Copy-Item .env.example .env
docker compose up -d
docker compose ps
```
第一次啟動要初始化資料庫（2–4 分鐘）。等到 `docker compose ps` 顯示 `healthy`，再驗收：

```powershell
Copy-Item .env.example .env
docker compose up -d
docker compose ps
```

等到 `docker compose ps` 顯示 `healthy` 後跑驗收（**`@` 開頭的參數在 PowerShell 會被當成運算子，必須整串加引號**）：

```powershell
docker compose exec -T oracle sqlplus -s 'sqluser/SqlDev#2026@//localhost:1521/FREEPDB1' '@/sql/verify_m1.sql'
```

## 資料模型（8 張表）
```
product ──< lot ──< wafer ──< process_event >── tool ──< chamber
                        └────< metrology
                        └────< wafer_bin
```
| 表 | 說明 |
|---|---|
| `product` | 產品（含技術節點，例如 N5/N3） |
| `tool` / `chamber` | 機台與腔體（一台機台有多個腔體） |
| `lot` | 批次，半導體廠的基本生產單位（≤ 25 片），急件用 `priority` 標記 |
| `wafer` | 晶圓（lot × slot） |
| `process_event` | **晶圓履歷**：哪一片晶圓、哪一站、哪台機台/腔體/recipe；`out_ts IS NULL` 代表還在機台上 |
| `metrology` | 量測結果與規格上下限 |
| `wafer_bin` | 晶圓測試（CP）bin 分佈 |

## 目錄
```
docker-compose.yml       Oracle 容器
schema/002_schema.sql    DDL（全部約束都具名）
schema/003_seed.sql      基線資料
db/001_load_schema.sh    容器首次初始化時以 APP_USER 身分載入上面兩個檔
sql/verify_m1.sql        M1 驗收查詢
sql/exercises/           你的練習與答案
docs/ROADMAP.md          M1–M12 課綱與驗收標準
```

## 已知注意事項
- 初始化腳本**只在資料卷為空時**執行；改了 `schema/` 之後要 `docker compose down -v` 再 `up -d`。
- `schema/*.sql` 刻意放在 `/schema` 而不是 `/container-entrypoint-initdb.d`，避免被 entrypoint 用 SYS 身分再跑一次。
- `.env` 不進版控；裡面的密碼是本機練習用預設值，不是機密。
- Windows 上 git 會把 `.sh` 的執行位元弄掉，本專案因此刻意用「source 模式」載入腳本（不依賴 +x）。
- **PowerShell 的陷阱**：`@` 在參數開頭會被解析成 splatting／陣列運算子，`@/sql/x.sql` 會報
  `ParserError: UnrecognizedToken`。sqlplus 的 `@script` 參數一定要整串加引號（`'@/sql/verify_m1.sql'`），
  或改用 `docker compose exec -T oracle bash -lc "sqlplus -s 'user/pass@//localhost:1521/FREEPDB1' @/sql/x.sql"`。
- 每個 sqlplus 呼叫都加 `< /dev/null`，且每支 `.sql` 結尾有 `EXIT`：容器有 TTY 時 sqlplus 可能在讀完
  腳本後停在 stdin 不退出，造成初始化「看起來卡住」（health 永遠 `starting`）。
