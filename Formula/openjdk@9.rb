# Documentation: https://docs.brew.sh/Formula-Cookbook
#                http://www.rubydoc.info/github/Homebrew/brew/master/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class OpenjdkAT9 < Formula
  desc "Java Development Kit"
  homepage "http://openjdk.java.net/"
  version "9.0.4+12"
  url "http://hg.openjdk.java.net/jdk-updates/jdk9u/archive/1b1226687b89.tar.gz"
  sha256 "57568549590e654b6e21737a1b64fefc2e4ca04d13f50c629d2c906cf694f7a6"

  depends_on "jdk" => :build
  depends_on "linuxbrew/xorg/libxau" => :build
  depends_on "linuxbrew/xorg/libxcb" => :build
  depends_on "linuxbrew/xorg/libx11"
  depends_on "linuxbrew/xorg/libxi"
  depends_on "linuxbrew/xorg/libxdmcp" => :build
  depends_on "linuxbrew/xorg/libsm" => :build
  depends_on "linuxbrew/xorg/xtrans" => :build
  depends_on "linuxbrew/xorg/xorg" => :build
  depends_on "linuxbrew/xorg/libxext"
  depends_on "linuxbrew/xorg/libxfixes" => :build
  depends_on "linuxbrew/xorg/libxrender"
  depends_on "linuxbrew/xorg/libxt" => :build
  depends_on "linuxbrew/xorg/libxtst"
  depends_on "linuxbrew/xorg/libice" => :build
  depends_on "linuxbrew/xorg/libpthread-stubs" => :build
  depends_on "linuxbrew/xorg/fixesproto" => :build
  depends_on "linuxbrew/xorg/inputproto" => :build
  depends_on "linuxbrew/xorg/kbproto" => :build
  depends_on "linuxbrew/xorg/recordproto" => :build
  depends_on "linuxbrew/xorg/renderproto" => :build
  depends_on "linuxbrew/xorg/xextproto" => :build
  depends_on "linuxbrew/xorg/xorg-sgml-doctools" => :build
  depends_on "alsa-lib"
  depends_on "freetype"
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libelf"
  depends_on "libffi" => :build
  depends_on "cups" => :build
  depends_on "zlib"

  resource "corba" do
    url "http://hg.openjdk.java.net/jdk-updates/jdk9u/corba/archive/dc23e0c17719.tar.gz"
    sha256 "a7a30d1dbd22128381daafdd0c129a532690a47c15b5a51676c16b87722a4dfa"
  end

  resource "hotspot" do
    url "http://hg.openjdk.java.net/jdk-updates/jdk9u/hotspot/archive/22d7a88dbe78.tar.gz"
    sha256 "0f83b08ac8cd77a8ebc9e5d0f52ee306d641a957a7dd0fd44b81ce367397aee1"
  end

  resource "jaxp" do
    url "http://hg.openjdk.java.net/jdk-updates/jdk9u/jaxp/archive/cef904a4a03d.tar.gz"
    sha256 "98197e4055151154b8c6bcf9a5af2cac870f453fcb5ffcacfa96bdc3d8935c84"
  end

  resource "jaxws" do
    url "http://hg.openjdk.java.net/jdk-updates/jdk9u/jaxws/archive/da3398a70e2f.tar.gz"
    sha256 "d067554a27a8da40cdbb4b8176fb69611beab79e96ee01101cbccbcde902cccd"
  end

  resource "jdk" do
    url "http://hg.openjdk.java.net/jdk-updates/jdk9u/jdk/archive/d54486c189e5.tar.gz"
    sha256 "448c794188bd7604c958b82250dc74d42e4a1175c2f09f05aa3b287d05aeb14e"
  end

  resource "langtools" do
    url "http://hg.openjdk.java.net/jdk-updates/jdk9u/langtools/archive/a1c9ab610f6f.tar.gz"
    sha256 "c29466500465c1effdeea1ef5c05e659c06a1a4f034f353e6a031c88323c8ae1"
  end

  resource "nashorn" do
    url "http://hg.openjdk.java.net/jdk-updates/jdk9u/nashorn/archive/1d03f7058e2b.tar.gz"
    sha256 "5f1cc8e79f372a5967a4dc2011a18d4cccba22b2ac9ab6611ed8f8a1f5d491f4"
  end

  def install
    # The makefile does not support "make -jN"
    # TODO: Figure out how to pass in job number as "make JOBS=N"
    ENV.deparallelize

    resource("corba").stage buildpath/"corba"
    resource("hotspot").stage buildpath/"hotspot"
    resource("jaxp").stage buildpath/"jaxp"
    resource("jaxws").stage buildpath/"jaxws"
    resource("jdk").stage buildpath/"jdk"
    resource("langtools").stage buildpath/"langtools"
    resource("nashorn").stage buildpath/"nashorn"

    # The configure wrapper from the archive does not have the exec bit set
    chmod 0755, "./configure"

    # The configure script checks the first line of output from "java -version"
    # to determine the version of the bootstrap JDK we're using. With the env
    # variable set, the first line of output instead becomes a note that the
    # environment variable was picked up. Remove it to allow proper JDK version
    # detection.
    ENV.delete("_JAVA_OPTIONS")
    system "./configure", "--with-debug-level=release"
    system "make", "images"
    
    # The configure script does not respect --prefix=, so we have to install
    # things manually.
    cd buildpath/"build/linux-x86_64-normal-server-release/images/jdk" do
      prefix.install "bin", "conf", "include", "jmods", "legal", "lib", "release"
      share.install "man"
    end

  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test openjdk-9`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end
end
