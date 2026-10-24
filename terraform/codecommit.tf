resource "aws_codecommit_repository" "gitops" {
  repository_name = var.cluster_name
  description     = "GitOps repository for ${var.cluster_name} Kubernetes manifests"
}

resource "aws_iam_user" "argocd_codecommit" {
  name = "${var.cluster_name}-argocd-codecommit"
}

resource "aws_iam_user_policy_attachment" "argocd_codecommit_readonly" {
  user       = aws_iam_user.argocd_codecommit.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitReadOnly"
}

resource "aws_iam_service_specific_credential" "argocd_codecommit" {
  service_name = "codecommit.amazonaws.com"
  user_name    = aws_iam_user.argocd_codecommit.name
}

resource "kubectl_manifest" "argocd_repository_secret" {
  yaml_body = templatefile("${path.module}/../argocd/repository-secret.yaml.tpl", {
    repo_url = aws_codecommit_repository.gitops.clone_url_http
    username = aws_iam_service_specific_credential.argocd_codecommit.service_user_name
    password = aws_iam_service_specific_credential.argocd_codecommit.service_password
  })

  depends_on = [helm_release.argocd]
}
