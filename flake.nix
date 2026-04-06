{
  description = "Flutter dev";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };

        android = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [
            "36.0.0"
            "28.0.3"
          ];
          platformVersions = [ "36" ];
          abiVersions = [ "arm64-v8a" ];
        };

      in
      {
        devShell = pkgs.mkShell {
          ANDROID_SDK_ROOT = "${android.androidsdk}/libexec/android-sdk";

          buildInputs = with pkgs; [
            jdk17
            clang
            cmake
            ninja
            pkg-config
            gtk3
          ];

          shellHook = ''
            export PATH=$HOME/dev/flutter/bin:$PATH
            export LD_LIBRARY_PATH=${
              pkgs.lib.makeLibraryPath [
                pkgs.libepoxy
                pkgs.fontconfig
                pkgs.gtk3
                pkgs.pango
                pkgs.cairo
                pkgs.glib
                pkgs.xorg.libX11
                pkgs.xorg.libXcursor
                pkgs.xorg.libXrandr
                pkgs.xorg.libXi
              ]
            }
          '';
        };
      }
    );
}
