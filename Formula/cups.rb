class Cups < Formula
  desc "Standards-based, open source printing system"
  homepage "https://www.cups.org"
  url "https://github.com/apple/cups/archive/v2.2.8.tar.gz"
  sha256 "8f87157960b9d80986f52989781d9de79235aa060e05008e4cf4c0a6ef6bca72"

  depends_on "zlib"

  def install
    system "./configure", "--disable-debug",
                          "--prefix=#{prefix}",
                          "--exec-prefix=#{prefix}",
                          "--with-rcdir=#{prefix}/etc",
                          "--with-menudir=#{share}/applications",
                          "--with-icondir=#{share}/icons"
    system "make", "install"
  end

  test do
    # TODO: write test case(s)
    system "false"
  end
end
