{
  description = "MDTT: Heterogeneous Multi-stage Dependent Type Theory (spec + Lean 4 formalization)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        # 版本权威来自 mdtt-lean/lean-toolchain (由 elan 解析);
        # devShell 只提供工具链管理器与辅助工具, 保证进入 shell 即可 `just check`.
        devTools = with pkgs; [
          elan
          just
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = devTools;
          shellHook = ''
            echo "MDTT devShell: use 'just check' to build & verify the Lean formalization."
            echo "Lean toolchain is pinned by mdtt-lean/lean-toolchain (resolved via elan)."
          '';
        };
      });
}
