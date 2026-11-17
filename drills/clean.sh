#!/usr/bin/env bash
# Undo any practice fault (same as the runbook repair, plus removes stray bindings in 'default')
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../env.sh"; cd "$ROOT"
K() { kubectl --kubeconfig "$ADMIN" "$@"; }
K -n default delete rolebinding -l owner="$SID" --ignore-not-found
K apply -f manifests/rbac/
