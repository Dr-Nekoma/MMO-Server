# generated by zon2nix (https://github.com/Cloudef/zig2nix)

{
  lib,
  linkFarm,
  fetchurl,
  fetchgit,
  runCommandLocal,
  zig,
  name ? "zig-packages",
}:

with builtins;
with lib;

let
  unpackZigArtifact =
    { name, artifact }:
    runCommandLocal name
      {
        nativeBuildInputs = [ zig ];
      }
      ''
        hash="$(zig fetch --global-cache-dir "$TMPDIR" ${artifact})"
        mv "$TMPDIR/p/$hash" "$out"
        chmod 755 "$out"
      '';

  fetchZig =
    {
      name,
      url,
      hash,
    }:
    let
      artifact = fetchurl { inherit url hash; };
    in
    unpackZigArtifact { inherit name artifact; };

  fetchGitZig =
    {
      name,
      url,
      hash,
    }:
    let
      parts = splitString "#" url;
      url_base = elemAt parts 0;
      url_without_query = elemAt (splitString "?" url_base) 0;
      rev_base = elemAt parts 1;
      rev = if match "^[a-fA-F0-9]{40}$" rev_base != null then rev_base else "refs/heads/${rev_base}";
    in
    fetchgit {
      inherit name rev hash;
      url = url_without_query;
      deepClone = false;
    };

  fetchZigArtifact =
    {
      name,
      url,
      hash,
    }:
    let
      parts = splitString "://" url;
      proto = elemAt parts 0;
      path = elemAt parts 1;
      fetcher = {
        "git+http" = fetchGitZig {
          inherit name hash;
          url = "http://${path}";
        };
        "git+https" = fetchGitZig {
          inherit name hash;
          url = "https://${path}";
        };
        http = fetchZig {
          inherit name hash;
          url = "http://${path}";
        };
        https = fetchZig {
          inherit name hash;
          url = "https://${path}";
        };
        file = unpackZigArtifact {
          inherit name;
          artifact = /. + path;
        };
      };
    in
    fetcher.${proto};
in
linkFarm name [
  {
    name = "1220df9aa89d657f5dca24ab0ac3d187f7a992a4d27461fd9e76e934bf0670ca9a90";
    path = fetchZigArtifact {
      name = "raylib-zig";
      url = "https://github.com/Not-Nik/raylib-zig/archive/58df62807f62bef1db79538d04b37b9f79909d0a.tar.gz";
      hash = "sha256-iPVRpT6r3yIZRdhZSaFBOO+EBtHt4bpuLAnXVr7m6J8=";
    };
  }
  {
    name = "1220aa75240ee6459499456ef520ab7e8bddffaed8a5055441da457b198fc4e92b26";
    path = fetchZigArtifact {
      name = "raylib";
      url = "https://github.com/raysan5/raylib/archive/5767c4cd059e07355ae5588966d0aee97038a86b.tar.gz";
      hash = "sha256-ijvgBlAfUD71p07Zg/oMzZnneQ95RoiaJXIkNlB26oc=";
    };
  }
  {
    name = "122002d98ca255ec706ef8e5497b3723d6c6e163511761d116dac3aee87747d46cf1";
    path = fetchZigArtifact {
      name = "raygui";
      url = "https://github.com/raysan5/raygui/archive/4b3d94f5df6a5a2aa86286350f7e20c0ca35f516.tar.gz";
      hash = "sha256-AjU+fyonXnGTG8ZBMb10ScB3G6iI97eiL9N3anm+r1Q=";
    };
  }
  {
    name = "1220621432ddbc3b52ed431d858fe4be2fa6c2b7a37087573856c0389705a275fb5a";
    path = fetchZigArtifact {
      name = "zerl";
      url = "https://github.com/dont-rely-on-nulls/zerl/archive/327d1a8a473546c7340d34a3ff262fce75b93bbd.tar.gz";
      hash = "sha256-kjXrPku6DZ7+WR9RwQwA+xGd4/t6b6VWwCyr/JYdVxs=";
    };
  }
]
