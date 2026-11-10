# Usage:  source ./env.sh      (reads SID etc. from bootstrap.sh - single source of truth)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_cfg() { grep -m1 "^$1=" "$ROOT/bootstrap.sh" | cut -d= -f2- | sed 's/[[:space:]]*#.*//' | tr -d "\"'"; }
export SID="$(_cfg SID)" DHUSER="$(_cfg DHUSER)" APP_TAG="$(_cfg APP_TAG)" CLUSTER="$(_cfg CLUSTER)"
export NS="rbac-${SID}" ADMIN="$ROOT/kubeconfigs/admin.kubeconfig"
