# Oracle 1Z0-071 模擬考（M1–M12 綜合，20 題）

作答方式：先全部寫完再看最後的答案與解析。每題 5 分，總分 100。

---

**Q1.** `SELECT COUNT(*) FROM lot WHERE priority <> NULL;` 會回傳什麼？
(A) 5　(B) 0　(C) 錯誤　(D) NULL

**Q2.** Oracle 中 `WHERE product_family = ''` 的結果是？
(A) 回傳欄位為空字串的列　(B) 回傳 0 列　(C) ORA-00932　(D) 回傳 NULL 的列

**Q3.** `SELECT DISTINCT tool_type, fab_area FROM tool;` 回傳 4 列。這代表？
(A) 有 4 種 tool_type　(B) 有 4 種 (tool_type, fab_area) 組合　(C) 有 4 台機台　(D) 有 4 種 fab_area

**Q4.** 下列何者**不合法**？
(A) `SELECT product_name AS "產品" FROM product;`
(B) `SELECT product_name AS 產品 FROM product;`
(C) `SELECT product_name AS '產品' FROM product;`
(D) 三者都合法

**Q5.** `ORDER BY priority DESC` 時，NULL 值會出現在？
(A) 最前面　(B) 最後面　(C) 位置不確定　(D) 不參與排序

**Q6.** `ROUND(2.5)`、`ROUND(3.5)`、`TRUNC(2.9)` 依序是？
(A) 2, 4, 2　(B) 3, 4, 2　(C) 2, 3, 2　(D) 3, 3, 3

**Q7.** `SUBSTR('ABCDEF', -3, 2)` 回傳？
(A) `ABC`　(B) `DE`　(C) `DEF`　(D) `EF`

**Q8.** `INSTR('L-2601-01', '-', 5)` 回傳？
(A) 2　(B) 5　(C) 7　(D) 0

**Q9.** `NVL(out_ts, 'IN PROGRESS')` 其中 `out_ts` 是 TIMESTAMP，會發生什麼？
(A) 正常回傳字串　(B) ORA-01722　(C) ORA-01858　(D) ORA-00932

**Q10.** `DECODE(NULL, NULL, 'same', 'diff')` 與
`CASE WHEN NULL = NULL THEN 'same' ELSE 'diff' END` 分別回傳？
(A) `same` / `same`　(B) `diff` / `diff`　(C) `same` / `diff`　(D) `diff` / `same`

**Q11.** `TO_DATE('01-01-51','DD-MM-RR')` 與 `TO_DATE('01-01-51','DD-MM-YY')` 的年份（以 2026 為現在）？
(A) 2051 / 2051　(B) 1951 / 1951　(C) 1951 / 2051　(D) 2051 / 1951

**Q12.** `TO_CHAR(105, '990.99')` 與 `TO_CHAR(105, '000.00')` 分別是？
(A) `105` / `105.00`　(B) ` 105.00` / `105.00`　(C) `105.00` / ` 105.00`　(D) 兩者相同

**Q13.** `SELECT lot_id, COUNT(*) FROM wafer;` 的錯誤碼是？
(A) ORA-00979　(B) ORA-00937　(C) ORA-00918　(D) ORA-00933

**Q14.** 下列敘述何者正確？
(A) `HAVING` 必須搭配 `GROUP BY`
(B) `HAVING` 可以沒有 `GROUP BY`，此時整表視為一組
(C) `WHERE` 可以過濾群組函數結果
(D) `ORDER BY` 不能用群組函數

**Q15.** `tool LEFT JOIN process_event` 後用 `COUNT(*)` 數事件數，沒有事件的機台會得到？
(A) 0　(B) 1　(C) 錯誤　(D) NULL

**Q16.** `WHERE qty_wafers = (SELECT qty_wafers FROM lot)` 的錯誤碼？
(A) ORA-00979　(B) ORA-01427　(C) ORA-01722　(D) ORA-00918

**Q17.** `WHERE lot_id NOT IN (SELECT x FROM t)` 若子查詢結果含 NULL，會回傳？
(A) 排除 NULL 後的結果　(B) 全部列　(C) 0 列　(D) 錯誤

**Q18.** `qty_wafers > ANY (SELECT qty_wafers FROM lot WHERE priority='NORMAL')`（值為 3,3,2）等價於？
(A) `> 3`　(B) `> 2`　(C) `>= 3`　(D) `> 5`

**Q19.** 關於簡單視圖（simple view），下列何者正確？
(A) 可以 INSERT/UPDATE/DELETE
(B) 一定不能 DML
(C) 只能 SELECT DISTINCT
(D) 一定含 GROUP BY

**Q20.** `GROUP BY ROLLUP(step_name)` 的總計列中，`step_name` 為 NULL。要用什麼區分它與「真正的 NULL」？
(A) `NVL(step_name,'TOTAL')`
(B) `GROUPING(step_name)`
(C) `COUNT(*)`
(D) `DECODE(step_name, NULL, …)`

---

## 答案與解析

| 題 | 答 | 解析 |
|---|---|---|
| Q1 | B | `<> NULL` 恆為 UNKNOWN，0 列 |
| Q2 | B | Oracle 的 `''` 等於 NULL，比較 NULL 永不成立 → 0 列（不報錯） |
| Q3 | B | DISTINCT 作用在**整組欄位**，4 是組合數 |
| Q4 | C | 單引號是字串字面值，不能當別名 → ORA-00923；A（雙引號）與 B（不加引號，AL32UTF8）都合法 |
| Q5 | A | DESC 時 NULL（視為最大）排最前 |
| Q6 | B | ROUND 為 half away from zero；TRUNC 無條件截斷 |
| Q7 | B | 從尾端第 3 個字元起取 2 個 → `DE` |
| Q8 | C | 從位置 5 開始找第二個 `-` → 位置 7；找不到會回 0 |
| Q9 | C | NVL 會嘗試把字串轉成 TIMESTAMP，轉不動 → ORA-01858 |
| Q10 | C | DECODE 視兩個 NULL 為相等；CASE 的 `= NULL` 是 UNKNOWN |
| Q11 | C | RR 的 50–99 且目前年份在 00–49 → 上一世紀 1951；YY 一律當世紀 2051 |
| Q12 | B | `9` 留前導空白、`0` 補零；兩者小數位都跟格式模型一致 |
| Q13 | B | 沒有 GROUP BY 混用欄位與群組函數 → ORA-00937（有 GROUP BY 但欄位不在其中才是 ORA-00979） |
| Q14 | B | HAVING 可無 GROUP BY；WHERE 不能過濾群組函數；ORDER BY 可用群組函數 |
| Q15 | B | LEFT JOIN 下右表全 NULL 仍算一列 → `COUNT(*)` = 1，要用 `COUNT(右表欄位)` |
| Q16 | B | 單列比較配多列子查詢 → ORA-01427；改 `IN` |
| Q17 | C | NOT IN 遇到 NULL 永遠不成立 → 0 列 |
| Q18 | B | `> ANY` = 大於最小值 2 |
| Q19 | A | 單一基表、無函數/群組/DISTINCT → 可 DML |
| Q20 | B | `GROUPING(col)` = 1 表示該 NULL 是小計／總計造成的 |

## 評分
- 90–100：可以報考 1Z0-071
- 75–89：把錯的章節複習一次
- 60–74：重做該章練習
- < 60：把 M2–M9 的練習重跑一輪
