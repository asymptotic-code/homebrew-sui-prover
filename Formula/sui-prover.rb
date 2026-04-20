class SuiProver < Formula
  desc "Prover - a tool for verifying Move smart contracts on the Sui blockchain"
  homepage "https://github.com/asymptotic-code/sui"
  license "Apache-2.0"

  stable do
    depends_on "dotnet@8"
    url "https://github.com/asymptotic-code/sui-prover.git", branch: "main"
    version "2.4.3"
    resource "boogie" do
      url "https://github.com/asymptotic-code/boogie.git", branch: "master", using: :git
    end
  end

  bottle do
    root_url "https://github.com/asymptotic-code/homebrew-sui-prover/releases/download/sui-prover-1.4.3"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "e7666f5bb736813af9e58919a78863985576bdae39c9bbfbd14c144967c9ff10"
  end

  head "https://github.com/asymptotic-code/sui-prover.git", branch: "main" do
    depends_on "dotnet@8"
    resource "boogie" do
      url "https://github.com/asymptotic-code/boogie.git", branch: "master", using: :git
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
