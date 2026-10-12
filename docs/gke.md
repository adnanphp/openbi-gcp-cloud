# GKE — Google Kubernetes Engine

The managed Kubernetes cluster that runs OpenBI workloads.

## Configuration

| Setting | Value |
| --- | --- |
| Mode | Standard (not Autopilot) |
| Region | `europe-west3` (regional — control plane across 3 zones) |
| Release channel | REGULAR |
| Kubernetes version | Release-channel default |
| Private nodes | Yes (no external IPs) |
| Private endpoint | Configurable (default: public endpoint) |
| Workload Identity | Enabled |
| Shielded nodes | Enabled |
| Observability | Cloud Logging + Cloud Monitoring + Managed Prometheus |

## Node pools

Two node pools:

| Pool | Machine | Min | Max | Purpose |
| --- | --- | --- | --- | --- |
| primary | e2-medium | 1/zone | 3/zone | Critical workloads (CoreDNS, controllers) |
| spot | e2-medium | 0/zone | 5/zone | User workloads, ~60–90% cheaper |

The spot pool carries a `cloud.google.com/gke-spot=true:NoSchedule` taint
so only pods with the matching toleration land there. Cluster Autoscaler
scales this pool between 0 and 5 per zone based on pending pods.

## Why Standard (not Autopilot)

Autopilot abstracts the node layer — Google manages the nodes, and you
pay per pod's resource request. Elegant, but it hides the design
decisions this repo exists to demonstrate: node pool configuration,
machine types, taints, autoscaling, node SA binding.

For a learning-oriented repo, Standard shows the mechanics.

## Private nodes and Cloud NAT

Nodes have no external IPs. They reach the internet via Cloud NAT
(created in G1). They reach GCP APIs (Artifact Registry, Cloud Logging,
Secret Manager, etc.) via Private Google Access — already enabled on
the subnet.

The cluster's control plane IPs are Google-managed. The `master_ipv4_cidr_block`
(`172.16.0.0/28`) is a private range reserved for the control plane's
internal addresses.

## Workload Identity

Enabled on the cluster with:

```hcl
workload_identity_config {
  workload_pool = "${project_id}.svc.id.goog"
}
This creates the pool PROJECT_ID.svc.id.goog and configures every node
pool with workload_metadata_config { mode = "GKE_METADATA" }.

Once G4 is applied:

Pods that need GCP access get it via the KSA↔GSA binding set up in a
future phase.

No service account JSON keys anywhere.

Node service account
Nodes use the SA created in G2 (openbi-dev-gke-nodes), not the default
Compute Engine SA. The node SA has exactly four roles:

roles/logging.logWriter

roles/monitoring.metricWriter

roles/monitoring.viewer

roles/artifactregistry.reader

That's the least-privilege pattern. The default SA has Editor.

Node configuration
Setting	Value
Image type	COS_CONTAINERD (Container-Optimized OS)
Disk type	pd-balanced
Disk size	50 GB
OAuth scopes	cloud-platform (access controlled by SA roles, not scopes)
Shielded VMs	Secure Boot + Integrity Monitoring enabled
Metadata	disable-legacy-endpoints=true
Note on OAuth scopes: the cloud-platform scope is broad, but on
GCP, IAM roles are the actual access control. The scope acts as an upper
bound. Setting cloud-platform and controlling access via the SA's
roles is the modern pattern.

Applying
bash
cd terraform/environments/dev
terraform apply
A regional GKE cluster with two node pools takes ~10–15 minutes.

After apply:

bash
gcloud container clusters get-credentials openbi-dev --region europe-west3
kubectl get nodes
Six nodes should appear (3 primary, 3 spot) — unless the spot pool is
scaled to zero.

Deleting
bash
terraform destroy
The cluster must be empty before destruction. Any LoadBalancer services,
PersistentVolumeClaims, or Ingress-created resources hold references
that block deletion. Clean up Kubernetes resources first.

GCP vs AWS
GCP	AWS
GKE Standard	EKS managed node groups
GKE Autopilot	(no direct equivalent — closest is Fargate)
Node pool	Node group
Spot VMs (per node pool)	Spot instances (per ASG)
Workload Identity	IRSA (OIDC)
master_ipv4_cidr_block	EKS control plane ENIs in the VPC
Release channel	EKS version + platform version
Shielded GKE Nodes	(no direct equivalent)
Private cluster	EKS private endpoint
Verification status
Not verified against real GCP. Statically validated. See docs/verification.md.
