apiVersion: v1
kind: Secret
metadata:
  name: 0root-demo-codecommit
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: ${repo_url}
  username: ${username}
  password: ${password}
