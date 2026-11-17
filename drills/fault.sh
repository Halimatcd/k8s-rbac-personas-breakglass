#!/usr/bin/env bash
# PRACTICE ONLY. Simulates the instructor twist.
# usage: drills/fault.sh <a|b|c|d> <deployer|readonly|ci> [other-persona   (only for c)]
#   a = delete the RoleBinding        b = remove verbs from the Role
#   c = wrong subject in the binding  d = binding recreated in 'default' namespace
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../env.sh"
K() { kubectl --kubeconfig "$ADMIN" "$@"; }
f="$1"; p="$2"; B="$p-binding-$SID"; R="$p-role-$SID"
case "$f" in
 a) K -n "$NS" delete rolebinding "$B" ;;
 b) case "$p" in
      deployer) K -n "$NS" patch role "$R" --type=json -p '[{"op":"replace","path":"/rules/0/verbs","value":["get","watch","create","update","patch","delete"]},{"op":"replace","path":"/rules/1/verbs","value":["get","watch","create","update","patch","delete"]}]' ;;
      readonly) K -n "$NS" patch role "$R" --type=json -p '[{"op":"replace","path":"/rules/0/verbs","value":["get","watch"]},{"op":"replace","path":"/rules/1/verbs","value":["get","watch"]}]' ;;
      ci)       K -n "$NS" patch role "$R" --type=json -p '[{"op":"replace","path":"/rules/0/verbs","value":["get"]}]' ;;
    esac ;;
 c) name="wrong-sa-$SID"; [[ -n "${3:-}" ]] && name="${3}-${SID}"
    K -n "$NS" patch rolebinding "$B" --type=json -p "[{\"op\":\"replace\",\"path\":\"/subjects/0/name\",\"value\":\"$name\"}]" ;;
 d) K -n "$NS" get rolebinding "$B" -o json \
      | jq 'del(.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.metadata.managedFields,.metadata.annotations) | .metadata.namespace="default"' \
      | K create -f -
    K -n "$NS" delete rolebinding "$B" ;;
 *) echo "unknown fault $f"; exit 2 ;;
esac
