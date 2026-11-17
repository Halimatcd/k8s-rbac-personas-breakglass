# Runbook - RBAC personas and break-glass

Start any session with:

```bash
cd /workspaces/k8s-rbac-personas-breakglass
source ./env.sh          # exports SID, NS, DHUSER, APP_TAG, ADMIN from bootstrap.sh
echo "$SID $NS"
```

Personas: `deployer`, `readonly`, `ci`. Their kubeconfigs are in `kubeconfigs/` (git-ignored).

## 1. Bootstrap from a clean host

Prerequisites: Docker, kind, kubectl, jq. `SID` and `DHUSER` are set at the top of `bootstrap.sh` only.

```bash
time ./bootstrap.sh
```

Healthy looks like 2 web pods Running, 3 ServiceAccounts, 3 Roles, 3 RoleBindings and a final `Bootstrap finished OK` line:

```bash
kubectl --kubeconfig kubeconfigs/admin.kubeconfig get all,sa,role,rolebinding -n "$NS"
```

Rerunning is safe. A recorded run is in `evidence/bootstrap-run.txt`.

## 2. Run the permission test suite

```bash
./tests/rbac-test.sh; echo "exit=$?"
```

- `PASS persona verb resource (expected=...)` means `kubectl auth can-i` matched `tests/expected.txt`.
- `FAIL ... (expected=yes actual=no)` means a permission is missing. `expected=no actual=yes` means too much access.
- `actual=error` means the kubeconfig is missing or expired, or the cluster is unreachable (see section 7).
- Exit code 0 means all green, 1 means at least one mismatch.
- `pods:log` in the file means resource `pods` with `--subresource=log`.

## 3. Act as each persona

```bash
# deployer: apply / scale / rollout
kubectl --kubeconfig kubeconfigs/deployer.kubeconfig apply -f manifests/workload/03-deployment.yaml
kubectl --kubeconfig kubeconfigs/deployer.kubeconfig patch deploy web-$SID -p '{"spec":{"replicas":3}}'
kubectl --kubeconfig kubeconfigs/deployer.kubeconfig rollout status deploy/web-$SID --timeout=60s
kubectl --kubeconfig kubeconfigs/deployer.kubeconfig get pods

# readonly: get / describe
kubectl --kubeconfig kubeconfigs/readonly.kubeconfig get pods
kubectl --kubeconfig kubeconfigs/readonly.kubeconfig get deploy,svc,cm
kubectl --kubeconfig kubeconfigs/readonly.kubeconfig describe pod -l app=web-$SID
kubectl --kubeconfig kubeconfigs/readonly.kubeconfig get secret db-creds-$SID        # Forbidden (expected)

# ci: roll an image, verify it landed
kubectl --kubeconfig kubeconfigs/ci.kubeconfig set image deployment/web-$SID nginx=nginx:1.27
kubectl --kubeconfig kubeconfigs/ci.kubeconfig get deploy web-$SID -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
kubectl --kubeconfig kubeconfigs/ci.kubeconfig get pods                              # Forbidden (expected)
```

To roll CI to your own image use `nginx=$DHUSER/clo835-app:$APP_TAG` (it must serve on port 80).

These are consequences of least privilege, not bugs:
- `kubectl scale` needs the `deployments/scale` subresource, which the deployer Role does not grant. Use `patch`.
- `kubectl logs` needs `pods/log`, which nobody has.
- `kubectl rollout status` needs list and watch, which CI lacks. It hangs retrying, so CI verifies with `get`.

Reset demo state (admin): `kubectl --kubeconfig kubeconfigs/admin.kubeconfig apply -f manifests/workload/`

## 4. Diagnose an authorization failure

1. Find who is failing: `./tests/rbac-test.sh | grep FAIL`
2. Read the Forbidden message. It names user, verb, resource, API group and namespace:
   ```bash
   kubectl --kubeconfig kubeconfigs/readonly.kubeconfig get pods
   # User "system:serviceaccount:rbac-<sid>:readonly-<sid>" cannot list resource "pods" in API group "" in the namespace "rbac-<sid>"
   ```
3. See what the persona can still do:
   `kubectl --kubeconfig kubeconfigs/<persona>.kubeconfig auth can-i --list -n "$NS"`
4. Interpret (persona side only):

| Symptom | Likely break |
|---|---|
| Persona keeps some rules but one verb or resource is gone | Role verbs or resources edited |
| Persona has only the default selfsubject basics | Binding layer: deleted, wrong subject or wrong namespace |
| Another persona's expected-no flipped to yes, or it can do something new | Wrong subject pointing at that persona's ServiceAccount |

5. Only then open break-glass and inspect in this order: binding exists, binding subject name and namespace, binding roleRef, role verbs and resources.
   ```bash
   ./break-glass.sh kubectl get role,rolebinding -n "$NS" -o yaml
   ./break-glass.sh kubectl get rolebinding -A -l owner="$SID"     # catches a binding in the wrong namespace
   ```

## 5. Invoke break-glass

Break-glass is permitted only after persona-side diagnosis is finished and the fix needs rights no persona has, for example inspecting or repairing RBAC objects. Every use is announced, kept as short as possible and logged to `break-glass.log` by the script. The personas must never be given cluster-admin, because one leaked token (especially the CI one) would then control the whole cluster including every Secret, and least privilege exists to limit that blast radius. RBAC objects are the one thing the personas must not be able to edit, otherwise they could grant themselves anything. Routine work never needs admin.

```bash
./break-glass.sh                      # interactive cluster-admin subshell, prompt shows [BREAK-GLASS]
kubectl get role,rolebinding -n rbac-<sid> -o yaml
exit                                  # leaves break-glass and returns to the normal shell
```

Manual equivalent: `export KUBECONFIG=$PWD/kubeconfigs/admin.kubeconfig` (made with `kind get kubeconfig --name clo835`). Undo it with `unset KUBECONFIG`. The old `kind get kubeconfig-path` no longer exists.

## 6. Repair

```bash
./break-glass.sh kubectl apply -f manifests/rbac/
./break-glass.sh kubectl -n default delete rolebinding -l owner="$SID" --ignore-not-found   # only if a binding was put in 'default'
./tests/rbac-test.sh; echo "exit=$?"                                                       # must be all PASS, exit 0
```

Interactive variant: `./break-glass.sh`, then `kubectl apply -f manifests/rbac/`, then `exit`, then the suite.
`apply` restores a deleted binding, reverts edited verbs and corrects a wrong subject. For a binding in the wrong namespace it recreates the correct one, and the stray one in `default` is deleted separately.

## 7. Regenerate a persona kubeconfig (expired token)

Tokens last 48 hours. Symptoms are `Unauthorized`, or every check failing with `actual=error`.

```bash
./bootstrap.sh kubeconfigs        # re-mints all three, touches nothing else
./tests/rbac-test.sh
```
