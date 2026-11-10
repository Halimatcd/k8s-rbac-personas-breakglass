apiVersion: v1
kind: Service
metadata:
  name: web-__SID__
  namespace: rbac-__SID__
  labels:
    app: web-__SID__
    owner: __SID__
spec:
  type: ClusterIP
  selector:
    app: web-__SID__
  ports:
    - port: 80
      targetPort: 80
