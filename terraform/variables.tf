variable "aws_region" {
  description = "AWS region for the EKS cluster."
  type        = string
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "0root-demo"
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.33"
}

variable "domain" {
  description = "Base DNS domain for ingress hostnames."
  type        = string
  default     = "devops1.0root.com"
}

variable "argocd_hostname" {
  description = "ArgoCD DNS name."
  type        = string
  default     = "argocd.0root-demo.devops1.0root.com"
}

variable "app_hostname" {
  description = "Application DNS name."
  type        = string
  default     = "app.0root-demo.devops1.0root.com"
}

variable "gitops_repo_url" {
  description = "Git repository containing the Kubernetes manifests."
  type        = string
  default     = "https://github.com/rizbuk/step.git"
}

variable "gitops_repo_revision" {
  description = "Git revision ArgoCD tracks."
  type        = string
  default     = "main"
}

variable "gitops_repo_path" {
  description = "Path to the Kustomize overlay inside the GitOps repository."
  type        = string
  default     = "k8s/overlays/eks"
}

variable "node_instance_type" {
  description = "Instance type for the single EKS managed node."
  type        = string
  default     = "c7i-flex.large"
}
