apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-__SID__
  namespace: rbac-__SID__
  labels:
    owner: __SID__
data:
  app.conf: |
    owner: __SID__
    purpose: CLO835 RBAC personas demo
  index.html: |
    <h1>owner: __SID__</h1>
