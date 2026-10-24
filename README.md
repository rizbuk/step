# 0root-demo: EKS + ArgoCD + GitHub Actions

Проект выполняет все пункты задания: Python backend, Dockerfile, GitHub Action для Docker Hub,
EKS-кластер `0root-demo` с одной managed node group (1 нода), ingress-nginx, ArgoCD и GitOps-доставка
манифестов приложения.

## Что создано в AWS (уже применено)

| Ресурс | Значение |
|---|---|
| Регион | `eu-central-1` |
| EKS-кластер | `0root-demo` (Kubernetes 1.33) |
| Node group | 1 нода `c7i-flex.large` (Free Tier-eligible в этом аккаунте) |
| ingress-nginx | namespace `ingress-nginx`, AWS NLB |
| NLB hostname | `a0558f1c9eb79436798ffdbab4746c51-f6cc821a70968517.elb.eu-central-1.amazonaws.com` |
| ArgoCD | namespace `argocd`, `http://argocd.0root-demo.devops1.0root.com` |
| Приложение | namespace `demo`, `http://app.0root-demo.devops1.0root.com` |
| ArgoCD Application | `0root-demo-app` (auto-sync, prune, self-heal) |
| GitOps-репозиторий | GitHub `https://github.com/rizbuk/step.git` |

Проверка:

```bash
aws eks update-kubeconfig --region eu-central-1 --name 0root-demo
kubectl get nodes
kubectl get pods -A
kubectl -n argocd get applications
```

## Структура

```
.
├── app/                         # Python backend + Dockerfile
├── .github/workflows/           # GitHub Action: build & push в Docker Hub
├── k8s/
│   ├── base/                    # deployment, service, ingress, namespace
│   └── overlays/eks/            # Kustomize overlay с ECR-образом для live-кластера
├── argocd/
│   └── application.yaml         # ArgoCD Application (шаблон, рендерится Terraform)
└── terraform/                   # VPC, EKS, node group, ingress-nginx, ArgoCD
```

## 1. Приложение и Docker Hub

Приложение слушает `PORT` (по умолчанию `8080`) и возвращает `200` и JSON на `/`, `/healthz`, `/readyz`.

GitHub Action `.github/workflows/docker-build-push.yml` собирает `app/` и публикует образ
`<DOCKERHUB_USERNAME>/0root-demo-app:latest` и `:sha-<commit>`.

В настройках GitHub-репозитория добавьте Secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN` (access token Docker Hub с правами Read & Write)

После этого замените образ в `k8s/base/deployment.yaml` на свой Docker Hub-образ
(`docker.io/<DOCKERHUB_USERNAME>/0root-demo-app:latest`). Для live-кластера сейчас используется
ECR-образ через overlay `k8s/overlays/eks`, потому что Docker Hub-учётные данные не были предоставлены.

## 2. Terraform: EKS, node group, ingress-nginx

```bash
cd terraform
terraform init
terraform apply
```

Terraform создаёт:

- VPC с двумя public subnet в разных AZ (NAT не нужен);
- EKS `0root-demo` и managed node group ровно с 1 нодой;
- ingress-nginx (Helm) с AWS NLB;
- ArgoCD (Helm) с Ingress;
- ArgoCD Application, который смотрит на GitHub-репозиторий.

Основные outputs:

```bash
terraform output
```

## 3. ArgoCD

ArgoCD установлен Helm-чартом `argo-cd` (`10.11.1`). Ingress:

- `argocd.0root-demo.devops1.0root.com`
- `server.insecure: true`, поэтому вход по HTTP (TLS можно добавить позже через cert-manager/ACM).

Логин по умолчанию: `admin`.

Пароль:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

## 4. Kubernetes-манифесты приложения

`k8s/base` содержит `Deployment`, `Service`, `Ingress` (host `app.0root-demo.devops1.0root.com`).
`k8s/overlays/eks` переопределяет образ на ECR.

Применить вручную:

```bash
kubectl apply -k k8s/overlays/eks
```

## 5. ArgoCD Application и автоматическое обновление

ArgoCD Application `0root-demo-app` отслеживает Git-репозиторий, ветку `main`, путь `k8s/overlays/eks`,
и имеет `automated: { prune: true, selfHeal: true }`. Каждое изменение в Git автоматически
применяется в кластер (опрос раз в 60 секунд, `timeout.reconciliation: 60s`).

Источник GitOps — GitHub-репозиторий `https://github.com/rizbuk/step.git` (ветка `main`).
ArgoCD Application уже переключён на него; репозиторий публичный, поэтому ArgoCD не требует
отдельных credentials. Токен GitHub использовался только для первоначального `git push`
и не записан ни в репозиторий, ни в Terraform.

Проверено на практике: коммит с изменением `APP_VERSION` был подхвачен ArgoCD автоматически,
приложение переразвернулось и начало возвращать новую версию.

Обновление кода:

```bash
git add .
git commit -m "update manifests"
git push origin main
```

Локальный remote:

```bash
git remote -v
# origin  https://github.com/rizbuk/step.git
```

Для мгновенного обновления вместо опроса добавьте webhook GitHub на ArgoCD
(`/api/webhook`) или настройте webhook в настройках репозитория.

## DNS

В аккаунте AWS нет Route53 hosted zone для `0root.com`, поэтому DNS-записи нужно создать
у регистратора/в DNS-провайдере домена:

```
app.0root-demo.devops1.0root.com.    CNAME  a0558f1c9eb79436798ffdbab4746c51-f6cc821a70968517.elb.eu-central-1.amazonaws.com.
argocd.0root-demo.devops1.0root.com. CNAME  a0558f1c9eb79436798ffdbab4746c51-f6cc821a70968517.elb.eu-central-1.amazonaws.com.
```

До настройки DNS обе точки уже работают через NLB с заголовком `Host`:

```bash
curl -H 'Host: app.0root-demo.devops1.0root.com' \
  http://a0558f1c9eb79436798ffdbab4746c51-f6cc821a70968517.elb.eu-central-1.amazonaws.com/
```

## Удаление

```bash
cd terraform
terraform destroy
```

## Примечания

- В этом AWS-аккаунте разрешены только Free Tier-eligible типы инстансов, поэтому используется
  `c7i-flex.large` (1 нода).
- ECR-образ `0root-demo-app` опубликован для live-демонстрации, так как Docker Hub credentials
  не были переданы. GitHub Action готов к работе после добавления Secrets.
- ArgoCD/приложение доступны в namespace `argocd` и `demo`; ingress-класс `nginx`.
