# kiri-nix

Nix flake for [Kiri](https://github.com/libracoder/kiri), a small container
runtime for macOS that speaks the Docker Engine API.

The package repackages the upstream release tarball (`Kiri-<version>-<arch>.tar.gz`)
as is. Kiri.app is signed with a Developer ID, notarized and carries the
`com.apple.security.virtualization` entitlement, so nothing in the bundle is
patched or stripped.

Supported systems: `aarch64-darwin`, `x86_64-darwin`.

## Use

Try it:

```sh
nix run github:kwin-wang/kiri-nix -- version
```

In a nix-darwin flake:

```nix
{
  inputs.kiri-nix = {
    url = "github:kwin-wang/kiri-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # in a module
  environment.systemPackages = [inputs.kiri-nix.packages.${pkgs.system}.default];
  # or: nixpkgs.overlays = [inputs.kiri-nix.overlays.default]; then pkgs.kiri
}
```

nix-darwin copies `Kiri.app` to `/Applications/Nix Apps`, and `kiri` is on
`PATH`.

Kiri sets itself up the first time the app opens (or with `kiri setup`):
a `kiri` docker context, a LaunchAgent for the engine and `~/.kiri/bin`.
Run that from the app in `/Applications/Nix Apps`, not from the store path:
the LaunchAgent records the binary's path, and the app rewrites an agent that
points elsewhere.

## Package contents

- `$out/Applications/Kiri.app`: the app, with the bundled docker CLI, Compose,
  buildx and guest kernel.
- `$out/bin/kiri`: a symlink to the app's binary. Kiri finds its guest through
  the canonical path of its binary, so the link works.

The bundled `docker` is not put on `PATH`; `kiri run`, `kiri compose` and the
rest use it directly.

## Self-update

Kiri's built-in updater replaces `Kiri.app` in place. The app in the Nix store
and in `/Applications/Nix Apps` is read-only, so an in-app update fails. Update
through this flake instead (`nix flake update kiri-nix`).

## Updates

`.github/workflows/update.yml` checks for a new upstream release every 6 hours.
It runs `update.sh`, builds the package on macOS, verifies the code signature
and commits the new `sources.json`.

When a new release changes how `kiri setup` configures a Mac
(`crates/kiri/src/setup.rs`, `flavor.rs`, `update.rs` or `packaging/README.md`),
the workflow also opens an issue here linking the diff (`watch-setup.sh`), so
configs built on this package can be checked.

To update by hand:

```sh
./update.sh          # latest release
./update.sh 0.2.1    # a given version
```

## License

The Nix code in this repository is MIT. Kiri itself is Apache-2.0; its guest
kernel is GPL-2.0.
