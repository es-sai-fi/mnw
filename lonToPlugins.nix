{
  lib,
  fetchgit,
  fetchzip,
}: func: pathToLon:
func
(
  name: spec: let
    mayOverride = name: path: let
      envVarName = "LON_OVERRIDE_${saneName}";
      saneName = builtins.concatStringsSep "_" (
        builtins.concatLists (
          builtins.filter (x: builtins.isList x && x != [""]) (builtins.split "([a-zA-Z0-9]*)" name)
        )
      );
      ersatz = builtins.getEnv envVarName;
    in
      if ersatz == ""
      then path
      else
        # this turns the string into an actual Nix path (for both absolute and
        # relative paths)
        builtins.trace "Overriding path of \"${name}\" with \"${ersatz}\" due to set \"${envVarName}\"" (
          if builtins.substring 0 1 ersatz == "/"
          then /. + ersatz
          else /. + builtins.getEnv "PWD" + "/${ersatz}"
        );

    path =
      if spec.fetchType == "tarball"
      then
        fetchzip {
          inherit (spec) url hash;
        }
      else if spec.fetchType == "git"
      then
        fetchgit {
          url =
            if spec.type == "GitHub"
            then "https://github.com/${spec.owner}/${spec.repo}.git"
            else spec.url;

          rev = spec.revision;
          hash = spec.hash;
          fetchSubmodules = spec.submodules or false;
        }
      else throw "Unknown fetchType ${spec.fetchType}";

    version =
      if spec ? revision
      then builtins.substring 0 8 spec.revision
      else "0";
  in
    spec
    // {
      name = "${name}-${version}";
      pname = name;
      inherit version;
      vimPlugin = true;
      outPath =
        (
          # Override logic won't do anything if we're in pure eval
          if builtins ? currentSystem
          then mayOverride name path
          else path
        ).overrideAttrs
        {
          pname = name;
          name = "${name}-${version}";
          inherit version;
        };
    }
)
(
  let
    json = lib.importJSON pathToLon;
  in
    assert lib.assertMsg (json.version == "1") ''
      Your lon version does not match that of mnw.lib.lonToPlugins.
    '';
      json.sources
)
