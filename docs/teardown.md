# Teardown Guide

How to destroy an OpenBI deployment on GCP.

## ⚠️ Read first

Teardown destroys real GCP resources. Before running:

1. **Confirm nothing in Cloud Storage is important.** The buckets are
   deleted by `terraform destroy`.
2. **Confirm no Cloud SQL backups are needed.** Point-in-time recovery
   is deleted with the instance.
3. **Confirm any LoadBalancer resources in the cluster are deleted
   first.** GKE's managed LB resources block cluster deletion if they
   still exist.

## Safe teardown

```bash
./scripts/teardown.sh         # dry-run
./scripts/teardown.sh --yes   # actually destroy
Order
Delete OpenBI Kubernetes resources (Ingress first → LB deleted)

Delete External Secrets ClusterSecretStore

Delete cluster-addon YAMLs (if any)

Uninstall Helm releases

Delete namespaces

terraform destroy

Manual teardown
bash
kubectl delete -k kubernetes/openbi-app/overlays/dev
kubectl delete -f kubernetes/external-secrets/cluster-secret-store.yaml
helm uninstall external-secrets -n external-secrets
kubectl delete namespace openbi external-secrets

cd terraform/environments/dev
terraform destroy -var="resource_suffix=$(gcloud config get-value project)"
Verifying cleanup
bash
gcloud compute instances list
gcloud sql instances list
gcloud storage buckets list | grep openbi
gcloud pubsub topics list | grep openbi
gcloud pubsub subscriptions list | grep openbi
gcloud compute addresses list
gcloud artifact repositories list --location=europe-west3
gcloud secrets list | grep openbi
gcloud logging buckets list --location=global
Likely orphans
Load balancer resources. If an Ingress was deleted after the
cluster was destroyed, the LB persists. Check:

bash
gcloud compute forwarding-rules list
gcloud compute target-pools list
Delete any with names starting with k8s-.

Persistent disks. PVCs backed by pd-* disks persist if the cluster
is deleted without deleting the PVCs first.

Reserved IPs. The static external IP is not deleted by terraform
destroy unless it's declared as a Terraform resource (it is, in our
case, so it will be deleted).

What's not cleaned automatically
Artifact Registry images. The repository is deleted by terraform,
but if you have images in other registries, they're yours to clean.

GCS bucket contents. force_destroy = false on the buckets means
deletion fails if there are objects. Empty the buckets first or set
force_destroy = true before destroy.

Verification status
Not verified against real GCP. See verification.md.
