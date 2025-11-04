class SuiProver < Formula
  desc "Prover - a tool for verifying Move smart contracts on the Sui blockchain"
  homepage "https://github.com/asymptotic-code/sui"
  license "Apache-2.0"

  stable do
    depends_on "dotnet@8"
    url "https://github.com/asymptotic-code/sui-prover.git", branch: "main"
    version "0.3.94"
    resource "boogie" do
      url "https://github.com/boogie-org/boogie.git", branch: "master"
    end
  end

  bottle do
    root_url "https://github.com/asymptotic-code/homebrew-sui-prover/releases/download/sui-prover-0.3.93"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "cf6842f8705bb56e1cf2a485aa7a359655ef7a38d0e43aabf95d36893a5c5d67"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "abb89f244e8f8a7d89503d7373641717b0c5e0642530e602fd40cd3233d12c41"
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
