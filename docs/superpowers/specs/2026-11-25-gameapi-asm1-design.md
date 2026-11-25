# GameApi ASM1 design

**Intent:** Tạo ASP.NET Core Web API đăng ký/đăng nhập và quản lý nhân vật, kết nối MySQL, chạy 12 ca thử nghiệm theo Mục 13 của đề GAM106.

**Source of truth:** Đặc tả đầy đủ trong yêu cầu của người dùng. File PDF không có trong `E:\SQL_ASM1`; danh sách TC01–TC12 được suy từ các thông báo và luồng được cite trong yêu cầu.

**Goals:** đúng 5 thư mục ngang (`Models`, `Data`, `DTOs`, `Services`, `Controllers`), Controller không dùng `AppDbContext`, JWT có 2 claim, thông báo lỗi tiếng Việt khớp đề, hash mật khẩu `AQAAAA...`, migration `InitialCreate`.

**Non-goals:** phân quyền Admin/Player, refresh token, logout, quên mật khẩu, gửi email, chia module theo tính năng, endpoint GET.

## Constraints

- DB: `server=localhost;port=3306;database=game_asm1_demo;user=root;password=123456`.
- `Jwt:Key`: `Gam106_Asm1_SecretKey_2026_MustBeAtLeast32Chars!`.
- Chỉ .NET SDK 10.0.401 cài đặt → target `net10.0`.
- Không có gói Pomelo/EFCore major 10 trên nuget.org → dùng major 9 cho Pomelo, EF Design, JwtBearer. Swashbuckle `6.9.0`.
- `dotnet-ef` chưa cài → cài global tool version `9.0.23`; nếu tool thiếu runtime 8/9, dùng `DOTNET_ROLL_FORWARD=Major`.
- Không có repo Git → không tạo worktree/commit; dùng ledger file để ghi tiến độ.

## Approach

Đơn luồng `Controller -> Service -> DbContext -> MySQL`. Service trả `null` cho thất bại nghiệp vụ; Controller dịch `null` thành `401/404/409`. DTO chỉ chứa dữ liệu công khai. Hash bằng `PasswordHasher<Account>`. Migration sinh bằng `dotnet ef`, app gọi `Database.Migrate()` lúc startup.

Phương án khác bị loại: gọi `AppDbContext` trực tiếp trong Controller (vi phạm luồng đề), tự tạo bảng bằng SQL thủ công (không có migration), chia feature folder (vi phạm cấu trúc 5 thư mục).

## Test cases (suy từ đề, chạy đúng thứ tự)

| Case | Hành động | Kết quả |
| --- | --- | --- |
| TC01 | Đăng ký hợp lệ | 201, `id > 0`, `username` đúng |
| TC02 | Đăng ký trùng username | 409, `Tên đăng nhập đã tồn tại` |
| TC03 | Đăng ký username/password ngắn | 400 |
| TC04 | Đăng nhập đúng | 200, token + username |
| TC05 | Đăng nhập sai mật khẩu | 401, `Sai tên đăng nhập hoặc mật khẩu` |
| TC06 | Đăng nhập sai username | 401, thông báo như TC05 |
| TC07 | Gọi API nhân vật không có token | 401 |
| TC08 | Tạo nhân vật hợp lệ | 201, level 1, hp 100, accountId đúng |
| TC09 | Tạo nhân vật tên 1 ký tự | 400 |
| TC10 | Sửa nhân vật của mình | 200, dữ liệu cập nhật |
| TC11 | Sửa nhân vật của tài khoản khác | 404, `Không tìm thấy nhân vật của bạn` |
| TC12 | Sửa nhân vật không tồn tại | 404, thông báo như TC11 |
| EX1 | Sửa thiếu `level` hoặc `hp` | 400 |
| EX2 | Query MySQL `PasswordHash` | Bắt đầu `AQAAAA` |

## Open decisions settled by builder

- `net10.0` + EF/Pomelo major 9: chỉ SDK 10 tồn tại trên máy; EF major 9 chạy được trên runtime 10.
- TC07 dùng `POST /api/characters` không token vì đề không yêu cầu endpoint GET.
- Test script tự tạo username có suffix thời gian để chạy lại nhiều lần.
