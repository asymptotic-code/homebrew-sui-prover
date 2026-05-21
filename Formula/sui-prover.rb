class SuiProver < Formula
  desc "Prover - a tool for verifying Move smart contracts on the Sui blockchain"
  homepage "https://github.com/asymptotic-code/sui"
  license "Apache-2.0"

  stable do
    depends_on "dotnet@8"
    url "https://github.com/asymptotic-code/sui-prover.git", branch: "main"
    version "2.8.3"
    resource "boogie" do
      url "https://github.com/asymptotic-code/boogie.git", branch: "master", using: :git
    end
  end

  bottle do
    root_url "https://github.com/asymptotic-code/homebrew-sui-prover/releases/download/sui-prover-2.8.3"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "ab253b04c13000c7614d3d616928c7276a43bf6ffccaa869b5ae217637a2dc65"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "811a2958ee6bebaf0bc4e2483078313661aa8426871a70271d820ef419114a65"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "f41ec2fb2b4a819c493635281f84c371e9b24023d7a2360580c656849a5ec02c"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "4fd5a7717cfd81075c9d540c6a4c6a7437502d3783d2b1662f7b2d798d173e2e"
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
