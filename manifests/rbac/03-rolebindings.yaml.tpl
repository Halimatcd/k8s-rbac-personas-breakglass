apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployer-binding-__SID__
  namespace: rbac-__SID__
  labels:
    owner: __SID__
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: deployer-role-__SID__
subjects:
  - kind: ServiceAccount
    name: deployer-__SID__
    namespace: rbac-__SID__
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: readonly-binding-__SID__
  namespace: rbac-__SID__
  labels:
    owner: __SID__
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: readonly-role-__SID__
subjects:
  - kind: ServiceAccount
    name: readonly-__SID__
    namespace: rbac-__SID__
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ci-binding-__SID__
  namespace: rbac-__SID__
  labels:
    owner: __SID__
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ci-role-__SID__
subjects:
  - kind: ServiceAccount
    name: ci-__SID__
    namespace: rbac-__SID__
