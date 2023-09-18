output "prometheus_role_arn" {
  description = "The ARN of the Prometheus IAM role"
  value       = aws_iam_role.prometheus.arn
}
