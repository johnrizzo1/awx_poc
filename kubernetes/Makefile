.PHONY: all deploy deploy-operator deploy-secret deploy-service deploy-ingress clean help

# Default target - deploy everything
all: deploy

# Deploy all resources in the correct order
deploy: deploy-operator deploy-secret deploy-service deploy-ingress
	@echo "✓ All resources deployed successfully"

# Deploy the Tailscale operator (includes namespace, CRDs, RBAC, and deployment)
deploy-operator:
	@echo "Deploying Tailscale operator..."
	sudo k3s kubectl apply -f operator.yaml
	@echo "✓ Operator deployed"

# Deploy the Tailscale auth secret
deploy-secret:
	@echo "Deploying Tailscale auth secret..."
	sudo k3s kubectl apply -f secret.yaml
	@echo "✓ Secret deployed"

# Deploy the AWX service
deploy-service:
	@echo "Deploying AWX service..."
	sudo k3s kubectl apply -f awx-svc.yaml
	@echo "✓ Service deployed"

# Deploy the AWX ingress
deploy-ingress:
	@echo "Deploying AWX ingress..."
	sudo k3s kubectl apply -f awx-ingress.yaml
	@echo "✓ Ingress deployed"

# Remove all deployed resources
clean:
	@echo "Removing all resources..."
	-sudo k3s kubectl delete -f awx-ingress.yaml
	-sudo k3s kubectl delete -f awx-svc.yaml
	-sudo k3s kubectl delete -f secret.yaml
	-sudo k3s kubectl delete -f operator.yaml
	@echo "✓ All resources removed"

# Show status of deployed resources
status:
	@echo "=== Namespaces ==="
	sudo k3s kubectl get namespace tailscale awx 2>/dev/null || true
	@echo ""
	@echo "=== Tailscale Operator ==="
	sudo k3s kubectl get deployment -n tailscale operator 2>/dev/null || true
	@echo ""
	@echo "=== Secrets ==="
	sudo k3s kubectl get secret -n tailscale tailscale-auth 2>/dev/null || true
	@echo ""
	@echo "=== Services ==="
	sudo k3s kubectl get svc -n awx awx-service-lb 2>/dev/null || true
	@echo ""
	@echo "=== Ingresses ==="
	sudo k3s kubectl get ingress -n awx awx-ingress 2>/dev/null || true

# Show help
help:
	@echo "Available targets:"
	@echo "  make          - Deploy all resources (operator, secret, service, ingress)"
	@echo "  make deploy   - Same as 'make'"
	@echo "  make deploy-operator - Deploy only the Tailscale operator"
	@echo "  make deploy-secret   - Deploy only the Tailscale auth secret"
	@echo "  make deploy-service  - Deploy only the AWX service"
	@echo "  make deploy-ingress  - Deploy only the AWX ingress"
	@echo "  make status   - Show status of all deployed resources"
	@echo "  make clean    - Remove all deployed resources"
	@echo "  make help     - Show this help message"