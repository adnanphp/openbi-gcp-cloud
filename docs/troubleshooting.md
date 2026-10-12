# Troubleshooting

Common failure modes on GCP.

## Terraform

### "Error 403: The caller does not have permission"

The account running terraform is missing a role. Common missing roles:

- `roles/compute.networkAdmin` — for VPC
- `roles/container.admin` — for GKE
- `roles/cloudsql.admin` — for Cloud SQL
- `roles/iam.serviceAccountAdmin` — for service accounts
- `roles/secretmanager.admin` — for secrets
- `roles/resourcemanager.projectIamAdmin` — to grant IAM

Grant the roles or use an account with `roles/owner` (dev only).

### "Error: Error creating Network: googleapi: Error 403: Compute Engine API has not been used in project..."

An API isn't enabled. Enable it:

```bash
gcloud services enable compute.googleapis.com
Or run the full gcloud services enable list in deployment.md.

"Error: Error creating Subnetwork: Invalid value for field 'resource.ipCidrRange': '10.30.0.0/20'. Must be smaller than the range of the network..."
Your subnet CIDR doesn't fit inside the VPC CIDR. Verify with:

bash
gcloud compute networks describe openbi-dev-vpc
Cloud SQL creation hangs at "Creating instance"
Cloud SQL requires the Service Networking API and Private Service Access peering. If it hangs:

bash
gcloud services vpc-peerings list --network=openbi-dev-vpc
The peering should exist. If not, the google_service_networking_connection resource didn't complete — check Terraform's plan for that resource.

GKE
"gcloud container clusters get-credentials: cluster not found"
The cluster name and region must match. Verify:

bash
gcloud container clusters list
Pods
Pods stuck in Pending
Common causes:

Node pool scaled to zero and autoscaler not enabled. Check with:

bash
kubectl describe pod -n openbi <pod-name>
Look for "no nodes available". GKE's node auto-provisioning needs
to be enabled, or the node pool needs a min count above zero.

Resource requests exceed node capacity. e2-medium has 4 GB RAM.
Requesting 5 GB will never schedule.

Taints not tolerated. The spot pool has a taint. Pods without
the matching toleration won't schedule there.

Pods stuck in ImagePullBackOff
The image isn't in Artifact Registry

The node SA lacks roles/artifactregistry.reader

The image reference has the wrong region or project

Check the node SA's roles:

bash
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:openbi-dev-gke-nodes" \
  --format="table(bindings.role)"
Cloud SQL sidecar fails
The cloud-sql-proxy sidecar needs:

roles/cloudsql.client on the pod's GSA

The instance connection name to be correct

The Cloud SQL Admin API enabled

Check sidecar logs:

bash
kubectl -n openbi logs <pod> -c cloud-sql-proxy
ExternalSecret stuck in SecretSyncedError
bash
kubectl -n openbi describe externalsecret <name>
Common causes:

GSA not bound to KSA (check ESO ServiceAccount annotation)

Secret doesn't exist in Secret Manager

Secret Manager API not enabled

IAM condition excludes the secret

Check ESO logs:

bash
kubectl -n external-secrets logs -l app.kubernetes.io/name=external-secrets --tail=50
Workload Identity not working
If a pod can't authenticate to GCP APIs:

Check the KSA annotation:

bash
kubectl -n openbi get sa fastapi -o yaml | grep gcp-service-account
Should reference the GSA email.

Check the KSA → GSA binding in GCP:

bash
gcloud iam service-accounts get-iam-policy FASTAPI_GSA_EMAIL
Should show a serviceAccount:PROJECT.svc.id.goog[openbi/fastapi] member
with role roles/iam.workloadIdentityUser.

Check the cluster has Workload Identity enabled:

bash
gcloud container clusters describe openbi-dev --region europe-west3 \
  --format="value(workloadIdentityConfig.workloadPool)"
Should print PROJECT.svc.id.goog.

Ingress / Load Balancer
Ingress has no ADDRESS
GKE takes 3–5 minutes to provision the LB. If it stays <pending>:

bash
kubectl -n openbi describe ingress <name>
Look at Events. Common issues:

The static IP annotation references a name that doesn't exist

The Service referenced by the backend doesn't have ready endpoints

The BackendConfig health check fails (target group has no healthy targets)

502 / 503 errors
Usually the health check fails. Verify:

bash
kubectl -n openbi port-forward svc/fastapi 8000:8000
curl http://localhost:8000/health
The path configured in BackendConfig (/health) must return 200.

Certificate stuck in Provisioning
DNS for the domain must point at the load balancer's IP. Verify:

bash
dig +short api.openbi.example.com
Should match the reserved static IP from Terraform output.

General debugging
What did Terraform create?
bash
cd terraform/environments/dev
terraform state list
terraform output
Recent events
bash
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -30
Quotas
GCP projects have per-region quotas (CPUs, IPs, disks). Check:

bash
gcloud compute regions describe europe-west3 --format="value(quotas)"
Verification status
Not verified against real GCP. See verification.md.
