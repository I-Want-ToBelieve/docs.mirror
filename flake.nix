{
  description = "docs mirror";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    flake-root.url = "github:srid/flake-root";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://devenv.cachix.org"
    ];
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [inputs.devenv.flakeModule inputs.treefmt-nix.flakeModule inputs.flake-root.flakeModule];
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.
        devenv.shells.default = {
          name = "docs mirror mono repo";

          imports = [
            # This is just like the imports in devenv.nix.
            # See https://devenv.sh/guides/using-with-flake-parts/#import-a-devenv-module
            # ./devenv-foo.nix
          ];

          # https://devenv.sh/reference/options/
          packages = with pkgs;
            [bun]
            ++ [zellij]
            ++ [nodePackages.pnpm npm-check-updates];

          # https://devenv.sh/basics/
          env = {
            GREET = "🛠️ Let's hack 🧑🏻‍💻";
          };

          # https://devenv.sh/scripts/
          scripts.hello.exec = "echo $GREET";
          scripts.up.exec = "ncu -i";

          scripts."all:build".exec = ''
            cd $DEVENV_ROOT
            sh -c $'sleep 0.314;zellij -s yakite -s yakite action write-chars "zellij run -- yakite-toast:build\n"' &
            sh -c $'sleep 0.314;zellij -s yakite -s yakite action write-chars "zellij run -- yakite:build\n"' &
            sh -c $'sleep 0.314;zellij -s yakite -s yakite action write-chars "zellij run -- pnpm --recursiv build\n"' &
            zellij --session yakite || zellij attach yakite
          '';

          scripts."git-user:setup".exec = ''
            git config user.name I-Want-ToBelieve
            git config user.email i.want.tobelieve.dev@gmail.com
          '';

          enterShell = ''
            hello
          '';

          # https://devenv.sh/languages/
          languages.javascript = {
            enable = true;
            package = pkgs.nodejs_20; # latest lts version
          };
          languages.typescript = {enable = true;};

          # Make diffs fantastic
          difftastic.enable = true;

          # https://devenv.sh/pre-commit-hooks/
          pre-commit.hooks = {
            # commons
            editorconfig-checker.enable = true;

            # configs
            yamllint.enable = true;

            # nix
            alejandra.enable = true;

            # javascript
            prettier.enable = false;
            eslint.enable = true;
          };

          # Plugin configuration
          pre-commit.settings = {yamllint.relaxed = true;};
        };

        treefmt.config = {
          inherit (config.flake-root) projectRootFile;
          # This is the default, and can be overriden.
          package = pkgs.treefmt;

          # formats .nix files
          programs.alejandra.enable = true;
        };
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };
    };
}
