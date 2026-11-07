apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployer-role-__SID__
  namespace: rbac-__SID__
  labels:
    owner: __SID__
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ci-role-__SID__
  namespace: rbac-__SID__
  labels:
    owner: __SID__
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "patch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: readonly-role-__SID__
  namespace: rbac-__SID__
  labels:
    owner: __SID__
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "events"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch"]
