#!/usr/bin/env bash
# Breaks something at random and hides what it was. Diagnose, then run drills/reveal.sh
set -euo pipefail
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kinds=(a b c d); personas=(deployer readonly ci); other=""
k="${kinds[RANDOM%4]}"; p="${personas[RANDOM%3]}"
if [[ "$k" == c && $((RANDOM%2)) -eq 0 ]]; then
  for o in "${personas[@]}"; do [[ "$o" != "$p" ]] && other="$o"; done
fi
echo "$k $p $other" > "$D/.last"
"$D/fault.sh" "$k" "$p" $other >/dev/null 2>&1
echo "Something is broken. Run ./tests/rbac-test.sh. Limit: 10 minutes to full recovery."
