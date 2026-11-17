#!/usr/bin/env bash
# Break-glass: cluster-admin access, logged.
#   ./break-glass.sh                      -> interactive admin shell (type 'exit' to leave)
#   ./break-glass.sh kubectl get ... -o yaml   -> one admin command, then done
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"; cd "$ROOT"
mkdir -p kubeconfigs
kind get kubeconfig --name "$CLUSTER" > "$ADMIN"; chmod 600 "$ADMIN"
echo "BREAK-GLASS opened $(date -u +%FT%TZ) user=${USER:-unknown} cmd=${*:-interactive}" | tee -a break-glass.log
export KUBECONFIG="$ADMIN"
rc=0
if [[ $# -gt 0 ]]; then
  "$@" || rc=$?
else
  echo ">>> cluster-admin shell. Type 'exit' to drop back to normal. <<<"
  bash --rcfile <(echo 'PS1="[BREAK-GLASS] \w \$ "') -i || true
fi
echo "BREAK-GLASS closed $(date -u +%FT%TZ)" | tee -a break-glass.log
exit "$rc"
