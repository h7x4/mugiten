{
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: let
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
      };
      androidSdk = (pkgs.androidenv.composeAndroidPackages {
        buildToolsVersions = [ "33.0.1" "34.0.0" ];
        platformVersions = [ "35" "36" ];
        abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
        cmakeVersions = [ "3.22.1" ];
        includeNDK = true;
        ndkVersions = [ "27.0.12077973" ];
      }).androidsdk;
    in f system pkgs androidSdk);
  in {
    devShells = forAllSystems (_: pkgs: androidSdk: {
      default = let
        flutter' = pkgs.flutter335;
        jdk' = pkgs.jdk21;
      in pkgs.mkShell {
        packages = [
          flutter'
          pkgs.sqlite-interactive
          androidSdk
          jdk'
        ];
        env = {
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/34.0.0/aapt2";
          FLUTTER_SDK = "${flutter'}";
          JAVA_HOME = "${jdk'}/lib/openjdk";
          LIBSQLITE_PATH = "${pkgs.sqlite.out}/lib/libsqlite3.so";
          JADB_PATH = "./assets/jadb.sqlite";
        };
      };
    });
  };
}
