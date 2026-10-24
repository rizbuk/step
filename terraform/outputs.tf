output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_version" {
  value = module.eks.cluster_version
}

output "region" {
  value = var.aws_region
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "ingress_load_balancer" {
  description = "NLB hostname created by ingress-nginx. Point DNS records for app/argocd hostnames here."
  value       = try(data.kubernetes_service_v1.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "argocd_url" {
  value = "http://${var.argocd_hostname}"
}

output "app_url" {
  value = "http://${var.app_hostname}"
}

output "argocd_initial_admin_password_command" {
  value = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "gitops_repo_url" {
  value = var.gitops_repo_url
}
