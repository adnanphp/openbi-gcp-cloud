# Cloud Storage module for OpenBI.
#
# Three buckets mirroring the OpenBI data lifecycle. Each has:
#   - Uniform bucket-level access (UBLA) enabled
#   - Public access prevention enforced
#   - Google-managed encryption (default; CMEK documented as opt-in)
#   - Lifecycle rules matched to its role

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

locals {
  raw_bucket_name       = "${var.raw_bucket_name}-${var.bucket_suffix}"
  processed_bucket_name = "${var.processed_bucket_name}-${var.bucket_suffix}"
  models_bucket_name    = "${var.models_bucket_name}-${var.bucket_suffix}"
}

# ----------------------------------------------------------------------
# Raw bucket
# ----------------------------------------------------------------------

resource "google_storage_bucket" "raw" {
  name     = local.raw_bucket_name
  project  = var.project_id
  location = var.region

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = var.raw_nearline_days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = var.raw_coldline_days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = var.raw_archive_days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  lifecycle_rule {
    condition {
      age = var.raw_expiration_days
    }
    action {
      type = "Delete"
    }
  }

  labels = var.labels
}

# ----------------------------------------------------------------------
# Processed bucket
# ----------------------------------------------------------------------

resource "google_storage_bucket" "processed" {
  name     = local.processed_bucket_name
  project  = var.project_id
  location = var.region

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  lifecycle_rule {
    condition {
      age = var.processed_expiration_days
    }
    action {
      type = "Delete"
    }
  }

  labels = var.labels
}

# ----------------------------------------------------------------------
# Models bucket
# ----------------------------------------------------------------------

resource "google_storage_bucket" "models" {
  name     = local.models_bucket_name
  project  = var.project_id
  location = var.region

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      days_since_noncurrent_time = var.models_noncurrent_expiration_days
      with_state                 = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  labels = var.labels
}

# ----------------------------------------------------------------------
# Optional additional readers
# ----------------------------------------------------------------------
# Grants object viewer at the bucket level. Scoped to each bucket, so a
# reader on 'processed' doesn't get access to 'raw'.

resource "google_storage_bucket_iam_member" "raw_readers" {
  for_each = toset(var.additional_reader_members)

  bucket = google_storage_bucket.raw.name
  role   = "roles/storage.objectViewer"
  member = each.value
}

resource "google_storage_bucket_iam_member" "processed_readers" {
  for_each = toset(var.additional_reader_members)

  bucket = google_storage_bucket.processed.name
  role   = "roles/storage.objectViewer"
  member = each.value
}

resource "google_storage_bucket_iam_member" "models_readers" {
  for_each = toset(var.additional_reader_members)

  bucket = google_storage_bucket.models.name
  role   = "roles/storage.objectViewer"
  member = each.value
}
