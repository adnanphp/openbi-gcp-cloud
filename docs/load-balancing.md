# Load Balancing

GKE's built-in ingress → Cloud Load Balancer.

## The key difference from AWS

On EKS, you install the AWS Load Balancer Controller (Helm chart, IRSA
role, ServiceAccount annotation). On GKE, the load balancer provisioning
is **part of the platform**.
AWS GKE
─────────────────────────────────── ───────────────────────────────────

Install ALB Controller Nothing to install.

Configure IRSA for the controller

Apply Ingress Apply Ingress

Controller provisions ALB GKE provisions Cloud LB

Wait 2-3 minutes Wait 2-3 minutes

text

Same end result, less setup on GCP.

## What G8 delivers

| Resource | Purpose |
| --- | --- |
| `google_compute_global_address` | Static external IP for the LB |
| ManagedCertificate CRD example | Google-managed TLS certificate |
| FrontendConfig CRD example | HTTPS redirect |
| BackendConfig CRD example | Health checks, timeouts |
| Ingress examples | External HTTP, external HTTPS, internal |

## Reserved static IP

By default, a GKE Ingress gets an ephemeral IP. If the Ingress is
recreated, the IP changes. Reserving a static IP means the address is
stable:

```hcl
resource "google_compute_global_address" "external_lb" {
  name         = "openbi-dev-lb-ip"
  address_type = "EXTERNAL"
}
The Ingress references it by name:

yaml
annotations:
  kubernetes.io/ingress.global-static-ip-name: openbi-dev-lb-ip
External vs internal
Type	Ingress class	Reachable from
External	gce	Internet
Internal	gce-internal	VPC only
Internal load balancers use a regional static IP from a subnet. Set
reserve_internal_ip = true and provide internal_ip_subnet_self_link.

TLS via ManagedCertificate
GKE can provision and renew certificates automatically. Two steps:

Create a ManagedCertificate:

yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: openbi-dev-cert
spec:
  domains:
    - api.openbi.example.com
Reference it in the Ingress:

yaml
annotations:
  networking.gke.io/managed-certificates: openbi-dev-cert
Google validates domain ownership by HTTP-01 challenge. DNS must
point at the load balancer's IP. Otherwise the certificate stays in
Provisioning state.

For a lab without a domain, use HTTP-only.

FrontendConfig
Configures the LB frontend. Currently: HTTPS redirect.

yaml
apiVersion: networking.gke.io/v1beta1
kind: FrontendConfig
metadata:
  name: openbi-frontend-config
spec:
  redirectToHttps:
    enabled: true
    responseCodeName: MOVED_PERMANENTLY_DEFAULT
Reference it in the Ingress:

yaml
annotations:
  networking.gke.io/v1beta1.FrontendConfig: openbi-frontend-config
BackendConfig
Configures health checks and timeouts. On GKE, health checks are
configured on the BackendConfig CRD and referenced from a Service or
Ingress — different from AWS where health check paths are annotations
on the Ingress.

yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: openbi-backend-config
spec:
  healthCheck:
    requestPath: /health
    port: 8000
    checkIntervalSec: 15
  timeoutSec: 30
Path-based routing
Standard Kubernetes Ingress paths work:

yaml
rules:
  - host: api.openbi.example.com
    http:
      paths:
        - path: /kpis
          pathType: Prefix
          backend:
            service:
              name: fastapi
              port: { number: 8000 }
        - path: /superset
          pathType: Prefix
          backend:
            service:
              name: superset
              port: { number: 8088 }
One LB, multiple services behind it.

GCP vs AWS
GCP	AWS
GKE Ingress (built-in)	AWS Load Balancer Controller
gce / gce-internal	alb
Global external IP	internet-facing scheme
Regional internal IP	internal scheme
ManagedCertificate	ACM certificate
FrontendConfig CRD	Ingress annotations
BackendConfig CRD	Service/Ingress annotations
Health check on BackendConfig	Health check on Ingress annotation
Verification status
Not verified against real GCP. Statically validated. See docs/verification.md.
