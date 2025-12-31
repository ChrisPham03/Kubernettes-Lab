# Kubernetes YAML Guide

A practical guide to writing Kubernetes manifests from scratch.

## Table of Contents
- [YAML Structure Basics](#yaml-structure-basics)
- [The Four Required Fields](#the-four-required-fields)
- [How to Find the Right apiVersion](#how-to-find-the-right-apiversion)
- [Deployment Manifest](#deployment-manifest)
- [Service Manifest](#service-manifest)
- [ConfigMap and Secrets](#configmap-and-secrets)
- [How to Approach Writing Manifests](#how-to-approach-writing-manifests)
- [Using kubectl explain](#using-kubectl-explain)

---

## YAML Structure Basics

YAML uses indentation (2 spaces) to show hierarchy:

```yaml
parent:
  child: value
  another_child:
    grandchild: value
```

**Key rules:**
- Use spaces, not tabs
- 2 spaces per indentation level
- Colons need a space after them: `key: value`
- Lists use dashes: `- item`

---

## The Four Required Fields

Every Kubernetes manifest has these four top-level fields:

```yaml
apiVersion: <API_VERSION>    # Which API to use
kind: <RESOURCE_TYPE>        # What you're creating
metadata:                    # Info about the resource
  name: <NAME>
spec:                        # The desired state
  # ... resource-specific configuration
```

### Example: A Simple Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.27
```

---

## How to Find the Right apiVersion

Different resources use different API versions. Here's how to find them:

### Method 1: kubectl explain

```bash
kubectl explain deployment
# Shows: VERSION:  apps/v1

kubectl explain service
# Shows: VERSION:  v1

kubectl explain pod
# Shows: VERSION:  v1
```

### Method 2: Common API Versions Cheat Sheet

| Resource | apiVersion |
|----------|------------|
| Pod | `v1` |
| Service | `v1` |
| ConfigMap | `v1` |
| Secret | `v1` |
| Deployment | `apps/v1` |
| ReplicaSet | `apps/v1` |
| StatefulSet | `apps/v1` |
| DaemonSet | `apps/v1` |
| Ingress | `networking.k8s.io/v1` |
| PersistentVolumeClaim | `v1` |
| HorizontalPodAutoscaler | `autoscaling/v2` |

### Method 3: kubectl api-resources

```bash
kubectl api-resources | grep -i deployment
# Shows: deployments    deploy    apps/v1    true    Deployment
```

---

## Deployment Manifest

A Deployment manages a set of identical pods.

### Full Example with Comments

```yaml
apiVersion: apps/v1          # API version for Deployments
kind: Deployment             # Resource type
metadata:
  name: my-app               # Name of this deployment
  labels:                    # Labels for the deployment itself
    app: my-app
spec:
  replicas: 3                # Number of pod copies
  
  # Selector - how the Deployment finds its pods
  selector:
    matchLabels:
      app: my-app            # Must match template.metadata.labels
  
  # Strategy - how updates happen
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1            # Can have 1 extra pod during update
      maxUnavailable: 0      # Always keep all pods running
  
  # Pod template - what each pod looks like
  template:
    metadata:
      labels:
        app: my-app          # Pods get this label (matches selector)
    spec:
      containers:
      - name: my-app
        image: nginx:1.27
        
        ports:
        - containerPort: 80
        
        # Resource management
        resources:
          requests:          # Minimum guaranteed
            memory: "64Mi"
            cpu: "100m"      # 100 millicores = 0.1 CPU
          limits:            # Maximum allowed
            memory: "128Mi"
            cpu: "200m"
        
        # Health checks
        readinessProbe:      # Ready to receive traffic?
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        
        livenessProbe:       # Still alive?
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        
        # Environment variables
        env:
        - name: ENV
          value: "production"
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: my-config
              key: database_host
```

### Minimal Deployment

The bare minimum that works:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx:1.27
```

---

## Service Manifest

A Service provides a stable endpoint to access pods.

### Service Types

| Type | Use Case |
|------|----------|
| `ClusterIP` | Internal only (default) |
| `NodePort` | Expose on each node's IP |
| `LoadBalancer` | External load balancer (AWS ELB) |

### Full Example

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  type: LoadBalancer         # Creates AWS ELB
  
  # Selector - finds pods with these labels
  selector:
    app: my-app              # Matches pods from Deployment
  
  ports:
  - protocol: TCP
    port: 80                 # Service port (what users hit)
    targetPort: 8080         # Container port (where app listens)
```

### How Service Connects to Pods

```
┌─────────────────────────────────────────────────┐
│ Deployment                                      │
│   template.metadata.labels:                     │
│     app: my-app  ◄────────────────┐            │
└─────────────────────────────────────┼───────────┘
                                      │ matches
┌─────────────────────────────────────┼───────────┐
│ Service                             │           │
│   selector:                         │           │
│     app: my-app  ───────────────────┘           │
└─────────────────────────────────────────────────┘
```

---

## ConfigMap and Secrets

### ConfigMap (non-sensitive config)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  database_host: "db.example.com"
  log_level: "info"
  config.json: |
    {
      "feature_flags": {
        "new_ui": true
      }
    }
```

### Secret (sensitive data)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  # Values must be base64 encoded
  password: cGFzc3dvcmQxMjM=      # echo -n "password123" | base64
  api_key: c2VjcmV0a2V5MTIz
```

### Using in Deployment

```yaml
spec:
  containers:
  - name: my-app
    image: nginx
    
    # Single value from ConfigMap
    env:
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: my-config
          key: database_host
    
    # Single value from Secret
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: my-secret
          key: password
    
    # Mount entire ConfigMap as files
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  
  volumes:
  - name: config-volume
    configMap:
      name: my-config
```

---

## How to Approach Writing Manifests

### Step 1: Start with the Four Required Fields

```yaml
apiVersion: 
kind: 
metadata:
  name: 
spec:
```

### Step 2: Determine apiVersion and kind

```bash
# What resource do I need?
kubectl explain deployment   # Shows apiVersion: apps/v1
```

### Step 3: Fill in metadata

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
```

### Step 4: Use kubectl explain to Find Spec Fields

```bash
# What goes in spec?
kubectl explain deployment.spec

# Go deeper
kubectl explain deployment.spec.template.spec.containers
```

### Step 5: Build Up Incrementally

Start minimal, add features one at a time:

```yaml
# Version 1: Minimal
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx
```

```yaml
# Version 2: Add resources
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
```

```yaml
# Version 3: Add health checks
        readinessProbe:
          httpGet:
            path: /
            port: 80
```

---

## Using kubectl explain

Your best friend for writing manifests!

### Basic Usage

```bash
# Top level
kubectl explain pod
kubectl explain deployment
kubectl explain service

# Nested fields (use dots)
kubectl explain deployment.spec
kubectl explain deployment.spec.replicas
kubectl explain deployment.spec.template.spec.containers

# Show all fields recursively
kubectl explain deployment --recursive

# Show specific nested path with details
kubectl explain pod.spec.containers.resources
```

### Example Session

```bash
$ kubectl explain deployment.spec.strategy
KIND:     Deployment
VERSION:  apps/v1

FIELD:    strategy <Object>

DESCRIPTION:
     The deployment strategy to use to replace existing pods with new ones.

$ kubectl explain deployment.spec.strategy.rollingUpdate
KIND:     Deployment
VERSION:  apps/v1

FIELD:    rollingUpdate <Object>

DESCRIPTION:
     Rolling update config params. Present only if DeploymentStrategyType =
     RollingUpdate.

FIELDS:
   maxSurge	<IntOrString>
     The maximum number of pods that can be scheduled above the desired number...

   maxUnavailable	<IntOrString>
     The maximum number of pods that can be unavailable during the update...
```

---

## Quick Reference

### Common Fields Cheat Sheet

```yaml
# Deployment
spec:
  replicas: 3
  selector:
    matchLabels: {}
  strategy:
    type: RollingUpdate
  template:
    metadata:
      labels: {}
    spec:
      containers: []

# Container
- name: my-app
  image: nginx:1.27
  ports:
  - containerPort: 80
  env: []
  resources:
    requests: {}
    limits: {}
  readinessProbe: {}
  livenessProbe: {}
  volumeMounts: []

# Service
spec:
  type: LoadBalancer
  selector: {}
  ports:
  - port: 80
    targetPort: 8080
```

### Common Commands

```bash
# Apply manifest
kubectl apply -f deployment.yaml

# Dry run (validate without creating)
kubectl apply -f deployment.yaml --dry-run=client

# Generate YAML from running resource
kubectl get deployment my-app -o yaml > deployment.yaml

# Create basic YAML template
kubectl create deployment my-app --image=nginx --dry-run=client -o yaml > deployment.yaml
```

---

## Labels and Selectors Pattern

The most important concept—how resources find each other:

```yaml
# Deployment creates pods with labels
template:
  metadata:
    labels:
      app: my-app        # ← Pods get this label

# Service finds pods by labels  
selector:
  app: my-app            # ← "Find pods where app=my-app"
```

**The label key and value must match exactly!**
