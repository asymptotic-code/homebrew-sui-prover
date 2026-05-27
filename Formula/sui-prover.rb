class SuiProver < Formula
  desc "Prover - a tool for verifying Move smart contracts on the Sui blockchain"
  homepage "https://github.com/asymptotic-code/sui"
  license "Apache-2.0"

  stable do
    depends_on "dotnet@8"
    url "https://github.com/asymptotic-code/sui-prover.git", branch: "main"
    version "2.8.5"
    resource "boogie" do
      url "https://github.com/asymptotic-code/boogie.git", branch: "master", using: :git
    end
  end

  bottle do
    root_url "https://github.com/asymptotic-code/homebrew-sui-prover/releases/download/sui-prover-2.8.4"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "77a07dde6f55512ef99e63cc06bf1bdd5fa84a7601df61bae8e8bced94d13ed3"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "77076c14f61a204399810e6a44ace7f2825b4ac87059a4fa676836edb3334d64"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "4e7e8795153714ded7de94c072690a91b1fb4a45ab072b40502a58d7e9c3a936"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "cc7625fb4f30c3e4e7a3f5796a76fa70c97a3f2bc40db0fd72c837d6e37b16de"
  end

  head "https://github.com/asymptotic-code/sui-prover.git", branch: "main" do
    depends_on "dotnet@8"
    resource "boogie" do
      url "https://github.com/asymptotic-code/boogie.git", branch: "master", using: :git
    end
  end

  depends_on "rust" => :build
  depends_on "openssl@3"
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
