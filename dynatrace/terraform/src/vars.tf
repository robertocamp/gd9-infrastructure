variable "scope" {
  description = "The scope of the k8s workload anomalies"
  default     = "environment"
}

variable "observation_period_in_minutes" {
  description = "The observation period in minutes for anomalies"
  default     = 6
}

variable "sample_period_in_minutes" {
  description = "The sample period in minutes for anomalies"
  default     = 4
}

variable "threshold" {
  description = "The threshold for anomalies"
  default     = 2
}

// Define other variables as needed
