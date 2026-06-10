{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    tamerye = {
      url = "git+https://git.pvv.ntnu.no/Mugiten/tamerye.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, tamerye, nixpkgs }: let
    inherit (nixpkgs) lib;
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = f: lib.genAttrs systems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          android_sdk.accept_license = true;
          allowUnfree = true;
        };
        overlays = [
          tamerye.overlays.default
        ];
      };
      androidPkgs = (pkgs.androidenv.composeAndroidPackages {
        buildToolsVersions = [ "35.0.0" "36.1.0" ];
        platformVersions = [ "35" "36" ];
        abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
        cmakeVersions = [ "3.22.1" ];
        includeNDK = true;
        ndkVersions = [ "28.2.13676358" ];
      });
    in f system pkgs androidPkgs);
  in {
    devShells = forAllSystems (_: pkgs: androidPkgs: {
      default = let
        flutter' = pkgs.flutter341;
        jdk' = pkgs.jdk21;
      in pkgs.mkShell {
        packages = [
          flutter'
          androidPkgs.androidsdk
          jdk'

          pkgs.tamerye-sqlite-cli
          pkgs.sqldiff
        ];
        env = {
          ANDROID_SDK_ROOT = "${androidPkgs.androidsdk}/libexec/android-sdk";
          GRADLE_OPTS = let
            buildToolsVersion = (lib.head androidPkgs.build-tools).version;
            buildToolsDir = "${androidPkgs.androidsdk}/libexec/android-sdk/build-tools/${buildToolsVersion}";
          in lib.concatStringsSep " " [
            "-Dorg.gradle.project.android.aapt2FromMavenOverride=${buildToolsDir}/aapt2"
          ];
          FLUTTER_SDK = "${flutter'}";
          JAVA_HOME = "${jdk'}/lib/openjdk";
          LIBSQLITE_PATH = "${pkgs.tamerye-sqlite}/lib/libsqlite3.so";
          JADB_PATH = "./assets/jadb.sqlite";
          NIX_NATIVE_LIBTAMERYE_PATH = "${pkgs.tamerye-sqlite-shared-lib}/lib/libtamerye.so";
          NIX_ANDROID_LIBTAMERYE_PATH = "${pkgs.tamerye-sqlite-android-shared-lib}/lib/libtamerye.so";
        };
      };
    });
  };
}
