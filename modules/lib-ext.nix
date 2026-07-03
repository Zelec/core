# Loader for the lib folder outside of the modules folder
# Uses the namespace of zelCoreLib
{...}: {
  perSystem = {pkgs, ...}: {
    _module.args.zelCoreLib = import ../lib {inherit pkgs;};
  };
}
