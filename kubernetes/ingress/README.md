# Ingress

Example Kubernetes Ingress resources for GKE. GKE provisions a Cloud
Load Balancer when these are applied — no controller to install.

## Files

| File | Purpose |
| --- | --- |
| `examples.yaml` | External HTTP, external HTTPS, internal Ingress examples |
| `frontendconfig.yaml` | FrontendConfig CRD (HTTPS redirect) |
| `managed-certificate.yaml` | ManagedCertificate CRD (Google-managed TLS) |

## Key annotations

| Annotation | Purpose |
| --- | --- |
| `kubernetes.io/ingress.class: "gce"` | External Cloud LB (or use `ingressClassName`) |
| `kubernetes.io/ingress.class: "gce-internal"` | Internal Cloud LB |
| `kubernetes.io/ingress.global-static-ip-name` | Reference a reserved static IP |
| `networking.gke.io/managed-certificates` | Reference a ManagedCertificate |
| `networking.gke.io/v1beta1.FrontendConfig` | Reference a FrontendConfig |

## How it differs from AWS

| Aspect | GKE | AWS (EKS) |
| --- | --- | --- |
| Controller | Built-in | Install AWS Load Balancer Controller |
| Ingress class | `gce` / `gce-internal` | `alb` |
| Static IP | `networking.gke.io` annotations + reserved address | Depends on controller config |
| TLS | ManagedCertificate CRD (Google-managed) | ACM certificate + annotation |
| Path-based routing | Standard Ingress paths | Standard Ingress paths |
| Health checks | BackendConfig CRD | Annotation on Service |
