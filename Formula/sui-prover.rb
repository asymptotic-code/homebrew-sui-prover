class SuiProver < Formula
  desc "Prover - a tool for verifying Move smart contracts on the Sui blockchain"
  homepage "https://github.com/asymptotic-code/sui"
  license "Apache-2.0"

  stable do
    depends_on "dotnet@8"
    url "https://github.com/asymptotic-code/sui.git", branch: "next"
    version "0.1.0"
    resource "boogie" do
      url "https://github.com/boogie-org/boogie.git", branch: "master"
    end
  end

  bottle do
    root_url "https://github.com/asymptotic-code/homebrew-sui-prover/releases/download/sui-prover-0.1.0"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "3de677a653349b87bb1f6179cbf375ddf265d1631d8cc61fa89e00918854d8d8"
    sha256 cellar: :any_skip_relocation, ventura:       "b7a02a524a45272ec6475526a1e94ccf98bf8f2fa55d19f0d49a078d548b677e"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "4aed506663ec50a6d4ff457f08660fad2aef20e8a5095e92ba0090d53356d586"
  end

  head "https://github.com/asymptotic-code/sui.git", branch: "next" do
    depends_on "dotnet@8"
    resource "boogie" do
      url "https://github.com/boogie-org/boogie.git", branch: "master"
    end
  end

  depends_on "rust" => :build
  depends_on "z3"

  def install
    system "cargo", "install", "--locked", "--path", "./crates/sui-move", "--features", "all"
    # system "cargo", "build", "--release", "--features", "build", "--package", "sui-move"

    libexec.install "target/release/sui-move"

    ENV.prepend_path "PATH", Formula["dotnet@8"].opt_bin
    ENV["DOTNET_ROOT"] = Formula["dotnet@8"].opt_libexec

    resource("boogie").stage do
      system "dotnet", "build", "Source/Boogie.sln", "-c", "Release"
      libexec.install Dir["Source/BoogieDriver/bin/Release/net8.0/*"]
      bin.install_symlink libexec/"BoogieDriver" => "boogie"
    end

    (bin/"sui-move").write_env_script libexec/"sui-move", {
      DOTNET_ROOT: Formula["dotnet@8"].opt_libexec,
      BOOGIE_EXE:  bin/"boogie",
      Z3_EXE:      Formula["z3"].opt_bin/"z3",
    }
  end

  def caveats
    <<~EOS
      The formal verification toolchain has been installed.
    EOS
  end

  test do
    system "z3", "--version"
    system "#{bin}/sui-move", "--version"
  end
end
