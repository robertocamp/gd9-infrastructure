variable "scope" {
  description = "The scope of the k8s workload anomalies"
  default     = "environment"
}

variable "container_restarts" {
  type = object({
    enabled                      = bool
    observation_period_in_minutes = number
    sample_period_in_minutes      = number
    threshold                     = number
  })
  default = {
    enabled                      = true
    observation_period_in_minutes = 6
    sample_period_in_minutes      = 4
    threshold                     = 2
  }
}

variable "deployment_stuck" {
  type = object({
    enabled                      = bool
    observation_period_in_minutes = number
    sample_period_in_minutes      = number
  })
  default = {
    enabled                      = true
    observation_period_in_minutes = 5
    sample_period_in_minutes      = 4
  }
}

//... similarly, define other variables with default values for each monitor ...
