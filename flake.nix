{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devshell.flakeModule
      ];
      systems = ["x86_64-linux" "aarch64-linux"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      } @ args: {
        devshells.default.devshell.packages = with pkgs; [
          mix2nix
          elixir
        ];
        packages.akkoma = pkgs.callPackage ./package.nix {inherit inputs;};
        formatter = pkgs.alejandra;
        checks.akkoma = import ./test inputs args;
      };
      flake = {
        hydraJobs = {
          inherit (inputs.self) devShells packages formatter;

          inherit (inputs.self.checks) x86_64-linux;
        };
      };
    };
}
