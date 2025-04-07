class SuiProver < Formula
  desc "Prover - a tool for verifying Move smart contracts on the Sui blockchain"
  homepage "https://github.com/asymptotic-code/sui"
  license "Apache-2.0"

  stable do
    depends_on "dotnet@8"
    url "https://github.com/asymptotic-code/sui.git", branch: "next"
    version "0.2.23"
    resource "boogie" do
      url "https://github.com/boogie-org/boogie.git", branch: "master"
    end
  end

  bottle do
    root_url "https://github.com/asymptotic-code/homebrew-sui-prover/releases/download/sui-prover-0.2.22"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "43bc6a6c68fbe100af2c23809c66dc8ac173758f917782a77f3b5b703fd8a939"
    sha256 cellar: :any_skip_relocation, ventura:       "604414fc10398efc7f3d898dfd76a5d057963f84831d5db8ae854842af32774d"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "86d3c7b6826f38a1647fd8bb6c71077bbd0007a450dfbd81426d6d9b619d4718"
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
