apiVersion: v1
kind: Secret
metadata:
  name: db-creds-__SID__
  namespace: rbac-__SID__
  labels:
    owner: __SID__
type: Opaque
stringData:
  DB_USER: demo-user
  DB_PASSWORD: dummy-not-a-real-password
