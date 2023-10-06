resource "dynatrace_k8s_workload_anomalies" "example_name" {
  scope = var.scope
  
  container_restarts {
    enabled = var.container_restarts.enabled
    configuration {
      observation_period_in_minutes = var.container_restarts.observation_period_in_minutes
      sample_period_in_minutes      = var.container_restarts.sample_period_in_minutes
      threshold                     = var.container_restarts.threshold
    }
  }
  
  deployment_stuck {
    enabled = var.deployment_stuck.enabled
    configuration {
      observation_period_in_minutes = var.deployment_stuck.observation_period_in_minutes
      sample_period_in_minutes      = var.deployment_stuck.sample_period_in_minutes
    }
  }

  //... similarly, reference other variables for each monitor ...
}
