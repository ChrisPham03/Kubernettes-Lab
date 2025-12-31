# =============================================================================
# Outputs for Dev Environment
# =============================================================================

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Run this command to configure kubectl"
  value       = module.eks.configure_kubectl
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.eks.vpc_id
}

# Helpful reminder about costs
output "cost_reminder" {
  description = "Don't forget!"
  value       = "⚠️  This cluster costs ~$0.25/hour. Run 'terraform destroy' when done!"
}
