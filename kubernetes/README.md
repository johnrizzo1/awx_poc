# AWX Kubernetes Ingress Setup

This directory contains Kubernetes manifests for exposing AWX via an Ingress resource.

## Prerequisites

Before creating the Ingress, ensure you have:

1. **An Ingress Controller installed** (choose one):
   - NGINX Ingress Controller (recommended)
   - Traefik
   - HAProxy
   - Other Ingress controllers

2. **AWX deployed via Helm chart**

3. **Know your AWX service name and namespace**

## Quick Start

### 1. Verify Your AWX Service

First, check your AWX service details:

```bash
# List services in all namespaces
kubectl get svc -A | grep awx

# Or if you know the namespace (e.g., 'default')
kubectl get svc -n default
```

Note the service name (likely `awx-service` or similar) and port.

### 2. Install NGINX Ingress Controller (if not already installed)

For K3s:
```bash
# K3s comes with Traefik by default, but you can install NGINX
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

For standard Kubernetes:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

For Minikube:
```bash
minikube addons enable ingress
```

### 3. Update the Ingress Manifest

Edit `awx-ingress.yaml` and update:

- **namespace**: Change to match your AWX deployment namespace
- **host**: Change `awx.local` to your desired hostname
- **service.name**: Change to match your actual AWX service name
- **service.port**: Change if your service uses a different port
- **ingressClassName**: Change to `traefik` if using Traefik

### 4. Apply the Ingress

```bash
kubectl apply -f awx-ingress.yaml
```

### 5. Verify the Ingress

```bash
# Check Ingress status
kubectl get ingress -n default

# Get detailed information
kubectl describe ingress awx-ingress -n default
```

### 6. Access AWX

#### Option A: Using /etc/hosts (for local testing)

Add an entry to your `/etc/hosts` file:

```bash
# Get the Ingress IP
kubectl get ingress awx-ingress -n default

# Add to /etc/hosts (replace <INGRESS_IP> with actual IP)
echo "<INGRESS_IP> awx.local" | sudo tee -a /etc/hosts
```

Then access AWX at: `http://awx.local`

#### Option B: Using DNS

If you have a domain, create a DNS A record pointing to your Ingress IP:

```
awx.yourdomain.com -> <INGRESS_IP>
```

#### Option C: Direct IP Access (if no hostname)

If you don't want to use a hostname, you can modify the Ingress to not require a host:

```yaml
spec:
  rules:
  - http:  # Remove the 'host' line
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: awx-service
            port:
              number: 80
```

Then access via the Ingress IP directly.

## TLS/HTTPS Setup

To enable HTTPS, uncomment the TLS section in `awx-ingress.yaml` and:

### Option 1: Self-Signed Certificate

```bash
# Create a self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=awx.local/O=AWX"

# Create Kubernetes secret
kubectl create secret tls awx-tls-secret \
  --key tls.key \
  --cert tls.crt \
  -n default
```

### Option 2: Let's Encrypt with cert-manager

1. Install cert-manager:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
```

2. Create a ClusterIssuer:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

3. Uncomment the TLS section in `awx-ingress.yaml` and apply it.

## Troubleshooting

### Ingress shows no ADDRESS

```bash
# Check Ingress controller pods
kubectl get pods -n ingress-nginx

# Check Ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Cannot access AWX

1. **Check Ingress status:**
```bash
kubectl get ingress -n default
kubectl describe ingress awx-ingress -n default
```

2. **Check service endpoints:**
```bash
kubectl get endpoints -n default
```

3. **Check AWX pods:**
```bash
kubectl get pods -n default
kubectl logs <awx-pod-name> -n default
```

4. **Test service directly:**
```bash
kubectl port-forward svc/awx-service 8080:80 -n default
# Then access http://localhost:8080
```

### 502 Bad Gateway

This usually means the backend service is not ready:

```bash
# Check AWX pod status
kubectl get pods -n default

# Check AWX logs
kubectl logs -l app.kubernetes.io/name=awx -n default
```

## Alternative: NodePort Service

If Ingress is not working, you can expose AWX via NodePort:

```bash
kubectl patch svc awx-service -n default -p '{"spec":{"type":"NodePort"}}'

# Get the NodePort
kubectl get svc awx-service -n default
```

Then access AWX at: `http://<node-ip>:<nodeport>`

## Alternative: LoadBalancer Service

For cloud environments:

```bash
kubectl patch svc awx-service -n default -p '{"spec":{"type":"LoadBalancer"}}'

# Get the LoadBalancer IP
kubectl get svc awx-service -n default
```

## Useful Commands

```bash
# Watch Ingress status
kubectl get ingress -n default -w

# Get Ingress YAML
kubectl get ingress awx-ingress -n default -o yaml

# Delete and recreate Ingress
kubectl delete ingress awx-ingress -n default
kubectl apply -f awx-ingress.yaml

# Check Ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=100 -f