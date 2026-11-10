#!/usr/bin/env bash
# Runs `kubectl auth can-i` for every line of tests/expected.txt using each persona's kubeconfig.
# Exit 0 = all PASS, 1 = at least one FAIL/ERROR.
source "$(dirname "${BASH_SOURCE[0]}")/../env.sh"; cd "$ROOT"
rc=0; pass=0; fail=0
while read -r persona verb res expected _; do
  [[ -z "${persona:-}" || "$persona" == \#* ]] && continue
  resource="${res%%:*}"; args=()
  [[ "$res" == *:* ]] && args=(--subresource="${res#*:}")
  actual="$(kubectl --kubeconfig "kubeconfigs/${persona}.kubeconfig" auth can-i "$verb" "$resource" "${args[@]}" -n "$NS" 2>/dev/null | awk 'NR==1{print $1}')" || true
  [[ "$actual" == "yes" || "$actual" == "no" ]] || actual="error"
  if [[ "$actual" == "$expected" ]]; then
    echo "PASS  $persona $verb $res (expected=$expected)"; pass=$((pass+1))
  else
    echo "FAIL  $persona $verb $res (expected=$expected actual=$actual)"; fail=$((fail+1)); rc=1
  fi
done < tests/expected.txt
echo "---- $pass passed, $fail failed ----"
exit $rc
