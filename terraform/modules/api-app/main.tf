resource "azurerm_container_app" "api" {
  name                         = var.name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

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
    external_enabled           = false
    allow_insecure_connections = false
    target_port                = 8080
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    http_scale_rule {
      name                = "http-requests"
      concurrent_requests = 10
    }

    container {
      name   = "api"
      image  = "${var.registry_login_server}/api:${var.image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      # Reported by /status, so the running version cannot drift from the tag.
      env {
        name  = "SERVICE_VERSION"
        value = var.image_tag
      }

      # Required on every route except /health, which the platform probes call directly.
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
