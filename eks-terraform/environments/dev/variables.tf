# =============================================================================
# Variables for Dev Environment
# =============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name for the EKS cluster"
  type        = string
  default     = "gitops-lab"  # Your cluster name for the portfolio project
}
