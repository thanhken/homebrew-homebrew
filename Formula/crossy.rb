class Crossy < Formula
  desc "Ghi thời điểm chạy hiện tại vào một field trong file plist, tự động mỗi ngày"
  homepage "https://iamken.work"
  url "https://github.com/thanhken/homebrew-homebrew/releases/download/crossy-v1.0.1/crossy"
  version "1.0.1"
  sha256 "7c4945208fe5271bac48a3ad9a90ecdf544cf04cbb2473eedd7fe93228a025a2"

  def install
    bin.install "crossy"
    (bin/"crossy").chmod 0755
  end

  service do
    run opt_bin/"crossy"
    # interval thay vì cron: launchd đặt RunAtLoad=true nên chắc chắn chạy mỗi lần
    # login, kể cả khi máy đã tắt qua mốc hẹn giờ. Đổi lại là không rơi đúng 00:00
    # mà trôi theo thời điểm login — không sao, vì giá trị ghi ra là giờ thực lúc chạy.
    run_type :interval
    interval 86_400
    log_path var/"log/crossy.log"
    error_log_path var/"log/crossy.err.log"
    environment_variables PATH: std_service_path_env
  end

  def caveats
    <<~EOS
      1. Chạy `crossy` một lần để sinh file cấu hình (lần này chưa ghi gì cả)

      2. Sửa đường dẫn plist và tên key trong:
           ~/.config/crossy/config

      3. Bật chạy tự động (mỗi lần login + mỗi 24h):
           brew services start crossy
    EOS
  end

  test do
    ENV["XDG_CONFIG_HOME"] = testpath/"cfg"
    ENV["HOME"] = testpath

    # Cố tình trỏ ra ngoài Preferences/: `defaults` phớt lờ $HOME và luôn ghi vào
    # thư mục nhà thật của user, nên nếu dùng config mặc định thì test sẽ bẩn máy.
    (testpath/"cfg/crossy").mkpath
    (testpath/"cfg/crossy/config").write <<~CFG
      PLIST="#{testpath}/probe.plist"
      KEY="LastRun"
      TYPE="date"
    CFG

    system bin/"crossy"
    assert_match "LastRun", shell_output("plutil -p #{testpath}/probe.plist")
  end
end
