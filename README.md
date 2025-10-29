# Wil's Playground Application

This GitOps repository is used by ArgoCD to deploy Wil's playground application from Docker Hub: https://hub.docker.com/r/wil42/playground

## Application Details

- **Image**: wil42/playground:v1 (supports v1 and v2 for rollback testing)
- **Port**: 8888
- **Namespace**: dev
- **Service Type**: LoadBalancer
- **Replicas**: 1

## Repository Structure

```
wil-playground-argocd/
├── README.md              # This file
├── deploy-and-test.sh     # Deploy and test the application
├── setup-github.sh        # Helper script to push to GitHub
└── manifests/
    ├── namespace.yaml     # Dev namespace
    ├── deployment.yaml    # Deployment with wil42/playground:v1
    ├── service.yaml       # LoadBalancer service on port 8888
    └── ingress.yaml       # Ingress configuration (if needed)
```

## GitOps Workflow

This repository is designed to be used with ArgoCD for GitOps deployments.

### Version Management

To change the application version:
1. Edit `deployment.yaml` and change the image tag from `v1` to `v2` (or vice versa)
2. Commit and push the changes
3. ArgoCD will automatically detect and sync the changes

Example:
```bash
# Edit the file
vim manifests/deployment.yaml
# Change: image: wil42/playground:v1
# To:     image: wil42/playground:v2

# Commit and push
git add manifests/deployment.yaml
git commit -m "Update to v2"
git push
```

### Quick Deploy and Test

Use the provided script to deploy and test the application:

```bash
./deploy-and-test.sh
```

This script will:
1. Check kubectl connectivity
2. Apply all manifests (namespace, deployment, service)
3. Wait for deployment to be ready
4. Test the application with curl
5. Verify the response format and version

### Manual Testing

After deployment, you can test the application manually:
```bash
# Check status
kubectl get pods -n dev
kubectl get svc -n dev

# Test the application
curl http://localhost:8888/
# Expected response: {"status":"ok", "message": "v1"}
```

## Docker Hub

Image available at: https://hub.docker.com/r/wil42/playground

## Requirements Compliance

✅ Uses wil42/playground image (as specified in project requirements)
✅ Supports version switching (v1/v2)
✅ Uses port 8888
✅ Deployed in 'dev' namespace
✅ GitOps deployment via ArgoCD
✅ Self-healing enabled
✅ Automated sync enabled

