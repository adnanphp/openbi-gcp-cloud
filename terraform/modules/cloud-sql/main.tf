# Cloud SQL module for OpenBI.
#
# Creates a PostgreSQL instance with:
#   - Private IP (via Private Service Access)
#   - IAM database authentication
#   - Auto-generated password stored in Secret Manager
#   - Tuned flags for analytical workloads
#   - Automated backups

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# ----------------------------------------------------------------------
# Private Service Access
# ----------------------------------------------------------------------
# Reserve an IP range in the VPC and peer it to Google's service network.
# Cloud SQL private IPs come from this range.

resource "google_compute_global_address" "psa" {
  count = var.create_private_service_access ? 1 : 0

  name          = var.psa_address_name
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.psa_prefix_length
  network       = var.network_id
}

resource "google_service_networking_connection" "psa" {
  count = var.create_private_service_access ? 1 : 0

  network                 = var.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa[0].name]

  deletion_policy = "ABANDON"
}

# ----------------------------------------------------------------------
# Random password for the default user
# ----------------------------------------------------------------------
# Cloud SQL does not auto-manage passwords like RDS. We generate one,
# store it in Secret Manager, and reference it from the deployment.

resource "random_password" "db_password" {
  length      = 32
  special     = true
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2

  # Cloud SQL password rules: no /, @, ", spaces.
  override_special = "!$%^&*()-_=+[]{}<>?"
}

# ----------------------------------------------------------------------
# Cloud SQL instance
# ----------------------------------------------------------------------

resource "google_sql_database_instance" "this" {
  name             = var.instance_name
  project          = var.project_id
  region           = var.region
  database_version = var.database_version

  # Ensure PSA is up before creating the instance.
  depends_on = [google_service_networking_connection.psa]

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size_gb
    disk_autoresize   = var.disk_autoresize
    disk_type         = "PD_SSD"

    # Backups
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00" # UTC
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = var.backup_retention_days
        retention_unit   = "COUNT"
      }
    }

    # Maintenance window
    maintenance_window {
      day          = 7 # Sunday
      hour         = 4 # 04:00 UTC
      update_track = "stable"
    }

    # Private IP only (no public IP).
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network_self_link
      enable_private_path_for_google_cloud_services = true

      # IAM database authentication.
      # (Set at the instance level via database_flags below.)
    }

    # Tuned flags for analytical workloads.
    database_flags {
      name  = "log_min_duration_statement"
      value = "1000"
    }

    database_flags {
      name  = "track_io_timing"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }

    # Logging: send PostgreSQL logs to Cloud Logging.
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    user_labels = var.labels
  }

  deletion_protection = var.deletion_protection

  # The default postgres user is created by Google. We set its password
  # below.
}

# ----------------------------------------------------------------------
# Set the password for the default 'postgres' user
# ----------------------------------------------------------------------

resource "google_sql_user" "postgres_password" {
  name     = "postgres"
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  password = random_password.db_password.result
}

# ----------------------------------------------------------------------
# Application database and user
# ----------------------------------------------------------------------

resource "google_sql_database" "this" {
  name     = var.database_name
  project  = var.project_id
  instance = google_sql_database_instance.this.name
}

resource "google_sql_user" "app_user" {
  name     = var.database_user
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  password = random_password.db_password.result
}

# ----------------------------------------------------------------------
# Store the connection details in Secret Manager
# ----------------------------------------------------------------------

resource "google_secret_manager_secret" "db_credentials" {
  project   = var.project_id
  secret_id = "openbi/dev/db"

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "db_credentials" {
  secret = google_secret_manager_secret.db_credentials.id

  secret_data = jsonencode({
    host     = google_sql_database_instance.this.private_ip_address
    port     = 5432
    username = var.database_user
    password = random_password.db_password.result
    dbname   = google_sql_database.this.name
    instance = google_sql_database_instance.this.connection_name
  })
}
