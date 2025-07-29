class SuiProver < Formula
  desc "Prover - a tool for verifying Move smart contracts on the Sui blockchain"
  homepage "https://github.com/asymptotic-code/sui"
  license "Apache-2.0"

  stable do
    depends_on "dotnet@8"
    url "https://github.com/asymptotic-code/sui-prover.git", branch: "main"
    version "0.4.1"
    resource "boogie" do
      url "https://github.com/boogie-org/boogie.git", branch: "master"
    end
  end

  bottle do
    root_url "https://github.com/asymptotic-code/homebrew-sui-prover/releases/download/sui-prover-0.3.26"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "daac8638a4fe1a4c09d87c0e5a76770560ddfa3727ae2f14d5bd44cd8d881b12"
    sha256 cellar: :any_skip_relocation, ventura:       "18b06c3ef5dcf3aaf47b83a5b50999ecce4f63418479e331c86ed7d94cc4a59e"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "d2f977fb05a27c60635fe791f036c5e86b21183905969c8ddb8e6d4845b1df0f"
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
    # First build sui-prover as before
    system "cargo", "install", "--locked", "--path", "./crates/sui-prover"

    # Build move-analyzer from the sui dependency
    # First, ensure all dependencies are fetched
    system "cargo", "fetch"
    
    # Find the sui repository in Cargo's git checkouts
    cargo_home = ENV["CARGO_HOME"] || "#{ENV["HOME"]}/.cargo"
    sui_checkout_path = nil
    
    # Look for sui repository in git checkouts
    Dir.glob("#{cargo_home}/git/checkouts/sui-*/*/").each do |path|
      if File.exist?("#{path}/crates/sui-move-lsp/Cargo.toml")
        sui_checkout_path = path
        break
      end
    end
    
    # Alternative: try to find it via cargo metadata after dependencies are resolved
    if sui_checkout_path.nil?
      begin
        require "json"
        # Use --offline to avoid network calls since deps should already be fetched
        metadata = JSON.parse(`cargo metadata --format-version 1 --offline 2>/dev/null || cargo metadata --format-version 1`)
        
        # Look for any package from the sui repository
        sui_packages = metadata["packages"].select { |pkg| 
          pkg["source"] && pkg["source"].include?("github.com/asymptotic-code/sui")
        }
        
        if !sui_packages.empty?
          # Get the checkout path from any sui package
          manifest_path = sui_packages.first["manifest_path"]
          # Navigate up to find the repository root
          current_path = File.dirname(manifest_path)
          while current_path != "/" && !File.exist?("#{current_path}/crates/sui-move-lsp/Cargo.toml")
            current_path = File.dirname(current_path)
          end
          sui_checkout_path = current_path if File.exist?("#{current_path}/crates/sui-move-lsp/Cargo.toml")
        end
      rescue => e
        # Metadata approach failed, continue with manual search
      end
    end
    
    if sui_checkout_path.nil?
      odie "Could not find sui repository checkout. Please ensure the sui dependencies in Cargo.toml are correct."
    end
    
    # Build move-analyzer from the sui repository
    cd sui_checkout_path do
      system "cargo", "build", "--release", "--bin", "move-analyzer", "-p", "sui-move-lsp"
      bin.install "target/release/move-analyzer"
    end

    # Continue with existing libexec installation
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

      The Move language server (move-analyzer) has been installed at:
        #{bin}/move-analyzer

      To use Move language support in VS Code or Cursor:
      1. Install the Move language extension
      2. Go to Settings (Cmd/Ctrl + ,)
      3. Search for "move.server.path"
      4. Set the value to: #{bin}/move-analyzer
    EOS
  end

  test do
    system "z3", "--version"
    system "#{bin}/sui-prover", "--version"
    system "#{bin}/move-analyzer", "--version"
  end
end
