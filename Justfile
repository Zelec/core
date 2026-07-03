attic_repo_target := "zelec-core"

# By default run ci command
default: ci

# Builds all hosts using omnix
[linux]
ci:
  om ci

# Builds and pushes attic build artifacts for all hosts
[linux]
ci-push: ci
  attic push {{attic_repo_target}} ./result

# Validates nix config
validate:
  nix flake check --option abort-on-warn false

# Update flake inputs to their latest revisions
update:
  nix flake update

# Removes any result symlinks from the root of the project
cleanup:
  rm -f ./result*
