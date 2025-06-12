# Twenty CRM - GCP Deployment Guide

This guide covers deploying Twenty CRM to Google Cloud Platform using Kubernetes, with automated CI/CD via GitHub Actions.

## 🏗️ Architecture Overview

### Infrastructure Components
- **GKE Clusters**: Staging and Production Kubernetes clusters
- **Cloud SQL**: Managed PostgreSQL databases
- **Memorystore**: Managed Redis instances
- **Cloud Storage**: File storage buckets
- **Artifact Registry**: Docker image storage
- **Load Balancer**: HTTPS termination and traffic routing
- **Cloud CDN**: Static asset caching

### Environments
- **Staging**: `staging-crm.yourdomain.com` - Auto-deploy from `develop` branch
- **Production**: `crm.yourdomain.com` - Auto-deploy from `main` branch

## 🚀 Quick Start

### Prerequisites
1. Google Cloud Platform account with billing enabled
2. GitHub repository with this codebase
3. Domain managed by Cloudflare
4. `gcloud` CLI installed and authenticated

### 1. Initial GCP Setup

```bash
# Make the setup script executable (if not already)
chmod +x scripts/setup-gcp.sh

# Run the setup script with your GCP project ID
./scripts/setup-gcp.sh your-project-id
```

This script will:
- Enable required GCP APIs
- Create GKE clusters (staging and production)
- Set up Cloud SQL instances
- Create Redis instances
- Configure storage buckets
- Set up service accounts and IAM permissions
- Create secrets in Secret Manager

### 2. Configure GitHub Secrets

Add the following secrets to your GitHub repository (`Settings > Secrets and variables > Actions`):

#### Required Secrets
```
GCP_PROJECT_ID=your-project-id
WIF_PROVIDER=projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID
WIF_SERVICE_ACCOUNT=twenty-deploy@your-project-id.iam.gserviceaccount.com

# Staging Environment
STAGING_PG_HOST=staging-db-ip
STAGING_PG_USER=twenty-user
STAGING_PG_PASSWORD=staging-db-password
STAGING_REDIS_URL=redis://staging-redis-ip:6379
STAGING_APP_SECRET=staging-app-secret

# Production Environment
PROD_PG_HOST=production-db-ip
PROD_PG_USER=twenty-user
PROD_PG_PASSWORD=production-db-password
PROD_REDIS_URL=redis://production-redis-ip:6379
PROD_APP_SECRET=production-app-secret
```

### 3. Configure DNS

Update your Cloudflare DNS settings:

```
# Staging
staging-crm.yourdomain.com A staging-static-ip

# Production
crm.yourdomain.com A production-static-ip
```

### 4. Deploy

#### Deploy to Staging
```bash
# Push to develop branch to trigger staging deployment
git checkout develop
git push origin develop
```

#### Deploy to Production
```bash
# Push to main branch to trigger production deployment
git checkout main
git push origin main
```

## 🔧 Manual Deployment

If you prefer manual deployment or need to troubleshoot:

### Build and Deploy Staging
```bash
# Build and deploy to staging
./scripts/deploy.sh staging

# Or with specific version
./scripts/deploy.sh staging v1.2.3
```

### Build and Deploy Production
```bash
# Build and deploy to production
./scripts/deploy.sh production

# Or with specific version
./scripts/deploy.sh production v1.2.3
```

### Rollback
```bash
# Rollback to previous version
./scripts/rollback.sh production

# Rollback to specific revision
./scripts/rollback.sh production 5
```

## 📊 Monitoring and Maintenance

### View Logs
```bash
# Server logs
kubectl logs -f deployment/twenty-server -n twenty-production

# Worker logs
kubectl logs -f deployment/twenty-worker -n twenty-production

# All pods
kubectl logs -f -l app=twenty -n twenty-production
```

### Check Status
```bash
# Pod status
kubectl get pods -n twenty-production

# Service status
kubectl get services -n twenty-production

# Deployment status
kubectl get deployments -n twenty-production
```

### Scale Application
```bash
# Scale server replicas
kubectl scale deployment twenty-server --replicas=5 -n twenty-production

# Scale worker replicas
kubectl scale deployment twenty-worker --replicas=3 -n twenty-production
```

### Database Operations
```bash
# Connect to staging database
gcloud sql connect twenty-staging-db --user=twenty-user

# Connect to production database
gcloud sql connect twenty-production-db --user=twenty-user

# Create database backup
gcloud sql backups create --instance=twenty-production-db
```

## 🔐 Security Considerations

### Secrets Management
- All sensitive data stored in GCP Secret Manager
- Kubernetes secrets created automatically via CI/CD
- No secrets committed to repository

### Network Security
- GKE clusters use private nodes
- Database instances use private IPs
- All traffic encrypted in transit

### Access Control
- Principle of least privilege for service accounts
- Workload Identity for secure GKE-to-GCP communication
- Regular rotation of secrets and credentials

## 🚨 Troubleshooting

### Common Issues

#### Deployment Fails
```bash
# Check deployment status
kubectl rollout status deployment/twenty-server -n twenty-production

# Check events
kubectl get events -n twenty-production --sort-by='.lastTimestamp'

# Check pod logs
kubectl describe pod <pod-name> -n twenty-production
```

#### Database Connection Issues
```bash
# Test database connectivity
kubectl run test-db --image=postgres:15 --rm -it --restart=Never \
  -- psql -h $PG_HOST -U $PG_USER -d twenty

# Check Cloud SQL instance status
gcloud sql instances describe twenty-production-db
```

#### DNS/SSL Issues
```bash
# Check static IP allocation
gcloud compute addresses list

# Check SSL certificate status
kubectl describe managedcertificate twenty-ssl-cert -n twenty-production

# Check ingress status
kubectl describe ingress twenty-ingress -n twenty-production
```

## 🔄 CI/CD Pipeline Details

### Workflow Triggers
- **CI**: Pull requests to `main` or `develop`
- **Staging Deploy**: Push to `develop`
- **Production Deploy**: Push to `main`

### Pipeline Steps
1. **Test**: Run linting and unit tests
2. **Build**: Create optimized Docker image
3. **Deploy**: Apply Kubernetes manifests
4. **Verify**: Run health checks and smoke tests
5. **Notify**: Send deployment notifications

### Rollback Strategy
- Automatic rollback on deployment failure
- Manual rollback via scripts or GitHub Actions
- Database migrations are reversible
- Zero-downtime deployments via rolling updates

## 📈 Performance Optimization

### Resource Allocation
- **Staging**: 1-2 server replicas, 1 worker replica
- **Production**: 3+ server replicas, 2+ worker replicas
- **Auto-scaling**: Based on CPU and memory usage

### Caching Strategy
- Redis for session and application caching
- Cloud CDN for static assets
- Database query optimization

### Monitoring
- Application metrics via Prometheus
- Infrastructure monitoring via Cloud Monitoring
- Error tracking via Sentry
- Performance monitoring via APM

## 🧪 Testing Strategy

### Local Testing
```bash
# Test with production-like environment
docker-compose -f docker/docker-compose.prod.yml up
```

### Staging Testing
- Automated smoke tests after deployment
- Manual QA testing
- Performance testing
- Security scanning

### Production Validation
- Health checks during deployment
- Canary releases for major updates
- A/B testing capabilities
- Real user monitoring

## 📋 Maintenance Checklist

### Daily
- [ ] Check application health
- [ ] Monitor error rates
- [ ] Review resource usage

### Weekly
- [ ] Review security alerts
- [ ] Check backup status
- [ ] Update dependencies (if needed)

### Monthly
- [ ] Rotate secrets
- [ ] Review access permissions
- [ ] Optimize resource allocation
- [ ] Update documentation

For more detailed information, refer to the individual configuration files in the `k8s/` and `scripts/` directories.