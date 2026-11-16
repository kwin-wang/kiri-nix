{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  sources = lib.importJSON ./sources.json;
  system = stdenvNoCC.hostPlatform.system;
  source = sources.${system} or (throw "kiri: unsupported system ${system}");
in
  stdenvNoCC.mkDerivation {
    pname = "kiri";
    inherit (sources) version;

    src = fetchurl {inherit (source) url hash;};

    # The tarball is made by macOS tar, whose xattr headers GNU tar ignores.
    unpackPhase = ''
      runHook preUnpack
      tar --warning=no-unknown-keyword -xzf $src
      runHook postUnpack
    '';

    # The app is signed and notarized upstream, with the virtualization
    # entitlement. Stripping or patching any Mach-O would break the signature.
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      # GNU tar unpacks macOS AppleDouble metadata as `._*` files; they are not
      # part of the signed bundle.
      find Kiri.app -name '._*' -delete

      mkdir -p $out/Applications $out/bin
      cp -R Kiri.app $out/Applications/

      # kiri resolves its guest kernel through the canonical path of its own
      # binary, so a symlink on PATH works.
      ln -s $out/Applications/Kiri.app/Contents/MacOS/kiri $out/bin/kiri

      runHook postInstall
    '';

    meta = {
      description = "Small, fast container runtime for macOS that speaks the Docker Engine API";
      homepage = "https://github.com/libracoder/kiri";
      changelog = "https://github.com/libracoder/kiri/releases/tag/v${sources.version}";
      license = lib.licenses.asl20;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = ["aarch64-darwin" "x86_64-darwin"];
      mainProgram = "kiri";
    };
  }
