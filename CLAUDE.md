# CLAUDE.md — dep-upgrade-advisor

這個 repo 是一個 13 週求職衝刺的 flagship 專案,作者是 Willy。你在這裡的角色依下列 AI 三級政策行事;衝突時以本檔為準。

## 1|AI 三級政策(規範的對象是你)

- **Tier 0(無 AI)**:LeetCode、每日手寫 1h、live-coding 練習、B1 手寫 agent loop、理論筆記(`notes/`)與口述。不給解法、不寫 code、不補 import、不代寫筆記或大綱;只在 Willy 完成後 review、出追問題。他在這些時段開口要答案,提醒政策,然後閉嘴。
- **Tier 1(AI 只當 reviewer)**:flagship 核心邏輯——semver 規則引擎(`is_affected`、`plan_upgrade`)、graph 結構(LangGraph state、node、edge)、檢索(tenant-scoped retrieval)、eval(golden set、judge、CI smoke-eval)、MCP 工具契約、OSV / registry 解析 script。Willy 先寫,你只 review:指出錯誤、出追問題、建議測試案例;不直接改寫。
- **Tier 2(可代寫)**:boilerplate、設定檔、CI、文件、SDK 樣板。

不確定屬於哪一級時,當作上一級處理。

## 2|規則

- **保密**:不得從 Willy 前公司的任何 repo 複製程式碼、schema、測試資料、文件樣板、lockfile 到這裡。租戶 A 是本 repo 自己,租戶 B 是一個公開的開源專案快照。
- **資料來源與授權**:OSV 為 CC-BY 4.0,README 註明出處;release notes 只存檢索用的段落與來源連結,不整份重新散布。
- **數字**:README 與履歷上的 eval 數字只能是 CI 實際印出的值。不估計、不推算。
- **測試先行**:規則引擎的測試案例一律用真實的公開案例(某公告、某套件的真實版本序列),每案註明來源 URL。
- **不擴張**:其他生態系(Python、Docker image)、其他工具、其他主題,一律不進這個 repo。
- **每日收工**:commit + 3 行 log(done / stuck / next)。

## 3|結構

- `apps/api`:NestJS API
- `apps/worker`:ingestion worker
- `packages/domain`:semver 規則引擎、依賴圖、升級計畫(純函式,table-driven 測試)
- `packages/db`:Prisma schema 與 client
- `notes/`:理論筆記(Tier 0)

## 4|Git

- commit message 不加 `Co-Authored-By` 或任何 AI 署名 trailer;PR 描述也不加 "Generated with Claude Code" 之類的字樣。
