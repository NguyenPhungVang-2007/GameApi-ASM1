# GameApi ASM1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dựng và chạy thông toàn bộ GameApi ASM1 theo đặc tả GAM106, kèm 14 ca kiểm thử tự động.

**Architecture:** Web API 5 thư mục ngang. Controller gọi Service, Service gọi `AppDbContext`, DbContext gọi MySQL. JWT bearer bảo vệ `CharactersController`. Migration `InitialCreate` do `dotnet ef` sinh.

**Tech Stack:** .NET 10, Pomelo 9.0.0, EF Core Design 9.0.23, JwtBearer 9.0.23, Swashbuckle 6.9.0, MySQL 26.10, PowerShell test harness.

**Spec:** `docs/superpowers/specs/2026-11-25-gameapi-asm1-design.md`

## Global Constraints

- Project name `GameApi`; thư mục `GameApi` với đúng `Models`, `Data`, `DTOs`, `Services`, `Controllers`, `Migrations`.
- Xóa `WeatherForecast.cs` và controller mẫu.
- Connection string: `server=localhost;port=3306;database=game_asm1_demo;user=root;password=123456`.
- `Jwt:Key`: `Gam106_Asm1_SecretKey_2026_MustBeAtLeast32Chars!`.
- Cookie/JWT: HmacSha256, hạn 1 ngày, claim `ClaimTypes.NameIdentifier` và `ClaimTypes.Name`.
- `PasswordHasher<Account>`; DTO không chứa `PasswordHash`.
- Thông báo: `Tên đăng nhập đã tồn tại`, `Sai tên đăng nhập hoặc mật khẩu`, `Không tìm thấy nhân vật của bạn`.
- Middleware: `UseSwagger()`, `UseSwaggerUI()`, `UseAuthentication()`, `UseAuthorization()`, `MapControllers()` theo thứ tự.
- Không phân quyền, refresh token, logout, quên mật khẩu, email, feature module, endpoint GET.

## Review Focus

| Rủi ro | Ca kiểm thử |
| --- | --- |
| Trùng username vẫn cho đăng ký | TC02 |
| Sai mật khẩu / sai username lộ khác biệt | TC05, TC06 |
| Sửa nhân vật của người khác | TC11 |
| Thiếu `level`/`hp` vẫn sửa được | EX1 |
| Lưu mật khẩu gốc thay vì hash | EX2 |
| Gọi API nhân vật không token | TC07 |

---

### Task 1: Scaffold, packages, config

**Files:** Create `GameApi/GameApi.csproj`, `GameApi/appsettings.json`, `GameApi/appsettings.Development.json`, `GameApi/Program.cs` (minimal template); Delete template sample files.

**Interfaces:**
- Produces: project target `net10.0` và 4 gói NuGet đã cài.

- [ ] **Step 1:** `dotnet new webapi -n GameApi -o GameApi --framework net10.0 --no-https`; xóa `WeatherForecast.cs` và `Controllers/WeatherForecastController.cs`.
- [ ] **Step 2:** Cài `Pomelo.EntityFrameworkCore.MySql` `9.0.0`, `Microsoft.EntityFrameworkCore.Design` `9.0.23`, `Microsoft.AspNetCore.Authentication.JwtBearer` `9.0.23`, `Swashbuckle.AspNetCore` `6.9.0`.
- [ ] **Step 3:** Ghi `appsettings.json` với connection string và `Jwt:Key` đúng giá trị đề.
- [ ] **Step 4:** `dotnet build GameApi/GameApi.csproj` → `Build succeeded`, 0 error.
- [ ] **Step 5:** Cài `dotnet-ef` global tool `9.0.23`; ghi ledger cấu hình `DOTNET_ROLL_FORWARD=Major` nếu tool cần.

### Task 2: Failing acceptance harness (RED)

**Files:** Create `tests/run-all.ps1`.

**Interfaces:**
- Consumes: server `http://localhost:5080` chưa chạy.
- Produces: 14 case TC01–TC12 + EX1 + EX2; exit code 0 khi tất cả đạt.

- [ ] **Step 1:** Viết script dùng `Invoke-WebRequest -UseBasicParsing`, helper bắt ngoại lệ để đọc status/body cho 4xx, username có suffix `yyyyMMddHHmmss`, lưu token/id vào biến giữa các ca.
- [ ] **Step 2:** Chạy `powershell -NoProfile -File tests/run-all.ps1` với server chưa chạy → FAIL ở TC01 với lỗi kết nối; ghi RED vào ledger.

### Task 3: Models, DbContext, migration

**Files:** Create `GameApi/Models/Account.cs`, `GameApi/Models/Character.cs`, `GameApi/Data/AppDbContext.cs`, `GameApi/Migrations/*`.

**Interfaces:**
- Consumes: package từ Task 1.
- Produces: `AppDbContext(Account)`/`AppDbContext(Character)` và 2 bảng có unique `Username`, cascade `AccountId`.

- [ ] **Step 1:** Viết model theo đúng tên/kieu/ràng buộc đề; navigation `ICollection<Character> Characters`, `Account? Account`.
- [ ] **Step 2:** Viết `AppDbContext` với 2 `DbSet`, cấu hình độ dài, unique index, quan hệ 1–n cascade.
- [ ] **Step 3:** Chạy `dotnet ef migrations add InitialCreate --project GameApi/GameApi.csproj --startup-project GameApi/GameApi.csproj` → migration sinh ra.
- [ ] **Step 4:** Chạy app một lần hoặc `dotnet ef database update` → bảng tồn tại; kiểm tra bằng `mysql -e "SHOW TABLES;"`.

### Task 4: DTOs, services, controllers, wiring

**Files:** Create 7 file `GameApi/DTOs/*.cs`, `GameApi/Services/AuthService.cs`, `GameApi/Services/CharacterService.cs`, `GameApi/Controllers/AuthController.cs`, `GameApi/Controllers/CharactersController.cs`; Replace `GameApi/Program.cs`.

**Interfaces:**
- Consumes: `AppDbContext` từ Task 3, cấu hình Task 1.
- Produces: `AuthService.RegisterAsync`, `AuthService.LoginAsync`, `CharacterService.CreateAsync`, `CharacterService.UpdateAsync`; route `api/auth/register`, `api/auth/login`, `api/characters`, `api/characters/{id}`.

- [ ] **Step 1:** Viết DTO có đúng attribute và kiểu `int?` cho `Level`/`Hp` trong `UpdateCharacterRequest`.
- [ ] **Step 2:** Viết `AuthService`: trùng username → `null`; hash/verify bằng `PasswordHasher<Account>`; đúng thì trả JWT 1 ngày với 2 claim.
- [ ] **Step 3:** Viết `CharacterService`: tạo với level 1/hp 100; sửa chỉ khi `AccountId` khớp, ngược lại `null`.
- [ ] **Step 4:** Viết Controller: lấy `accountId` bằng `User.FindFirstValue(ClaimTypes.NameIdentifier)`; map `null` → 409/401/404.
- [ ] **Step 5:** Program: DbContext `UseMySql`, `Migrate()`, JWT auth, Swagger Bearer, DI scoped, middleware đúng thứ tự.
- [ ] **Step 6:** `dotnet build` → 0 error.

### Task 5: GREEN, DB check, Swagger

**Files:** Modify `tests/run-all.ps1` chỉ nếu phát hiện sai thiết kế; ledger `docs/superpowers/progress.md`.

- [ ] **Step 1:** Chạy server `dotnet run --project GameApi --urls http://localhost:5080` nền.
- [ ] **Step 2:** Chạy `powershell -NoProfile -File tests/run-all.ps1` → 14/14 PASS; đọc từng dòng output.
- [ ] **Step 3:** Query MySQL kiểm tra hash `AQAAAA...` và không có mật khẩu gốc.
- [ ] **Step 4:** `curl http://localhost:5080/swagger/v1/swagger.json` → chứa `Bearer` security scheme; ghi kết quả cuối vào ledger.
