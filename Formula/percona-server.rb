class PerconaServer < Formula
  desc "Drop-in MySQL replacement"
  homepage "https://www.percona.com"
  url "https://www.percona.com/downloads/Percona-Server-5.7/Percona-Server-5.7.22-22/source/tarball/percona-server-5.7.22-22.tar.gz"
  sha256 "3b94644861628fa6e17b82318220327f0beb2767739c976c961c8a9eb6c9783a"

  bottle do
    sha256 "939d9bf211128159aa8fa8063d5a2444f018c9f4c957c12aff8dfb8fbcc36d77" => :mojave
    sha256 "b532aa8c191442279c499bf270ab0dbccbaf7f5e54cfc9540a3d825436c55e7d" => :high_sierra
    sha256 "598e49c07d52132f8293474c57449ca4f8f92a755edb356909be3ddb51b46a1a" => :sierra
    sha256 "8d4b7018c451090ba8af05928eee7d082f9986211ed3dc9eaf83010456a3bd5b" => :el_capitan
  end

  depends_on "cmake" => :build
  depends_on "openssl"
  unless OS.mac?
    depends_on "readline"
    depends_on "libedit"
  end

  # https://github.com/Homebrew/homebrew-core/issues/1475
  # Needs at least Clang 3.3, which shipped alongside Lion.
  # Note: MySQL themselves don't support anything below El Capitan.
  depends_on :macos => :lion

  conflicts_with "mariadb", "mysql", "mysql-cluster",
    :because => "percona, mariadb, and mysql install the same binaries."
  conflicts_with "mysql-connector-c",
    :because => "both install MySQL client libraries"
  conflicts_with "mariadb-connector-c",
    :because => "both install plugins"

  resource "boost" do
    url "https://downloads.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.bz2"
    sha256 "727a932322d94287b62abb1bd2d41723eec4356a7728909e38adb65ca25241ca"
  end

  # Where the database files should be located. Existing installs have them
  # under var/percona, but going forward they will be under var/mysql to be
  # shared with the mysql and mariadb formulae.
  def datadir
    @datadir ||= (var/"percona").directory? ? var/"percona" : var/"mysql"
  end

  pour_bottle? do
    reason "The bottle needs a var/mysql datadir (yours is var/percona)."
    satisfy { datadir == var/"mysql" }
  end

  def install
    # Reduce memory usage below 4 GB for Circle CI.
    ENV["MAKEFLAGS"] = "-j8" if ENV["CIRCLECI"]

    # Set HAVE_MEMSET_S flag to fix compilation
    # https://bugs.launchpad.net/percona-server/+bug/1741647
    ENV.prepend "CPPFLAGS", "-DHAVE_MEMSET_S=1" if OS.mac?

    # https://dev.mysql.com/doc/refman/5.7/en/source-configuration-options.html
    # -DINSTALL_* are relative to `CMAKE_INSTALL_PREFIX` (`prefix`)
    args = %W[
      -DCOMPILATION_COMMENT=Homebrew
      -DDEFAULT_CHARSET=utf8
      -DDEFAULT_COLLATION=utf8_general_ci
      -DCOMPILATION_COMMENT=Homebrew
      -DINSTALL_DOCDIR=share/doc/#{name}
      -DINSTALL_INCLUDEDIR=include/mysql
      -DINSTALL_INFODIR=share/info
      -DINSTALL_MANDIR=share/man
      -DINSTALL_MYSQLSHAREDIR=share/mysql
      -DINSTALL_PLUGINDIR=lib/plugin
      -DMYSQL_DATADIR=#{datadir}
      -DSYSCONFDIR=#{etc}
      -DWITH_EDITLINE=system
      -DWITH_SSL=yes
    ]
    args << "-DWITH_EDITLINE=system" if OS.mac?

    # MySQL >5.7.x mandates Boost as a requirement to build & has a strict
    # version check in place to ensure it only builds against expected release.
    # This is problematic when Boost releases don't align with MySQL releases.
    (buildpath/"boost").install resource("boost")
    args << "-DWITH_BOOST=#{buildpath}/boost"

    # Percona MyRocks does not compile on macOS
    # https://bugs.launchpad.net/percona-server/+bug/1741639
    args.concat %w[-DWITHOUT_ROCKSDB=1]

    # TokuDB does not compile on macOS
    # https://bugs.launchpad.net/percona-server/+bug/1531446
    args.concat %w[-DWITHOUT_TOKUDB=1]

    args << "-DWITH_UNIT_TESTS=OFF"

    system "cmake", ".", *std_cmake_args, *args
    system "make"
    system "make", "install"

    (prefix/"mysql-test").cd do
      system "./mysql-test-run.pl", "status", "--vardir=#{Dir.mktmpdir}"
    end if OS.mac?
    # Test is disabled on Linux as it is currently failing

    # Remove the tests directory
    rm_rf prefix/"mysql-test"

    # Don't create databases inside of the prefix!
    # See: https://github.com/Homebrew/homebrew/issues/4975
    rm_rf prefix/"data"

    # Fix up the control script and link into bin.
    inreplace "#{prefix}/support-files/mysql.server",
              /^(PATH=".*)(")/,
              "\\1:#{HOMEBREW_PREFIX}/bin\\2"
    bin.install_symlink prefix/"support-files/mysql.server"

    # Install my.cnf that binds to 127.0.0.1 by default
    (buildpath/"my.cnf").write <<~EOS
      # Default Homebrew MySQL server config
      [mysqld]
      # Only allow connections from localhost
      bind-address = 127.0.0.1
    EOS
    etc.install "my.cnf"
  end

  def post_install
    # Make sure the datadir exists
    datadir.mkpath
    unless (datadir/"mysql/user.frm").exist?
      ENV["TMPDIR"] = nil
      system bin/"mysqld", "--initialize-insecure", "--user=#{ENV["USER"]}",
        "--basedir=#{prefix}", "--datadir=#{datadir}", "--tmpdir=/tmp"
    end
  end

  def caveats
    s = <<~EOS
      We've installed your MySQL database without a root password. To secure it run:
          mysql_secure_installation
      MySQL is configured to only allow connections from localhost by default
      To connect run:
          mysql -uroot
    EOS
    if my_cnf = ["/etc/my.cnf", "/etc/mysql/my.cnf"].find { |x| File.exist? x }
      s += <<~EOS
        A "#{my_cnf}" from another install may interfere with a Homebrew-built
        server starting up correctly.
      EOS
    end
    s
  end

  plist_options :manual => "mysql.server start"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <true/>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_bin}/mysqld_safe</string>
        <string>--datadir=#{datadir}</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>WorkingDirectory</key>
      <string>#{datadir}</string>
    </dict>
    </plist>
  EOS
  end

  test do
    begin
      # Expects datadir to be a completely clean dir, which testpath isn't.
      dir = Dir.mktmpdir
      system bin/"mysqld", "--initialize-insecure", "--user=#{ENV["USER"]}",
      "--basedir=#{prefix}", "--datadir=#{dir}", "--tmpdir=#{dir}"

      pid = fork do
        exec bin/"mysqld", "--bind-address=127.0.0.1", "--datadir=#{dir}"
      end
      sleep 2

      output = shell_output("curl 127.0.0.1:3306")
      output.force_encoding("ASCII-8BIT") if output.respond_to?(:force_encoding)
      assert_match version.to_s, output
    ensure
      Process.kill(9, pid)
      Process.wait(pid)
    end
  end
end
