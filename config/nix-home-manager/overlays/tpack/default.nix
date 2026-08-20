{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "tpack";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "tmuxpack";
    repo = "tpack";
    rev = "v${version}";
    hash = "sha256-WxOOrtTSH4F1j6SD+ShIULitaFtt3G7mIjpmHZ2pOPM=";
  };

  vendorHash = "sha256-83WSoE/jjwP8goeZe2iElAV0inLpKZQIGvvq9ef0gZI=";

  # The main package is in cmd/tpack
  subPackages = [ "cmd/tpack" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = with lib; {
    description = "A drop-in replacement for tmux-plugin-manager (tpm) with a TUI. Written in Go";
    homepage = "https://github.com/tmuxpack/tpack";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "tpack";
  };
}
