# External Secrets Operator

Syncs secrets from Secret Manager into Kubernetes Secrets. No secret
material lives in this repository or in plain Kubernetes YAML.

## Installation

```bash
ESO_SA=$(cd terraform/environments/dev && terraform output -raw eso_service_account_email)

helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set serviceAccount.name=external-secrets \
  --set serviceAccount.annotations."iam\.gke\.io/gcp-service-account"=$ESO_SA
The iam.gke.io/gcp-service-account annotation is GKE's Workload
Identity mechanism — it tells GKE to expose the GSA's identity to pods
using this KSA.

The binding itself (KSA → GSA) is created by Terraform in
terraform/modules/secrets/.

ClusterSecretStore
See cluster-secret-store.yaml. Apply once per cluster:

bash
kubectl apply -f kubernetes/external-secrets/cluster-secret-store.yaml
ExternalSecret
See example-external-secret.yaml. Applied per secret, per namespace.

The G6 module created openbi/dev/db with connection details for Cloud
SQL. The example shows how to sync it into a Kubernetes Secret.
