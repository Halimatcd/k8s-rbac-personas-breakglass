#!/usr/bin/env bash
# Records a FULL clean bootstrap (cluster deleted first) into evidence/bootstrap-run.txt
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"; cd "$ROOT"
./teardown.sh || true
mkdir -p evidence
{ time ./bootstrap.sh; } 2>&1 | tee evidence/bootstrap-run.txt
{ echo; echo "### healthy state"; kubectl --kubeconfig kubeconfigs/admin.kubeconfig get all,sa,role,rolebinding -n "$NS"; } 2>&1 | tee -a evidence/bootstrap-run.txt
if grep -qE 'eyJ[A-Za-z0-9_-]{20,}' evidence/bootstrap-run.txt; then echo "!! TOKEN FOUND IN EVIDENCE - do not commit" >&2; exit 1; fi
echo "Evidence saved, no tokens detected."
