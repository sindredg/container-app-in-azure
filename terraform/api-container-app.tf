resource "azurerm_container_app" "api" {
  name                         = "ca-${local.project_name}-api-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  max_inactive_revisions = 5

  identity {
    type = "UserAssigned"

    identity_ids = [
      azurerm_user_assigned_identity.container_pull.id
    ]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.container_pull.id
  }

  secret {
    name  = "api-shared-secret"
    value = random_password.api_shared_secret.result
  }

  # Internal ingress. The FQDN carries an .internal. segment and resolves only
  # inside the environment, so the web container is the only route to this app.
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
      image  = "${azurerm_container_registry.main.login_server}/api:${var.api_image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      # Reported by /status, so the running version cannot drift from the tag.
      env {
        name  = "SERVICE_VERSION"
        value = var.api_image_tag
      }

      # Every route except /health rejects a request without this value.
      # /health stays open because the platform probes call it directly.
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

  depends_on = [
    azurerm_role_assignment.container_pull
  ]

  tags = merge(local.common_tags, { component = "api" })
}