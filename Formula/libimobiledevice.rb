class Libimobiledevice < Formula
  desc "Library to communicate with iOS devices natively"
  homepage "http://www.libimobiledevice.org/"
  url "http://www.libimobiledevice.org/downloads/libimobiledevice-1.2.0.tar.bz2"
  sha1 "a8e3f21180b1d6df754d04a4080a29cf6891e701"

  bottle do
    cellar :any
    sha1 "7e4b860af3e151499c8444cd5617033dc696e228" => :yosemite
    sha1 "9db2d736d715cc8ea6af1f3c95679679792a5c25" => :mavericks
    sha1 "9f7786afecdd2b7ad55b92d5713dc8ade9d012fe" => :mountain_lion
  end

  head do
    url "http://git.sukimashita.com/libimobiledevice.git"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
    depends_on "libxml2"
  end

  depends_on "pkg-config" => :build
  depends_on "libtasn1"
  depends_on "libplist"
  depends_on "usbmuxd"
  depends_on "openssl"

  def install
    system "./autogen.sh" if build.head?
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          # As long as libplist builds without Cython
                          # bindings, libimobiledevice must as well.
                          "--without-cython"
    system "make install"
  end
end
