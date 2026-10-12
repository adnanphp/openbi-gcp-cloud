"""Cloud SQL PostgreSQL connection examples.

Demonstrates the two authentication paths:

  1. Cloud SQL Auth Proxy (recommended) — connects via localhost,
     authenticates via IAM, no password needed for IAM users.
  2. Direct private IP connection with password from Secret Manager.

Usage (Auth Proxy path, from a GKE pod or local machine):

    cloud-sql-proxy --port 5432 PROJECT:REGION:INSTANCE &

    psql "host=127.0.0.1 port=5432 dbname=openbi user=openbiadmin"

Requires:
    pip install google-cloud-secret-manager psycopg2-binary
"""

from __future__ import annotations

import json
import os
import sys


def get_password_from_secret(secret_id: str) -> dict:
    """Fetch credentials from Secret Manager."""
    from google.cloud import secretmanager

    client = secretmanager.SecretManagerClient()
    project = os.environ.get("GOOGLE_CLOUD_PROJECT")
    name = f"projects/{project}/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    payload = response.payload.data.decode("utf-8")
    return json.loads(payload)


def connect_direct(host: str, port: int, db: str, user: str, password: str):
    """Connect to Cloud SQL private IP directly (requires VPC access)."""
    import psycopg2

    return psycopg2.connect(
        host=host,
        port=port,
        dbname=db,
        user=user,
        password=password,
        sslmode="require",
    )


def main() -> int:
    secret_id = os.environ.get("OPENBI_DB_SECRET", "openbi/dev/db")

    if not os.environ.get("GOOGLE_CLOUD_PROJECT"):
        print("Set GOOGLE_CLOUD_PROJECT to test the Secret Manager path.")
        print()
        print("Two connection patterns for Cloud SQL:")
        print()
        print("  1. Cloud SQL Auth Proxy (recommended)")
        print("     - Run the proxy as a sidecar or local binary.")
        print("     - Connect to localhost:5432.")
        print("     - Proxy authenticates via IAM; no password needed.")
        print("     - Works from anywhere with GCP credentials.")
        print()
        print("  2. Direct private IP")
        print("     - Only works from inside the VPC (GKE pod, bastion).")
        print("     - Uses password from Secret Manager.")
        print("     - Faster (no proxy hop), but requires VPC access.")
        return 0

    try:
        creds = get_password_from_secret(secret_id)
    except Exception as exc:
        print(f"Failed to read secret: {exc}")
        return 1

    print(f"==> Read credentials from Secret Manager ({secret_id})")
    print(f"    host: {creds['host']}")
    print(f"    dbname: {creds['dbname']}")
    print(f"    username: {creds['username']}")
    print(f"    instance: {creds['instance']}")
    print()

    print("==> Attempting direct connection to private IP")
    try:
        conn = connect_direct(
            host=creds["host"],
            port=creds["port"],
            db=creds["dbname"],
            user=creds["username"],
            password=creds["password"],
        )
        with conn.cursor() as cur:
            cur.execute("SELECT version()")
            print(f"    connected: {cur.fetchone()[0][:60]}")
        conn.close()
    except Exception as exc:
        print(f"    failed: {exc}")
        print("    (expected unless running inside the VPC)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
