# Keystone Modules

Production-ready Terraform modules for AWS infrastructure provisioning. Used by the [Keystone Platform](https://github.com/Obulreddy58/keystone-platform) for self-service infrastructure delivery.

## Modules (29)

### Compute
| Module | Description |
|--------|-------------|
| `eks/` | EKS cluster with managed node groups, Karpenter, private endpoint |
| `eks-addons/` | EKS addons — VPC-CNI, CoreDNS, kube-proxy, Karpenter, ALB controller |
| `ecs-fargate/` | ECS Fargate service with ALB, auto-scaling, service discovery |
| `lambda/` | Lambda function with API Gateway, VPC, event source triggers |
| `ec2/` | EC2 instances with ASG, launch templates, SSM access |

### Data & Storage
| Module | Description |
|--------|-------------|
| `rds/` | RDS PostgreSQL/MySQL with Multi-AZ, encryption, automated backups |
| `documentdb/` | DocumentDB (MongoDB-compatible) cluster with encryption |
| `dynamodb/` | DynamoDB with auto-scaling, GSI/LSI, point-in-time recovery |
| `s3/` | S3 bucket with encryption, versioning, lifecycle, access logging |
| `elasticache/` | ElastiCache Redis with cluster mode, encryption, multi-AZ |
| `msk/` | MSK (Kafka) cluster with encryption, monitoring, auto-scaling |
| `iceberg/` | Apache Iceberg table on Glue Data Catalog with S3 storage |
| `vector-store/` | pgvector (RDS) or OpenSearch Serverless for vector embeddings |
| `efs/` | EFS file system with encryption and mount targets |

### Data Governance
| Module | Description |
|--------|-------------|
| `lake-formation/` | AWS Lake Formation with LF-tags and S3 location registration |
| `data-access/` | IAM roles for least-privilege data access (7 resource types) |
| `data-classification/` | Macie-based PII/sensitive data classification |
| `cross-account-share/` | RAM + KMS grants for cross-account data sharing |

### Networking
| Module | Description |
|--------|-------------|
| `vpc/` | VPC with public/private subnets, NAT Gateway, flow logs |
| `alb/` | Application Load Balancer with HTTPS, WAF integration |
| `route53/` | Route53 hosted zones with health checks and failover |
| `transit-gateway/` | Transit Gateway for multi-VPC connectivity |
| `cloudfront/` | CloudFront CDN with S3/ALB origins, ACM certificate |

### Security & Identity
| Module | Description |
|--------|-------------|
| `waf/` | AWS WAF v2 with managed rule groups |
| `oidc-github/` | GitHub OIDC provider for keyless AWS authentication |

### Account Management
| Module | Description |
|--------|-------------|
| `account-factory/` | AWS account vending with Organizations, SSO, OIDC |
| `account-baseline/` | Account baseline — GuardDuty, Config, CloudTrail, SCPs |

### Other
| Module | Description |
|--------|-------------|
| `ecr/` | ECR repositories with lifecycle policies and cross-region replication |
| `api-gateway/` | API Gateway REST/HTTP with Lambda integration |

## Usage

Reference modules from Terragrunt:

```hcl
terraform {
  source = "git::https://github.com/Obulreddy58/keystone-modules.git//rds?ref=v1.0.0"
}

inputs = {
  instance_name  = "payments-db"
  engine         = "postgres"
  engine_version = "16.4"
  instance_class = "db.r6g.large"
  environment    = "prod"
}
```

## Design Principles

1. **Encrypt everything** — KMS with key rotation enabled
2. **Least-privilege IAM** — Scoped to specific resources, partition-aware ARNs
3. **No public access** — Security groups default-deny, S3 public access blocked
4. **Tag everything** — Environment, ManagedBy, Service tags on all resources
5. **Conditional logic** — Prod-only features (Multi-AZ, enhanced monitoring) via environment flag

## Related Repos

| Repo | Description |
|------|-------------|
| [keystone-platform](https://github.com/Obulreddy58/keystone-platform) | Self-service API + UI |
| [keystone-infra-live](https://github.com/Obulreddy58/keystone-infra-live) | Live Terragrunt configurations |
| [keystone-workflows](https://github.com/Obulreddy58/keystone-workflows) | CI/CD pipelines for Terraform |
