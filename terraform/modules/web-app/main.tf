locals {
  # Only the values that should produce a new revision when they change.
  config_hash = substr(sha1(jsonencode({
    image      = var.image_tag
    max        = var.max_replicas
    concurrent = var.concurrent_requests
    upstream   = var.api_fqdn
  })), 0, 6)
}

resource "azurerm_container_app" "web" {
  name                         = var.name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Multiple"

  # Rollback needs the previous revision to still exist.
  max_inactive_revisions = 5

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  registry {
    server   = var.registry_login_server
    identity = var.identity_id
  }

  secret {
    name  = "api-shared-secret"
    value = var.shared_secret
  }

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = 8080
    transport                  = "auto"

    # Setting previous_revision_suffix adds a second weight, which is how a split and a rollback are expressed.
    dynamic "traffic_weight" {
      for_each = var.previous_revision_suffix == "" ? [] : [1]

      content {
        revision_suffix = var.previous_revision_suffix
        percentage      = 100 - var.latest_traffic_percentage
      }
    }

    traffic_weight {
      latest_revision = true
      percentage      = var.latest_traffic_percentage
    }
  }

  template {
    # Version plus a config hash, because the tag alone repeats when only configuration changes.
    revision_suffix = "${replace(var.image_tag, ".", "-")}-${local.config_hash}"

    min_replicas = 0
    max_replicas = var.max_replicas

    http_scale_rule {
      name = "http-requests"

      concurrent_requests = var.concurrent_requests
    }

    container {
      name   = "web"
      image  = "${var.registry_login_server}/web:${var.image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "API_UPSTREAM"
        value = "https://${var.api_fqdn}"
      }

      # Nginx sends this to the API as X-Api-Key on every proxied request.
      env {
        name        = "API_SHARED_SECRET"
        secret_name = "api-shared-secret"
      }

      startup_probe {
        transport               = "HTTP"
        port                    = 8080
        path                    = "/health"
        interval_seconds        = 5
        timeout                 = 2
        failure_count_threshold = 12
      }

      readiness_probe {
        transport               = "HTTP"
        port                    = 8080
        path                    = "/health"
        interval_seconds        = 5
        timeout                 = 2
        failure_count_threshold = 3
        success_count_threshold = 1
      }

      liveness_probe {
        transport               = "HTTP"
        port                    = 8080
        path                    = "/health"
        initial_delay           = 10
        interval_seconds        = 10
        timeout                 = 2
        failure_count_threshold = 3
      }
    }
  }

  tags = var.tags
}
