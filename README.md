# CLO835 Project 11: RBAC personas and break-glass

Least-privilege kind cluster with three ServiceAccount personas (deployer, readonly, ci), a scripted
permission test suite, and a documented break-glass admin path. Raw YAML and kubectl only, parameterised
by `SID` at the top of `bootstrap.sh`.

Student ID: hoaminu. Namespace: `rbac-hoaminu`.

| Path | Purpose |
|---|---|
| `bootstrap.sh` | One command: cluster, namespace, RBAC, workload, kubeconfigs, test suite |
| `manifests/rbac`, `manifests/workload` | `*.yaml.tpl` templates (`__SID__`) and the rendered `*.yaml` that kubectl applies |
| `tests/rbac-test.sh`, `tests/expected.txt` | Permission suite (`kubectl auth can-i` vs expectations) |
| `break-glass.sh` | Logged cluster-admin shell |
| `runbook.md` | Operating procedures |
| `evidence/bootstrap-run.txt` | Transcript of a clean bootstrap and green test run |
| `drills/` | Practice helpers (fault injection) |

Quick start: `./bootstrap.sh`, then `./tests/rbac-test.sh`. See `runbook.md`.
