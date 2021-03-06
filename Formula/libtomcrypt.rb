class Libtomcrypt < Formula
  desc "Comprehensive, modular and portable cryptographic toolkit"
  homepage "https://www.libtom.net/"
  url "https://github.com/libtom/libtomcrypt/archive/v1.18.2.tar.gz"
  sha256 "d870fad1e31cb787c85161a8894abb9d7283c2a654a9d3d4c6d45a1eba59952c"

  bottle do
    cellar :any_skip_relocation
    sha256 "93de55d83b104750011920b2fa6b977605e6ff822563786d46d3e623ab1c7993" => :mojave
    sha256 "e7d2345a89bfd72ccb915ffd28dafcb18166a1ddf976bd026c6c2c13efc48cdc" => :high_sierra
    sha256 "3b0887710aa1aa5b8e352b6b02d742cb44a4b7bcf99bfd1f38cf1eeca16d77a8" => :sierra
    sha256 "9ecd9f9965864d6c58970ebd6d0c3b1871e38ef787ed8732ef12072a651fd3c3" => :el_capitan
    sha256 "b6eb7e499dc2296e6bb923f735cf0f380eb9e189640edd7d2a818fce51c23869" => :x86_64_linux
  end

  option "with-gmp", "enable gmp as MPI provider"
  option "with-libtommath", "enable libtommath as MPI provider"

  depends_on "gmp" => :optional
  depends_on "libtommath" => :optional

  def install
    if build.with? "gmp"
      ENV.append "CFLAGS", "-DUSE_GMP -DGMP_DESC"
      ENV.append "EXTRALIBS", "-lgmp"
    end
    if build.with? "libtommath"
      ENV.append "CFLAGS", "-DUSE_LTM -DLTM_DESC"
      ENV.append "EXTRALIBS", "-ltommath"
    end
    system "make", "test"
    system "make", "install", "PREFIX=#{prefix}"
    pkgshare.install "test"
    (pkgshare/"tests").install "tests/test.key"
  end

  test do
    cp_r Dir[pkgshare/"*"], testpath
    system "./test"
  end
end
