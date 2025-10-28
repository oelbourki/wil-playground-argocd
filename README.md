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
├── README.md         # This file
├── setup-github.sh   # Helper script to push to GitHub
└── manifests/
    ├── namespace.yaml    # Dev namespace
    ├── deployment.yaml   # Deployment with wil42/playground:v1
    ├── service.yaml      # LoadBalancer service on port 8888
    └── ingress.yaml      # Ingress configuration
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

### Testing the Application

After deployment, you can test the application:
```bash
# Check status
kubectl get pods -n dev
kubectl get svc -n dev

# Test the application
curl http://localhost:8888
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

