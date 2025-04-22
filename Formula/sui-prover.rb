class SuiProver < Formula
  desc "Prover - a tool for verifying Move smart contracts on the Sui blockchain"
  homepage "https://github.com/asymptotic-code/sui"
  license "Apache-2.0"

  stable do
    depends_on "dotnet@8"
    url "https://github.com/asymptotic-code/sui-prover.git", branch: "main"
    version "0.3.5"
    resource "boogie" do
      url "https://github.com/boogie-org/boogie.git", branch: "master"
    end
  end

  bottle do
    root_url "https://github.com/asymptotic-code/homebrew-sui-prover/releases/download/sui-prover-0.3.4"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "46d85537a9f16bfb7fb53eeefe690cef43a609e16ab0474e81c9f698036f0264"
    sha256 cellar: :any_skip_relocation, ventura:       "4cbf3a8c31625b2e297a32b13e014c3a17f34c41e7e12d1f5cfff2678885cd7b"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "55f4108ec9b95827d523da75e3be307c7dc43b7bc9d14147ce7864ae73505792"
  end

  head "https://github.com/asymptotic-code/sui-prover.git", branch: "main" do
    depends_on "dotnet@8"
    resource "boogie" do
      url "https://github.com/boogie-org/boogie.git", branch: "master"
    end
  end

  depends_on "rust" => :build
  depends_on "z3"

  def install
    system "cargo", "install", "--locked", "--path", "./crates/sui-prover"

    libexec.install "target/release/sui-prover"

    ENV.prepend_path "PATH", Formula["dotnet@8"].opt_bin
    ENV["DOTNET_ROOT"] = Formula["dotnet@8"].opt_libexec

    resource("boogie").stage do
      system "dotnet", "build", "Source/Boogie.sln", "-c", "Release"
      libexec.install Dir["Source/BoogieDriver/bin/Release/net8.0/*"]
      bin.install_symlink libexec/"BoogieDriver" => "boogie"
    end

    (bin/"sui-prover").write_env_script libexec/"sui-prover", {
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
    system "#{bin}/sui-prover", "--version"
  end
end
