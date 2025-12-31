# EKS GitOps Lab - Terraform

## Project Structure

```
eks-terraform/
├── modules/
│   └── eks/                    # Reusable EKS module
│       ├── main.tf             # All AWS resources (VPC, EKS, IAM)
│       ├── variables.tf        # Input parameters
│       └── outputs.tf          # Return values
│
└── environments/
    └── dev/                    # Dev environment config
        ├── main.tf             # Calls the module
        ├── variables.tf        # Environment-specific vars
        └── outputs.tf          # What to display after apply
```

## What Gets Created

| Resource | Purpose | Cost |
|----------|---------|------|
| VPC | Network isolation | Free |
| 2 Public Subnets | For load balancers | Free |
| 2 Private Subnets | For worker nodes | Free |
| NAT Gateway | Outbound internet for private subnets | ~$0.045/hr |
| EKS Control Plane | Managed Kubernetes API | $0.10/hr |
| 2x t3.medium nodes | Where your pods run | ~$0.08/hr |

**Total: ~$0.22-0.25/hour (~$5-6/day if left running)**

## Quick Start

```bash
cd environments/dev

# Initialize Terraform (downloads providers)
terraform init

# Preview what will be created
terraform plan

# Create everything (takes 10-15 minutes)
terraform apply

# Configure kubectl to talk to your cluster
aws eks update-kubeconfig --region us-east-1 --name gitops-lab

# Verify connection
kubectl get nodes

# IMPORTANT: Destroy when done to stop costs!
terraform destroy
```

## AWS Concepts → Kubernetes Mapping

If you know AWS, here's how to think about what we're creating:

- **EKS Control Plane** = Like RDS manages your database, EKS manages K8s masters
- **Node Group** = Auto Scaling Group of EC2 instances that auto-join the cluster
- **Private Subnets** = Where worker nodes live (secure, no public IPs)
- **Public Subnets** = Where load balancers get created
- **NAT Gateway** = Lets private nodes pull container images from internet
