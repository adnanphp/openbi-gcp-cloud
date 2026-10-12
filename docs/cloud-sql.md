# Cloud SQL for PostgreSQL

GCP's managed Postgres. Replaces the local Postgres in the OpenBI
deployment.

## Configuration

| Setting | Value |
| --- | --- |
| Version | PostgreSQL 16 |
| Tier | db-f1-micro (dev) |
| Disk | 20 GB SSD, autoscaling enabled |
| Availability | ZONAL (dev); REGIONAL for HA in production |
| IP | Private only (no public IP) |
| IAM auth | Enabled |
| Backups | Enabled, 7-day retention, PITR |
| Flags | Analytical tuning (see below) |

## Private Service Access

Cloud SQL with private IP requires **Private Service Access** — a VPC
peering between your VPC and Google's managed-services network. This
must be set up once per VPC, and Cloud SQL instances get their private
IPs from the reserved range.

The `cloud-sql` module creates this automatically:
VPC (10.30.0.0/20)
│
│ VPC peering
▼
Google managed services network (servicenetworking.googleapis.com)
│
▼
Cloud SQL instance (private IP)

text

The peering is a one-time setup. If you have multiple Cloud SQL
instances or other Google-managed services (Memorystore, Filestore),
they all share the same peering.

## Authentication

Two paths:

### 1. Cloud SQL Auth Proxy (recommended)

The proxy runs as a local binary or a sidecar container. It:
- Connects outbound to Cloud SQL
- Authenticates using the caller's IAM identity
- Exposes a local TCP port that the client connects to

**Advantages:**
- No password needed (uses IAM)
- Works from anywhere with GCP credentials
- Encrypts automatically
- No network path required (uses Cloud SQL Admin API)

**Used by OpenBI in GKE:** a sidecar container runs `cloud-sql-proxy`,
and the FastAPI container connects to `127.0.0.1:5432`.

### 2. Direct private IP connection

From inside the VPC (a GKE pod or a bastion), you can connect directly
to the instance's private IP. Uses the password stored in Secret
Manager.

**Advantages:**
- One fewer network hop
- Simpler container setup

**Disadvantages:**
- Requires VPC routing (only works from inside the VPC)
- Password must be managed

OpenBI supports both. The Auth Proxy is the default for GKE workloads.

## IAM database authentication

Cloud SQL supports IAM database auth as an alternative to passwords.
The user's identity comes from their GCP service account (via Workload
Identity on GKE).

To use it:

```sql
-- In the DB, grant the IAM role to a user
CREATE USER "user@project.iam" LOGIN;
GRANT cloudsql.iam.roles.login TO "user@project.iam";
Then connect with an OAuth token as the password. The token is
short-lived; the client library typically handles refresh.

For OpenBI's initial deployment, we use password auth (simpler); IAM
auth is documented as the recommended production pattern.

Flags (analytical tuning)
Flag	Value	Why
log_min_duration_statement	1000	Log queries slower than 1 second
track_io_timing	on	Better query plans; feeds Query Insights
log_connections	on	Audit trail
log_disconnections	on	Audit trail
cloudsql.iam_authentication	on	Enable IAM auth
Credentials in Secret Manager
The module generates a random password for the openbiadmin user,
creates the openbi/dev/db secret in Secret Manager, and stores a JSON
object with connection details:

json
{
  "host": "10.x.x.x",
  "port": 5432,
  "username": "openbiadmin",
  "password": "...",
  "dbname": "openbi",
  "instance": "project:region:openbi-dev-pg"
}
The External Secrets Operator (from a future phase) reads this secret
and materializes it as a Kubernetes Secret in the openbi namespace.

Applying
bash
cd terraform/environments/dev
terraform apply
Cloud SQL provisioning takes ~10–15 minutes. The Private Service Access
peering happens first.

Verifying
bash
gcloud sql instances describe openbi-dev-pg
gcloud sql databases list --instance=openbi-dev-pg
Connecting from your laptop
The instance has no public IP. To connect, run the Cloud SQL Auth Proxy:

bash
cloud-sql-proxy PROJECT:REGION:openbi-dev-pg --port 5432 &

psql "host=127.0.0.1 port=5432 dbname=openbi user=openbiadmin"
The proxy requires your GCP identity to have roles/cloudsql.client.

GCP vs AWS
GCP	AWS
Cloud SQL	RDS
Private Service Access	VPC subnet groups + security groups
Cloud SQL Auth Proxy	(no direct equivalent; use RDS Proxy or IAM auth)
Private IP	Private subnet
db-f1-micro	db.t4g.micro
ZONAL / REGIONAL	Single-AZ / Multi-AZ
Query Insights	Performance Insights
Database flags	Parameter groups
IAM database auth	IAM database authentication
Secret Manager auto-managed	RDS-managed master password
Verification status
Not verified against real GCP. Statically validated. See docs/verification.md.
