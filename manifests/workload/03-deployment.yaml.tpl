apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-__SID__
  namespace: rbac-__SID__
  labels:
    app: web-__SID__
    owner: __SID__
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-__SID__
  template:
    metadata:
      labels:
        app: web-__SID__
        owner: __SID__
    spec:
      containers:
        - name: nginx
          image: nginx:1.27-alpine
          ports:
            - containerPort: 80
          volumeMounts:
            - name: site
              mountPath: /usr/share/nginx/html/index.html
              subPath: index.html
      volumes:
        - name: site
          configMap:
            name: app-config-__SID__
