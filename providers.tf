terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Backend values are injected via -backend-config flags in CI/CD.
  # Run: terraform init \
  #   -backend-config="bucket=<your-state-bucket>" \
  #   -backend-config="key=3-tier-app/terraform.tfstate" \
  #   -backend-config="region=us-east-1" \
  #   -backend-config="encrypt=true" \
  #   -backend-config="dynamodb_table=<your-lock-table>"
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
