# Interview Talking Points

Use this guide to discuss your Kubernetes GitOps Lab project confidently in interviews.

---

## Project Summary (30-second pitch)

> "I built a production-style Kubernetes infrastructure on AWS using Terraform for infrastructure as code. The project includes an EKS cluster with proper networking—VPC, public and private subnets, NAT gateway—and demonstrates GitOps workflows using ArgoCD where pushing to Git automatically deploys to the cluster. I also set up observability with Prometheus and Grafana for monitoring. The whole thing can be deployed or destroyed with a single command, and I documented everything including the architecture decisions."

---

## Common Questions & Strong Answers

### "Walk me through the architecture"

> "The infrastructure is deployed on AWS using Terraform. At the network layer, I have a VPC with public and private subnets across two availability zones. The public subnets host the NAT gateway and load balancers, while the private subnets contain the EKS worker nodes—this follows AWS best practices for security since the nodes don't have public IPs.
>
> The EKS control plane is managed by AWS, which handles the API server, etcd, and scheduler. I configured two t3.medium worker nodes in a managed node group with auto-scaling capabilities.
>
> On top of Kubernetes, I installed ArgoCD for GitOps—so deployments happen automatically when I push to Git—and Prometheus plus Grafana for monitoring and dashboards."

### "Why did you put nodes in private subnets?"

> "Security. Nodes in private subnets don't have public IP addresses, so they can't be directly accessed from the internet. They reach the internet through the NAT gateway only for outbound traffic like pulling container images. This reduces the attack surface significantly."

### "Explain how GitOps works in your project"

> "GitOps means Git is the single source of truth for what should be running in the cluster. ArgoCD watches my GitHub repository, and when I push a change—like updating the replica count or image version—ArgoCD detects the difference between Git and the cluster state, then automatically syncs the cluster to match Git.
>
> This is better than running kubectl commands manually because everything is versioned, auditable, and I can roll back just by reverting a Git commit."

### "How does a Kubernetes Service find its pods?"

> "Through labels and selectors. When I create a Deployment, the pod template includes labels like `app: my-app`. The Service has a selector with the same label. Kubernetes continuously watches for pods matching that selector and automatically updates the endpoints. If I scale up, new pods are automatically added to the Service. If a pod dies, it's removed."

### "What happens during a rolling update?"

> "When I change the image version, Kubernetes creates new pods with the new image while keeping old pods running. By default, it ensures at least 75% of desired pods are available at all times. Once a new pod passes its readiness probe, traffic shifts to it, and an old pod terminates. This continues until all pods are updated—zero downtime."

### "Why Terraform instead of CloudFormation?"

> "A few reasons: Terraform is cloud-agnostic, so the skills transfer if I work with GCP or Azure. The syntax is more readable—HCL versus JSON/YAML. The plan command gives a clear preview before any changes. And the module system makes it easy to create reusable components, which I did with my EKS module."

### "Explain the IAM roles you created"

> "I created two separate roles following least-privilege principles. The cluster role is assumed by the EKS service itself—it has permissions to manage networking for the control plane. The node role is assumed by EC2 instances—the worker nodes—and has permissions to join the cluster, manage pod networking through the CNI plugin, and pull images from ECR. Separating them means if a node is compromised, it can't modify the cluster control plane."

### "How would you handle secrets in production?"

> "Kubernetes Secrets are base64 encoded, not encrypted at rest by default. For production, I'd either enable EKS envelope encryption with KMS, or use AWS Secrets Manager with the External Secrets Operator to sync secrets into Kubernetes. I'd also use RBAC to restrict which services can access which secrets."

### "What would you add for production readiness?"

> "Several things:
> - **Remote state** for Terraform in S3 with DynamoDB locking
> - **Ingress controller** instead of LoadBalancer per service
> - **HTTPS** with cert-manager for TLS certificates
> - **Pod disruption budgets** to ensure availability during node maintenance
> - **Network policies** to restrict pod-to-pod traffic
> - **RBAC** for access control
> - **Alerting** rules in Prometheus, not just dashboards"

---

## Technical Depth Questions

### "What's the difference between a Deployment and a StatefulSet?"

> "Deployments are for stateless applications—pods are interchangeable, can be created in any order, and don't need stable network identities. StatefulSets are for stateful applications like databases—each pod gets a stable hostname, persistent storage that follows it, and they're created and terminated in order."

### "How does the VPC CNI plugin work?"

> "The AWS VPC CNI gives each pod a real IP address from the VPC subnet—not an overlay network. This means pods can communicate with other AWS services directly, and security groups work at the pod level. The downside is you can run out of IP addresses if you have many pods, since each takes a VPC IP."

### "What's the difference between readiness and liveness probes?"

> "Readiness probes determine if a pod should receive traffic. If it fails, the pod is removed from Service endpoints but keeps running. Liveness probes determine if a pod is alive. If it fails, Kubernetes restarts the pod. A common pattern is: liveness checks if the process is running, readiness checks if it's ready to serve requests."

---

## Behavioral Questions

### "What was the most challenging part?"

> "Understanding how all the pieces connect—Terraform creating the infrastructure, kubectl configuring it, ArgoCD automating deployments, and how traffic flows through load balancers to services to pods. Drawing architecture diagrams and mapping Kubernetes concepts to AWS services I already knew helped a lot."

### "What did you learn?"

> "Infrastructure as code changes how you think about resources—they're not pets you SSH into, they're cattle you define in code and recreate whenever needed. I also learned that Kubernetes has great primitives for reliability—health checks, rolling updates, auto-scaling—but you have to explicitly configure them."

### "How would you troubleshoot a pod that won't start?"

> "First, `kubectl describe pod` to see events—usually tells you the issue. Common problems: image pull errors (wrong image name or registry auth), resource limits (not enough CPU/memory on nodes), readiness probe failures, or missing ConfigMaps/Secrets. I'd check `kubectl logs` if the container started but crashed."

---

## Questions to Ask Them

- "What does your Kubernetes deployment pipeline look like?"
- "Do you use GitOps? If so, what tool?"
- "How do you handle secrets management in your clusters?"
- "What's your monitoring stack?"
- "How many clusters do you manage, and how do you handle multi-cluster?"
