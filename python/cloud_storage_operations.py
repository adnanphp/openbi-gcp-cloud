"""Cloud Storage operations via the Google Cloud Python SDK.

Examples of the operations OpenBI uses for object storage. Mirrors the
boto3 script in the AWS companion repo.

Usage:
    export GOOGLE_CLOUD_PROJECT=your-project-id
    export OPENBI_GCS_BUCKET=openbi-raw-your-project-id
    python python/cloud_storage_operations.py

Set OPENBI_GCS_WRITE=1 to also upload, download, and delete a small
test object.

Requires:
    pip install google-cloud-storage
"""

from __future__ import annotations

import os
import sys
from datetime import datetime, timedelta, timezone


def describe_bucket(client, name: str) -> None:
    """Print bucket metadata: storage class, versioning, UBLA, PAP."""
    print(f"\n==> Bucket: {name}")

    try:
        bucket = client.get_bucket(name)
    except Exception as exc:
        print(f"    error: {exc}")
        return

    print(f"    location:            {bucket.location}")
    print(f"    storage class:       {bucket.storage_class}")
    print(f"    versioning:          {bucket.versioning_enabled}")
    print(f"    UBLA:                {bucket.iam_configuration.uniform_bucket_level_access_enabled}")
    print(f"    public access prev:  {bucket.iam_configuration.public_access_prevention}")
    print(f"    lifecycle rules:     {len(bucket.lifecycle_rules or [])}")


def list_objects(client, name: str, prefix: str = "", max_results: int = 10) -> None:
    """List a few objects in the bucket."""
    print(f"\n==> Objects in {name} (prefix='{prefix}')")
    try:
        blobs = client.list_blobs(name, prefix=prefix, max_results=max_results)
        count = 0
        for blob in blobs:
            size_kb = blob.size / 1024 if blob.size else 0
            print(f"    {blob.name}  ({size_kb:.1f} KB, {blob.updated})")
            count += 1
        if count == 0:
            print("    (no objects)")
    except Exception as exc:
        print(f"    error: {exc}")


def optional_write_test(client, bucket_name: str) -> None:
    """If OPENBI_GCS_WRITE=1, upload, download, generate signed URL, delete."""
    if os.environ.get("OPENBI_GCS_WRITE") != "1":
        return

    bucket = client.bucket(bucket_name)
    key = f"__openbi-test/{datetime.now(timezone.utc).isoformat()}.txt"
    body = b"openbi-gcp-cloud storage write test\n"

    print(f"\n==> Upload: {key}")
    blob = bucket.blob(key)
    blob.upload_from_string(body)
    print("    uploaded")

    print("==> Download")
    content = blob.download_as_bytes().decode()
    print(f"    content: {content.strip()}")

    print("==> Generate signed URL (60s)")
    try:
        url = blob.generate_signed_url(
            version="v4",
            expiration=timedelta(seconds=60),
            method="GET",
        )
        print(f"    {url[:100]}...")
        print("    (requires service account with signing capability)")
    except Exception as exc:
        print(f"    signed URL failed: {exc}")
        print("    (in GKE with Workload Identity, use IAM SignBlob API —")
        print("     see: https://cloud.google.com/storage/docs/access-control/signing-urls-without-credentials)")

    print("==> Cleanup: delete")
    blob.delete()
    print("    deleted")


def main() -> int:
    project = os.environ.get("GOOGLE_CLOUD_PROJECT")
    bucket_name = os.environ.get("OPENBI_GCS_BUCKET")

    if not project or not bucket_name:
        print("Set GOOGLE_CLOUD_PROJECT and OPENBI_GCS_BUCKET to run live operations.")
        print()
        print("The SDK operations this script demonstrates:")
        print("  - storage.Client().get_bucket()")
        print("  - .list_blobs(prefix=...)")
        print("  - .upload_from_string(), .download_as_bytes(), .delete()")
        print("  - .generate_signed_url(version='v4')")
        return 0

    try:
        from google.cloud import storage
    except ImportError:
        print("Install: pip install google-cloud-storage")
        return 1

    client = storage.Client(project=project)
    describe_bucket(client, bucket_name)
    list_objects(client, bucket_name)
    optional_write_test(client, bucket_name)

    return 0


if __name__ == "__main__":
    sys.exit(main())
