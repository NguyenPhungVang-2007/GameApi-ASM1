# SDD ledger — plan: docs/superpowers/plans/2026-11-25-gameapi-asm1.md

Pre-flight: no shared interfaces beyond the explicit task sequence.
Ruling: no git repo in `E:\SQL_ASM1` — skip worktree and commits, keep this ledger as progress record — cost: no commit history to recover after compaction.
Ruling: PDF absent — use the prompt spec as authority and infer TC01–TC12 from cited behavior — cost: test case names may differ from PDF wording.
Ruling: only .NET 10 SDK installed and no Pomelo major 10 — target `net10.0` with Pomelo 9 / EF 9 packages — cost: no exact match to PDF's .NET 8 example versions.
Task 1: complete (scaffold `GameApi`, 4 packages, appsettings, template samples deleted; `dotnet build` → Build succeeded, 0 error, 1 NU1902 warning for transitive MySqlConnector 2.4.0 on loopback).
Task 2: RED verified (`powershell -File tests/run-all.ps1` → 14 FAIL, 0 PASS, reason server absent).
Ruling: PowerShell 5.1 misreads UTF-8 without BOM — test script saved with UTF-8 BOM — cost: editors that strip BOM must re-add it before rerun.
Task 3: complete (models, AppDbContext, `dotnet ef migrations add InitialCreate`, `database update`; MySQL shows accounts, characters, history row).
Task 4: complete (7 DTOs, 2 services, 2 controllers, full Program wiring; `dotnet build` → 0 error).
Task 5: complete (server on :5080, harness 14/14 PASS, MySQL hash `AQAAAA`, Swagger Bearer present).
Final review: subagent `general` reviewer; no Critical. Important 1: concurrent register returned 500 — fixed with `DbUpdateException`/MySqlException 1062 → null. RED `tests/race-check.ps1` → 39x500/1x201; GREEN → 39x409/1x201.
Final: fixed TC11 setup assertion — `setup_ok=True` now required — harness 14/14 PASS.
Final: minor (deferred): `int.Parse` on crafted nameid can 500; Swagger lacks response-type annotations; 1-second username suffix; unknown-user timing side channel; NU1902 warning on transitive MySqlConnector 2.4.0 (loopback, not exploitable here).
Final verification: `dotnet build` → 0 error; Swagger `/swagger/v1/swagger.json` 200 with Bearer; migration `20261125080755_InitialCreate` applied.
Ruling: user switched local DB to Microsoft SQL Server `.\SQLEXPRESS` (Windows auth) — swap provider, connection string, migration, duplicate catch and EX2 verifier; original MySQL assignment docs kept unchanged for reference — cost: submission must switch back to MySQL if PDF requires it.
Task 6: complete (SqlServer 9.0.23 replaces Pomelo 9.0.0; `UseSqlServer`; `SqlException 2627/2601` duplicate catch; MySQL migrations deleted, `20261125083617_InitialCreate` generated and applied; `dotnet build` → 0 error, 0 warning — NU1902 gone; harness 14/14 PASS; race-check 39x409/1x201, RACE_500=0; Swagger 200 with Bearer; sqlcmd confirms `AQAAAA...` hash).
Ruling: GitHub repo `GameApi-ASM1` created Public at user's choice despite JWT key exposure warning — cost: JWT key in `appsettings.json` is public; rotate or move to secrets before any real deployment.
Task 7: complete (`git init -b main`, root commit `d77c794` with 30 files, pushed to `https://github.com/NguyenPhungVang-2007/GameApi-ASM1`; 0 `bin`/`obj` artifacts; nested `GameApi/.git` contents backed up to `%TEMP%\GameApi-git-backup-20261125160246`, its commits already remote on `GameApi_GameBackEnd`).
