resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.11.1"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 900

  values = [
    yamlencode({
      crds = {
        install = true
        keep    = false
      }
      configs = {
        params = {
          "server.insecure" = true
        }
        cm = {
          "timeout.reconciliation"       = "60s"
          "application.instanceLabelKey" = "argocd.argoproj.io/instance"
        }
      }
      server = {
        ingress = {
          enabled          = true
          ingressClassName = "nginx"
          hostname         = var.argocd_hostname
          path             = "/"
          pathType         = "Prefix"
          tls              = false
          annotations = {
            "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
            "nginx.ingress.kubernetes.io/ssl-redirect"     = "false"
          }
        }
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      repoServer = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      applicationSet = {
        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }
    })
  ]

  depends_on = [
    module.eks,
    helm_release.ingress_nginx,
  ]
}

resource "kubectl_manifest" "argocd_application" {
  yaml_body = templatefile("${path.module}/../argocd/application.yaml", {
    gitops_repo_url      = var.gitops_repo_url
    gitops_repo_revision = var.gitops_repo_revision
    gitops_repo_path     = var.gitops_repo_path
  })

  depends_on = [helm_release.argocd]
}
