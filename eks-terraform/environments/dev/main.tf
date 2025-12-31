# =============================================================================
# Development Environment - EKS Cluster
# =============================================================================
# This is your "dev" environment configuration
# It calls the EKS module with settings optimized for learning (low cost)
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # For production, you'd use an S3 backend for state
  # For learning, local state is fine
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "eks/dev/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# Configure AWS provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "k8s-gitops-lab"
      ManagedBy   = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Call the EKS Module
# -----------------------------------------------------------------------------

module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = "1.29"

  # Cost optimization for learning:
  # - t3.medium: ~$0.0416/hour each
  # - 2 nodes = ~$0.08/hour for compute
  # - Plus EKS control plane: $0.10/hour
  # - Plus NAT Gateway: ~$0.045/hour
  # Total: ~$0.22-0.25/hour
  node_instance_types = ["t3.medium"]
  node_desired_count  = 2
  node_min_count      = 1
  node_max_count      = 3
}
