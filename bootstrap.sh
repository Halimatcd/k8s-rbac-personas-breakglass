#!/usr/bin/env bash
# ============================================================
#  CONFIG - the ONLY place these are defined.
# ============================================================
SID="hoaminu"           # Seneca student ID, lowercase
DHUSER="halimatcd"      # Docker Hub / GHCR username
APP_TAG="latest"        # tag of <DHUSER>/clo835-app used by the CI persona
CLUSTER="clo835"        # kind cluster name
# ============================================================
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd "$ROOT"
NS="rbac-${SID}"
TOKEN_TTL="48h"
ADMIN="$ROOT/kubeconfigs/admin.kubeconfig"
K() { kubectl --kubeconfig "$ADMIN" "$@"; }

if ! [[ "$SID" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  echo "SID must be lowercase letters/digits/hyphens." >&2; exit 2
fi

mint() {  # persona: deployer|readonly|ci
  local p="$1" sa="$1-${SID}" out="kubeconfigs/$1.kubeconfig" ca tok server
  ca="$(mktemp)"
  tok="$(K -n "$NS" create token "$sa" --duration="$TOKEN_TTL")"
  server="$(K config view --raw --minify -o jsonpath='{.clusters[0].cluster.server}')"
  K config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > "$ca"
  rm -f "$out"
  kubectl config --kubeconfig "$out" set-cluster "$CLUSTER" --server "$server" --certificate-authority "$ca" --embed-certs=true >/dev/null
  kubectl config --kubeconfig "$out" set-credentials "$sa" --token "$tok" >/dev/null
  kubectl config --kubeconfig "$out" set-context "$p" --cluster "$CLUSTER" --user "$sa" --namespace "$NS" >/dev/null
  kubectl config --kubeconfig "$out" use-context "$p" >/dev/null
  chmod 600 "$out"; rm -f "$ca"
  echo "  minted kubeconfigs/$p.kubeconfig (valid $TOKEN_TTL)"
}

mkdir -p kubeconfigs

# Fast path: ./bootstrap.sh kubeconfigs  -> only re-mint tokens
if [[ "${1:-}" == "kubeconfigs" ]]; then
  kind get kubeconfig --name "$CLUSTER" > "$ADMIN"; chmod 600 "$ADMIN"
  for p in deployer readonly ci; do mint "$p"; done
  exit 0
fi

echo "==> 0/6 preflight"
for c in docker kind kubectl jq sed base64; do
  command -v "$c" >/dev/null || { echo "missing required tool: $c" >&2; exit 1; }
done
docker info >/dev/null 2>&1 || { echo "docker daemon not reachable" >&2; exit 1; }

echo "==> 1/6 render manifests from templates (SID=$SID)"
for t in manifests/*/*.yaml.tpl; do
  sed "s/__SID__/${SID}/g; s/__DHUSER__/${DHUSER}/g" "$t" > "${t%.tpl}"
done

echo "==> 2/6 kind cluster '$CLUSTER'"
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo "  cluster already exists, reusing"
else
  kind create cluster --name "$CLUSTER" --config kind-config.yaml
fi
kind get kubeconfig --name "$CLUSTER" > "$ADMIN"; chmod 600 "$ADMIN"

echo "==> 3/6 RBAC objects"
K apply -f manifests/rbac/

echo "==> 4/6 demo workload"
K apply -f manifests/workload/
K -n "$NS" rollout status "deploy/web-${SID}" --timeout=240s

echo "==> 5/6 persona kubeconfigs"
for p in deployer readonly ci; do mint "$p"; done

echo "==> 6/6 permission test suite"
./tests/rbac-test.sh
echo "Bootstrap finished OK in ${SECONDS}s"
