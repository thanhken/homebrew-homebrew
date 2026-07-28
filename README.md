# homebrew-homebrew

Homebrew tap cá nhân của [@thanhken](https://github.com/thanhken), chứa vài tool nhỏ cho macOS.

```bash
brew tap thanhken/homebrew
```

Tên tap là `thanhken/homebrew` (Homebrew tự bỏ tiền tố `homebrew-` khỏi tên repo).

| Tool | Việc nó làm |
|---|---|
| [`crossy`](#crossy) | Ghi thời điểm hiện tại vào một field trong file plist, tự động mỗi ngày |
| [`zalo-login-item-remover`](#zalo-login-item-remover) | Xóa Zalo khỏi danh sách khởi động cùng máy, mỗi lần Zalo tự thêm lại |

---

## crossy

Cập nhật một field trong file plist bằng thời điểm chạy hiện tại. File chưa có thì tự tạo, đã có thì giữ nguyên mọi key khác và chỉ sửa đúng field được cấu hình.

Không có CLI, không có tham số — chạy là làm.

### Cài đặt

```bash
brew install thanhken/homebrew/crossy
brew services start crossy
```

Service chạy ngay lúc start, lặp lại mỗi lần login và mỗi 24 giờ.

### Cấu hình

Toàn bộ cấu hình nằm trong một file, tự sinh ở lần chạy đầu tiên:

```
~/.config/crossy/config
```

```sh
# Đường dẫn tới file plist cần ghi.
# Dùng $HOME thay vì gõ cứng /Users/<tên-user>.
PLIST="$HOME/Library/Preferences/com.example.app.plist"

# Tên key cần cập nhật.
KEY="LastRun"

# Kiểu dữ liệu: date | string | integer | bool | float
TYPE="date"

# Format thời gian (tham số của lệnh `date`).
# Chỉ có tác dụng khi TYPE="string".
FORMAT="%Y-%m-%dT%H:%M:%S%z"
```

Sửa xong không cần restart service — script đọc lại file mỗi lần chạy.

### Hai chế độ ghi

crossy tự chọn công cụ ghi dựa trên vị trí file plist:

| Vị trí `PLIST` | Ghi bằng | Key lồng nhau |
|---|---|---|
| Trong `~/Library/Preferences/` | `defaults` | Không hỗ trợ |
| Chỗ khác (vd `Application Support/`) | `plutil` | Có — ngăn cách bằng dấu chấm: `Muc.Con` |

Plist trong `Preferences/` **bắt buộc** phải ghi qua `defaults`: `cfprefsd` giữ bản cache trong RAM và sẽ ghi đè lại file nếu sửa trực tiếp trên đĩa, khiến thay đổi biến mất mà không báo lỗi gì.

Với `TYPE="date"`, crossy luôn ghi mốc UTC chuẩn ISO 8601 và bỏ qua `FORMAT`. Đây không phải tùy chọn thẩm mỹ: `defaults -date` không parse offset múi giờ mà nuốt luôn phần `+0700` làm năm, biến `2026-07-28T23:00:00+0700` thành năm `0700` — sai hoàn toàn mà vẫn thoát với mã 0.

### Chưa hỗ trợ

- Plist trong `~/Library/Preferences/ByHost/` (tên file kèm UUID phần cứng, cần `defaults -currentHost`)
- Plist cấp hệ thống trong `/Library/Preferences/` (thuộc root, cần LaunchDaemon chạy bằng sudo)

Cả hai trường hợp crossy đều dừng và báo lỗi rõ ràng thay vì ghi sai chỗ.

### Kiểm tra

```bash
crossy                                    # chạy tay ngay lập tức
brew services info crossy                 # trạng thái service
tail -f "$(brew --prefix)/var/log/crossy.log"
```

### Gỡ

```bash
brew services stop crossy
brew uninstall crossy
rm -rf ~/.config/crossy                   # xóa config nếu muốn
```

---

## zalo-login-item-remover

Zalo tự thêm mình vào Login Items mỗi lần khởi động, kể cả sau khi bạn xóa đi. Tool này theo dõi file log khởi động của Zalo, và cứ mỗi lần Zalo chạy thì xóa nó khỏi Login Items.

### Yêu cầu

- macOS trên Apple Silicon — đường dẫn binary trong launch agent đang gõ cứng `/opt/homebrew/bin`, máy Intel dùng `/usr/local` sẽ không chạy.

### Cài đặt

```bash
brew install thanhken/homebrew/zalo-login-item-remover
```

Formula tự gọi `--setup` sau khi cài, nên bình thường không phải làm gì thêm. Chạy lại thủ công nếu cần:

```bash
zalo-login-item-remover --setup
```

Lệnh này tạo `~/Library/LaunchAgents/com.zalo.login-item-remover.plist` rồi `launchctl load` nó. Agent dùng `WatchPaths` trỏ vào `~/Library/Application Support/ZaloData/startup.log` — hễ Zalo ghi log khởi động là tool được đánh thức.

### Cấp quyền

Tool xóa login item bằng AppleScript qua System Events, nên lần chạy đầu macOS sẽ hỏi quyền Automation. Phải bấm cho phép, không thì tool im lặng không làm gì.

Kiểm tra lại ở **System Settings → Privacy & Security → Automation**.

### Kiểm tra

```bash
launchctl list | grep zalo
osascript -e 'tell application "System Events" to get the name of every login item'
```

### Gỡ

Chạy `--uninstall` **trước** khi `brew uninstall` — Homebrew không có hook chạy lúc gỡ cài đặt, nên launch agent sẽ nằm lại nếu bỏ qua bước này:

```bash
zalo-login-item-remover --uninstall
brew uninstall zalo-login-item-remover
```

---

## Phát triển

```
Formula/     formula của từng tool
Sources/     mã nguồn
```

Formula trỏ trực tiếp vào file trong release asset, không phải tarball. Quy trình phát hành:

```bash
# 1. Sửa code trong Sources/
# 2. Tính lại checksum, cập nhật `sha256` trong formula
shasum -a 256 Sources/<tool>

# 3. Tag riêng cho từng tool vì repo chứa nhiều tool
gh release create <tool>-v1.0.1 Sources/<tool>

# 4. Cập nhật `url` và `version` trong formula rồi push
```

Sửa code mà quên cập nhật `sha256` thì người dùng sẽ gặp lỗi checksum mismatch lúc cài.

Kiểm tra formula trước khi push:

```bash
brew style Formula/                        # lint, có --fix để tự sửa
brew audit --strict --online thanhken/homebrew/<tool>
brew test <tool>                           # chạy khối `test do` sau khi đã cài
```
