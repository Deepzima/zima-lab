# infra-lab helpers — managed by dots/infra-lab

# Quick status of current project lab
zl() { zlab status; }

# Quick up/down
zlu() { zlab up "$@"; }
zld() { zlab down "$@"; }

# Open observability dashboard
zlo() { zlab observe; }

# Enter an asset
zle() { zlab ssh "$@"; }

# Auto-detect .zlab.yaml in parent dirs and print project name
zlab_project() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.zlab.yaml" ]]; then
      yq '.project' "$dir/.zlab.yaml" 2>/dev/null
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  echo "no project"
  return 1
}
