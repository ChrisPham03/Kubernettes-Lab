# Kubernetes GitOps Lab

A production-style Kubernetes infrastructure project demonstrating EKS deployment, GitOps workflows, and observability—built for learning and portfolio purposes.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │                        VPC (10.0.0.0/16)                             │  │
│   │                                                                      │  │
│   │   ┌─────────────────┐              ┌─────────────────┐              │  │
│   │   │  Public Subnet  │              │  Public Subnet  │              │  │
│   │   │   10.0.0.0/24   │              │   10.0.1.0/24   │              │  │
│   │   │  ┌───────────┐  │              │                 │              │  │
│   │   │  │    NAT    │  │              │   (Future LBs)  │              │  │
│   │   │  └─────┬─────┘  │              │                 │              │  │
│   │   └────────┼────────┘              └─────────────────┘              │  │
│   │            │                                                         │  │
│   │   ┌────────┼────────┐              ┌─────────────────┐              │  │
│   │   │  Private Subnet │              │  Private Subnet │              │  │
│   │   │  10.0.10.0/24   │              │  10.0.11.0/24   │              │  │
│   │   │                 │              │                 │              │  │
│   │   │ ┌─────────────┐ │              │ ┌─────────────┐ │              │  │
│   │   │ │  EKS Node   │ │              │ │  EKS Node   │ │              │  │
│   │   │ │ (t3.medium) │ │              │ │ (t3.medium) │ │              │  │
│   │   │ │  ┌─┐ ┌─┐    │ │              │ │  ┌─┐ ┌─┐    │ │              │  │
│   │   │ │  │P│ │P│    │ │              │ │  │P│ │P│    │ │              │  │
│   │   │ │  └─┘ └─┘    │ │              │ │  └─┘ └─┘    │ │              │  │
│   │   │ └─────────────┘ │              │ └─────────────┘ │              │  │
│   │   └─────────────────┘              └─────────────────┘              │  │
│   │                                                                      │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │                   EKS Control Plane (Managed)                        │  │
│   │              API Server  │  etcd  │  Scheduler                       │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🛠️ Technologies Used

| Category | Technology | Purpose |
|----------|------------|---------|
| **Infrastructure** | Terraform | Infrastructure as Code |
| **Cloud** | AWS EKS | Managed Kubernetes |
| **Networking** | VPC, NAT Gateway | Network isolation & security |
| **GitOps** | ArgoCD | Automated deployments from Git |
| **Monitoring** | Prometheus | Metrics collection |
| **Visualization** | Grafana | Dashboards & alerting |
| **Container Runtime** | Docker | Container packaging |

## 📁 Project Structure

```
Kubernettes-Lab/
├── apps/
│   └── demo-app/
│       ├── deployment.yaml    # Kubernetes Deployment manifest
│       └── service.yaml       # Kubernetes Service manifest
│
├── eks-terraform/
│   ├── modules/
│   │   └── eks/
│   │       ├── main.tf        # VPC, IAM, EKS resources
│   │       ├── variables.tf   # Input variables
│   │       └── outputs.tf     # Output values
│   │
│   └── environments/
│       └── dev/
│           ├── main.tf        # Dev environment config
│           ├── variables.tf   # Environment variables
│           └── outputs.tf     # Environment outputs
│
├── docs/
│   ├── terraform-syntax.md    # Terraform syntax guide
│   └── kubernetes-yaml.md     # Kubernetes YAML guide
│
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- kubectl
- Helm

### Deploy Infrastructure

```bash
# Navigate to dev environment
cd eks-terraform/environments/dev

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy (takes ~15 minutes)
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name gitops-lab
```

### Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Install Monitoring Stack

```bash
# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Create namespace
kubectl create namespace monitoring

# Install Prometheus + Grafana
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin123

# Port forward to Grafana
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
```

### Clean Up (Stop Costs!)

```bash
# Delete Kubernetes LoadBalancer services first
kubectl delete svc --all

# Then destroy infrastructure
cd eks-terraform/environments/dev
terraform destroy
```

## 💰 Cost Breakdown

| Resource | Cost/Hour | Purpose |
|----------|-----------|---------|
| EKS Control Plane | $0.10 | Managed Kubernetes API |
| NAT Gateway | ~$0.045 | Outbound internet for private subnets |
| t3.medium × 2 | ~$0.083 | Worker nodes |
| **Total** | **~$0.23/hr** | **~$5.50/day** |

⚠️ **Remember to run `terraform destroy` when not using the cluster!**

## 🎯 Key Concepts Demonstrated

### Infrastructure as Code (Terraform)
- Modular design with reusable EKS module
- Environment separation (dev/staging/prod ready)
- Proper state management
- IAM roles with least privilege

### Kubernetes
- Deployments with rolling updates
- Services with AWS Load Balancer integration
- Resource limits and health probes
- Namespace isolation

### GitOps (ArgoCD)
- Declarative application deployment
- Auto-sync from Git repository
- Drift detection and correction

### Observability
- Prometheus metrics collection
- Grafana dashboards for visualization
- Node and pod-level monitoring

## 📚 Learning Resources

- [Terraform Syntax Guide](docs/terraform-syntax.md)
- [Kubernetes YAML Guide](docs/kubernetes-yaml.md)

## 🙋 Author

**Chris Pham**
- GitHub: [@ChrisPham03](https://github.com/ChrisPham03)

---

*Built as a learning project for Kubernetes, Terraform, and GitOps practices.*
