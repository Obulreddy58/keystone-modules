output "classification_job_id" {
  description = "Macie classification job ID"
  value       = aws_macie2_classification_job.this.id
}

output "classification_job_arn" {
  description = "Macie classification job ARN"
  value       = aws_macie2_classification_job.this.id
}

output "sns_topic_arn" {
  description = "SNS topic ARN for findings notifications"
  value       = aws_sns_topic.classification_findings.arn
}

output "sensitivity_level" {
  description = "Applied sensitivity level"
  value       = var.sensitivity_level
}

output "scheduled_frequency" {
  description = "Classification schedule frequency"
  value       = var.schedule_frequency
}
