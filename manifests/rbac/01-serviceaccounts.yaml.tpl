apiVersion: v1
kind: ServiceAccount
metadata:
  name: deployer-__SID__
  namespace: rbac-__SID__
  labels:
    owner: __SID__
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: readonly-__SID__
  namespace: rbac-__SID__
  labels:
    owner: __SID__
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ci-__SID__
  namespace: rbac-__SID__
  labels:
    owner: __SID__
