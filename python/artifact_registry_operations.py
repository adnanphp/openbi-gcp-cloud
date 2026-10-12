"""Artifact Registry operations via the Google Cloud Python SDK.

Read-only examples: list repositories, list Docker images, inspect a
repository. Mirrors the AWS ECR script in the companion repo.

Usage:
    export GOOGLE_CLOUD_PROJECT=your-project-id
    export GOOGLE_CLOUD_REGION=europe-west3
    python python/artifact_registry_operations.py

Requires:
    pip install google-cloud-artifact-registry
"""

from __future__ import annotations

import os
import sys


def main() -> int:
    project = os.environ.get("GOOGLE_CLOUD_PROJECT")
    region = os.environ.get("GOOGLE_CLOUD_REGION", "europe-west3")

    if not project:
        print("Set GOOGLE_CLOUD_PROJECT to run live operations.")
        print()
        print("The SDK operations this script demonstrates:")
        print("  - artifactregistry_v1.ArtifactRegistryClient.list_repositories")
        print("  - .list_docker_images")
        print("  - .get_repository")
        return 0

    try:
        from google.cloud import artifactregistry_v1
    except ImportError:
        print("Install: pip install google-cloud-artifact-registry")
        return 1

    client = artifactregistry_v1.ArtifactRegistryClient()
    parent = f"projects/{project}/locations/{region}"

    print(f"==> Repositories in {parent}")
    for repo in client.list_repositories(parent=parent):
        print(f"    - {repo.name}")
        print(f"      format: {repo.format_.name}")
        print(f"      description: {repo.description}")

    print()
    print("==> Docker images in openbi repository")
    repo_path = f"{parent}/repositories/openbi"
    try:
        for image in client.list_docker_images(parent=repo_path):
            print(f"    - {image.name}")
            print(f"      tags: {[t for t in image.tags]}")
            print(f"      uri: {image.uri}")
            print(f"      uploaded: {image.upload_time}")
    except Exception as exc:
        print(f"    error: {exc}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
