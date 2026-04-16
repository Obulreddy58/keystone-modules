variable "name" {
  description = "Name prefix for MSK resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for broker placement (one per AZ, min 2)"
  type        = list(string)
}

variable "kafka_version" {
  description = "Apache Kafka version"
  type        = string
  default     = "3.6.0"
}

variable "number_of_broker_nodes" {
  description = "Number of broker nodes (must be multiple of AZ count)"
  type        = number
  default     = 3
}

variable "broker_instance_type" {
  description = "Instance type for Kafka brokers"
  type        = string
  default     = "kafka.m5.large"
}

variable "broker_ebs_volume_size" {
  description = "EBS volume size per broker in GB"
  type        = number
  default     = 100
}

variable "broker_ebs_throughput" {
  description = "Provisioned throughput in MiB/s (250-2375, only for kafka.m5.4xlarge+)"
  type        = number
  default     = 250
}

variable "auto_scaling_max_storage" {
  description = "Max storage per broker in GB for auto scaling (0 = disabled)"
  type        = number
  default     = 1000
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to the brokers"
  type        = list(string)
  default     = []
}

variable "client_authentication" {
  description = "Client authentication type: iam, tls, or sasl_scram"
  type        = string
  default     = "iam"
}

variable "encryption_in_transit" {
  description = "Encryption in transit: TLS, TLS_PLAINTEXT, or PLAINTEXT"
  type        = string
  default     = "TLS"
}

variable "enhanced_monitoring" {
  description = "Enhanced monitoring level: DEFAULT, PER_BROKER, PER_TOPIC_PER_BROKER, PER_TOPIC_PER_PARTITION"
  type        = string
  default     = "PER_TOPIC_PER_BROKER"
}

variable "cloudwatch_logs_enabled" {
  description = "Enable CloudWatch logging for broker logs"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

variable "configuration_server_properties" {
  description = "Custom server.properties for the MSK configuration"
  type        = string
  default     = <<-EOT
    auto.create.topics.enable=false
    default.replication.factor=3
    min.insync.replicas=2
    num.partitions=6
    log.retention.hours=168
    log.retention.bytes=-1
  EOT
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
