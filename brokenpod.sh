apiVersion: v1
kind: Pod
metadata:
  name: broken-nginx
  namespace: default
spec:
  containers:
  - name: nginx-container
    image: nginx:latest
    ports:
    - containerPort: 80
