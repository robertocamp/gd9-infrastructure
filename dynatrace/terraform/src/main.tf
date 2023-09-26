resource "dynatrace_k8s_workload_anomalies" "dyna-trial" {
  scope = "environment"
  container_restarts {
    enabled = true
    configuration {
      observation_period_in_minutes = var.observation_period_in_minutes
      sample_period_in_minutes      = var.sample_period_in_minutes
      threshold                     = var.threshold
    }
  }
  deployment_stuck {
    enabled = true
    configuration {
      observation_period_in_minutes = 5
      sample_period_in_minutes      = 4
    }
  }
  not_all_pods_ready {
    enabled = true
    configuration {
      observation_period_in_minutes = 6
      sample_period_in_minutes      = 4
    }
  }
  pending_pods {
    enabled = true
    configuration {
      observation_period_in_minutes = 16
      sample_period_in_minutes      = 11
      threshold                     = 2
    }
  }
  pod_stuck_in_terminating {
    enabled = true
    configuration {
      observation_period_in_minutes = 6
      sample_period_in_minutes      = 4
    }
  }
  workload_without_ready_pods {
    enabled = true
    configuration {
      observation_period_in_minutes = 6
      sample_period_in_minutes      = 4
    }
  }
  high_cpu_throttling {
    enabled = true
    configuration {
      observation_period_in_minutes = 6
      sample_period_in_minutes      = 4
      threshold                     = 2
    }
  }
  high_cpu_usage {
    enabled = true
    configuration {
      observation_period_in_minutes = 6
      sample_period_in_minutes      = 4
      threshold                     = 2
    }
  }
  high_memory_usage {
    enabled = true
    configuration {
      observation_period_in_minutes = 6
      sample_period_in_minutes      = 4
      threshold                     = 2
    }
  }
  job_failure_events {
    enabled = true
  }
  oom_kills {
    enabled = true
  }
  pod_backoff_events {
    enabled = true
  }
  pod_eviction_events {
    enabled = true
  }
  pod_preemption_events {
    enabled = true
  }
}