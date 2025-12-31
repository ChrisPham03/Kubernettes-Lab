# Terraform Syntax Guide

A practical guide to understanding and writing Terraform configurations.

## Table of Contents
- [Resource Syntax](#resource-syntax)
- [How Resources Reference Each Other](#how-resources-reference-each-other)
- [Variables](#variables)
- [Outputs](#outputs)
- [Key Syntax Patterns](#key-syntax-patterns)
- [How to Approach Writing Terraform](#how-to-approach-writing-terraform)

---

## Resource Syntax

Every Terraform resource follows this pattern:

```hcl
resource "PROVIDER_TYPE" "LOCAL_NAME" {
  argument1 = "value1"
  argument2 = "value2"
  
  nested_block {
    nested_argument = "value"
  }
}
```

### Real Example: VPC

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}
```

| Part | What It Is | Example |
|------|-----------|---------|
| `resource` | Keyword saying "create this thing" | Always `resource` |
| `"aws_vpc"` | **Resource type** = provider + underscore + AWS service | `aws_` = AWS provider, `vpc` = the service |
| `"main"` | **Local name** = your nickname for this resource | Could be anything: `"main"`, `"primary"`, `"my_vpc"` |
| `cidr_block` | **Argument** = configuration setting | Value comes from a variable |
| `tags` | **Nested block** = a group of related settings | Map of key-value pairs |

---

## How Resources Reference Each Other

This is where Terraform becomes powerful. Resources can reference attributes from other resources.

### The Reference Pattern

```
RESOURCE_TYPE.LOCAL_NAME.ATTRIBUTE
```

### Example: Internet Gateway Referencing VPC

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id      # ← References the VPC's ID
}
```

Breaking down `aws_vpc.main.id`:
- `aws_vpc` = resource type
- `main` = the local name we gave it
- `id` = attribute that exists after the resource is created

### Automatic Dependency Chain

Terraform automatically:
1. Understands the IGW depends on the VPC
2. Creates the VPC first
3. Waits for the VPC ID
4. Then creates the IGW

**Without Terraform (manual AWS CLI):**
```bash
# Step 1: Create VPC, get the ID back
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)

# Step 2: Use that ID to create IGW
aws ec2 create-internet-gateway --vpc-id $VPC_ID
```

Terraform handles this dependency chain automatically!

---

## Variables

Variables are inputs to your Terraform configuration—like function parameters.

### Defining Variables (variables.tf)

```hcl
variable "cluster_name" {
  description = "Name for the EKS cluster"
  type        = string
  default     = "my-cluster"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "enable_logging" {
  description = "Enable CloudWatch logging"
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "List of AZs to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}
```

### Using Variables

```hcl
resource "aws_eks_cluster" "main" {
  name = var.cluster_name      # ← Reference with var.NAME
}
```

### Providing Variable Values

**Option 1: terraform.tfvars file (auto-loaded)**
```hcl
cluster_name = "production-cluster"
node_count   = 5
```

**Option 2: Command line**
```bash
terraform apply -var="cluster_name=production-cluster"
```

**Option 3: Environment variables**
```bash
export TF_VAR_cluster_name="production-cluster"
terraform apply
```

---

## Outputs

Outputs are return values—information you need after resources are created.

### Defining Outputs (outputs.tf)

```hcl
output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${aws_eks_cluster.main.name}"
}
```

### Viewing Outputs

```bash
# After apply
terraform output

# Specific output
terraform output cluster_endpoint
```

---

## Key Syntax Patterns

### 1. String Interpolation

Embed expressions inside strings:

```hcl
Name = "${var.cluster_name}-vpc"    # Results in "gitops-lab-vpc"
```

### 2. Count (Create Multiple Resources)

```hcl
resource "aws_subnet" "public" {
  count      = 2                                              # Create 2 subnets
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)      # Different CIDR each
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
```

### 3. Splat Expression (Reference All Counted Resources)

```hcl
subnet_ids = aws_subnet.public[*].id    # Gets IDs of ALL public subnets
# Equivalent to: [aws_subnet.public[0].id, aws_subnet.public[1].id]
```

### 4. Specific Index

```hcl
subnet_id = aws_subnet.public[0].id     # First subnet only
```

### 5. Conditional Expression

```hcl
instance_type = var.environment == "prod" ? "t3.large" : "t3.medium"
```

### 6. depends_on (Explicit Dependency)

Usually Terraform figures out dependencies automatically. Use `depends_on` for hidden dependencies:

```hcl
resource "aws_eks_cluster" "main" {
  # ... config ...
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}
```

### 7. for_each (Create Resources from Map/Set)

```hcl
variable "subnets" {
  default = {
    "public-1"  = "10.0.1.0/24"
    "public-2"  = "10.0.2.0/24"
  }
}

resource "aws_subnet" "public" {
  for_each   = var.subnets
  cidr_block = each.value
  
  tags = {
    Name = each.key
  }
}
```

---

## How to Approach Writing Terraform

### Step 1: Identify Required AWS Resources

Think through the architecture:

```
EKS Cluster needs:
├── VPC
│   ├── Subnets (public + private)
│   ├── Internet Gateway
│   ├── NAT Gateway
│   └── Route Tables
├── IAM Roles
│   ├── Cluster role
│   └── Node role
└── EKS Resources
    ├── Cluster
    └── Node Group
```

### Step 2: Find the Resource Type

Go to [Terraform AWS Provider docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).

Search for the service (e.g., "eks cluster") and find:
- Resource name: `aws_eks_cluster`
- Required arguments
- Optional arguments
- Attributes (outputs)

### Step 3: Write Required Arguments First

```hcl
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name           # Required
  role_arn = aws_iam_role.cluster.arn   # Required
  
  vpc_config {                          # Required block
    subnet_ids = aws_subnet.private[*].id
  }
}
```

### Step 4: Add Optional Arguments

```hcl
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = "1.29"                     # Optional - pin K8s version
  role_arn = aws_iam_role.cluster.arn
  
  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_public_access  = true      # Optional
    endpoint_private_access = true      # Optional
  }
}
```

### Step 5: Connect Resources

Build the dependency chain by referencing other resources:

```hcl
# IAM role created first
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"
  # ...
}

# Cluster references the role
resource "aws_eks_cluster" "main" {
  role_arn = aws_iam_role.cluster.arn    # ← Creates dependency
  # ...
}
```

---

## Quick Reference

| Pattern | Example | Meaning |
|---------|---------|---------|
| `var.NAME` | `var.cluster_name` | Reference a variable |
| `TYPE.NAME.ATTR` | `aws_vpc.main.id` | Reference another resource |
| `"${...}"` | `"${var.name}-suffix"` | String interpolation |
| `[*]` | `aws_subnet.public[*].id` | All instances (splat) |
| `[0]` | `aws_subnet.public[0].id` | First instance |
| `count.index` | Inside counted resource | Current iteration (0, 1, 2...) |
| `each.key` | Inside for_each resource | Current map key |
| `each.value` | Inside for_each resource | Current map value |

---

## Common Commands

```bash
terraform init      # Download providers, initialize backend
terraform plan      # Preview changes (dry run)
terraform apply     # Execute changes
terraform destroy   # Delete all resources
terraform fmt       # Format code
terraform validate  # Check syntax
terraform output    # Show output values
terraform state list # List managed resources
```
