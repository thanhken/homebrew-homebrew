class Crossy < Formula
  desc "Ghi thời điểm chạy hiện tại vào một field trong file plist, tự động mỗi ngày"
  homepage "https://iamken.work"
  url "https://github.com/thanhken/homebrew-homebrew/releases/download/crossy-v1.0.0/crossy"
  version "1.0.0"
  sha256 "dbcbc592094fb7280ba9af68dce274b656bcad008c7d76d379513ca59917c276"

  def install
    bin.install "crossy"
    (bin/"crossy").chmod 0755
  end

  # Chạy ngay một lần lúc cài để sinh config mặc định, kể cả khi người dùng
  # chưa bật service. Thao tác idempotent nên chạy thừa không sao.
  def post_install
    system opt_bin/"crossy"
  rescue
    nil
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
      Cấu hình (đường dẫn plist + tên key):
        ~/.config/crossy/config

      Bật chạy tự động (mỗi lần login + mỗi 24h):
        brew services start crossy

      Chạy tay bất cứ lúc nào:
        crossy
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
