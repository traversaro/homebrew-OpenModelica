class Openmodelica < Formula
  desc "Open-source modeling and simulation tool"
  homepage "https://openmodelica.org/"
  url "https://github.com/OpenModelica/OpenModelica/archive/v1.12.0.tar.gz"
  sha256 "c3b89c298cc01f631ccfc427f32be67936e09d1c"
  head do
    url "https://github.com/OpenModelica/OpenModelica.git"
    option "with-library", "Build with OMLibraries"
  end

  depends_on "qt" =>:build
  depends_on "autoconf" =>:build
  depends_on "automake" =>:build
  depends_on "cmake" =>:build
  depends_on "gettext"
  depends_on "gnu-sed" =>:build
  depends_on "libtool" =>:build
  depends_on "homebrew/science/lp_solve"
  depends_on "openblas"
  depends_on "pkg-config" =>:build
  depends_on "readline" =>:build
  depends_on "xz" =>:build

  depends_on "omniorb" => :optional

  def install
    ENV["LDFLAGS"] = "-L#{Formula["openblas"].opt_lib}"
    ENV["CPPFLAGS"] = "-I#{Formula["openblas"].opt_include}"
    args = %W[--disable-debug
              --with-lapack=-lopenblas
              --disable-modelica3d
              --prefix=#{prefix}
              --without-omlibrary]

    args << "--with-omniORB" if build.with? "omniorb"

    system "autoconf"
    system "./configure", *args
    system "make", "omc"
    if build.with? "library"
      system "svn", "ls", "https://openmodelica.org/svn/OpenModelica", "--non-interactive", "--trust-server-cert"
      system "svn", "ls", "https://svn.modelica.org/projects/Modelica_ElectricalSystems/InstantaneousSymmetricalComponents", "--non-interactive", "--trust-server-cert"
      system "make", "omlibrary-core"
    end
    prefix.install Dir["build/*"]
  end

  test do
    system "#{bin}/omc", "--version"
    (testpath/"test.mo").write <<-EOS.undent
    model test
    Real x;
    initial equation
    x = 10;
    equation
    der(x) = -x;
    end test;
    EOS
    (testpath/"test.mos").write <<-EOS.undent
    loadFile("test.mo");
    simulate(test);
    EOS
    system "#{bin}/omc", "test.mos"
    assert File.exist?("test_res.mat")
  end
end
