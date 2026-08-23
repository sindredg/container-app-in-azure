locals {
  # Only the values that produce a new revision when they change.
  web_config_hash = substr(sha1(jsonencode({
    image      = var.web_image_tag
    max        = var.web_max_replicas
    concurrent = var.web_concurrent_requests
    upstream   = azurerm_container_app.api.ingress[0].fqdn
  })), 0, 6)
}

resource "azurerm_container_app" "web" {
  name                         = "ca-${local.project_name}-web-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Multiple"

  # Rollback needs the previous revision to still exist.
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

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = 8080
    transport                  = "auto"

    # Normal state is one block sending everything to the newest revision.
    # Setting web_previous_revision_suffix adds a second block, which is how a
    # split, a promotion, and a rollback are all expressed as one variable change.
    dynamic "traffic_weight" {
      for_each = var.web_previous_revision_suffix == "" ? [] : [1]

      content {
        revision_suffix = var.web_previous_revision_suffix
        percentage      = 100 - var.web_latest_traffic_percentage
      }
    }

    traffic_weight {
      latest_revision = true
      percentage      = var.web_latest_traffic_percentage
    }
  }

  template {
    # Azure generates a random suffix unless given one. Deriving it from the
    # image tag means a revision name says which release it is running.
    # Dots are not valid in a revision name, so 0.3.0 becomes 0-3-0.
    #
    # The tag alone is not enough. A config change that does not touch the
    # image reuses the tag, and Azure cannot create a second revision with a
    # name that already exists, so it silently falls back to auto numbering.
    # Appending a hash of the settings that define a revision keeps the name
    # unique per configuration while the version stays readable.
    revision_suffix = "${replace(var.web_image_tag, ".", "-")}-${local.web_config_hash}"

    min_replicas = 0
    max_replicas = var.web_max_replicas

    http_scale_rule {
      name = "http-requests"

      # Azure adds a replica when average concurrent requests per replica
      # exceeds this. Lower it to make scaling visible in a short test.
      concurrent_requests = var.web_concurrent_requests
    }

    container {
      name   = "web"
      image  = "${azurerm_container_registry.main.login_server}/web:${var.web_image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "API_UPSTREAM"
        value = "https://${azurerm_container_app.api.ingress[0].fqdn}"
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

  depends_on = [
    azurerm_role_assignment.container_pull
  ]

  tags = merge(local.common_tags, { component = "web" })
}