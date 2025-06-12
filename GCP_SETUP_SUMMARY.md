# GCP Infrastructure Setup Summary

## Project Details
- **Project ID**: `propods-crm`
- **Project Number**: `1839988285`
- **Region**: `us-central1`
- **Zone**: `us-central1-a`

## 🎯 Infrastructure Created

### Kubernetes Clusters
- **Staging**: `twenty-staging` (2 x e2-standard-2 nodes)
- **Production**: `twenty-production` (3 x e2-standard-4 nodes)

### Databases (Cloud SQL - PostgreSQL 15)
- **Staging**: `twenty-staging-db` (db-f1-micro, IP: `34.66.240.32`)
- **Production**: `twenty-production-db` (db-custom-2-4096, IP: `35.223.160.163`)
- **Database Name**: `twenty`
- **Database User**: `twenty-user`

### Redis (Memorystore)
- **Staging**: `twenty-staging-redis` (Basic, 1GB, IP: `10.204.184.243`)
- **Production**: `twenty-production-redis` (Standard HA, 5GB, IP: `10.254.128.188`)

### Storage Buckets
- **Staging**: `gs://twenty-storage-staging-propods-crm`
- **Production**: `gs://twenty-storage-production-propods-crm`

### Static IP Addresses
- **Staging**: `34.160.160.113`
- **Production**: `34.149.120.90`

### Container Registry
- **Repository**: `us-central1-docker.pkg.dev/propods-crm/twenty-crm`

## 🔐 Generated Secrets

### Database Passwords
- **Staging DB Password**: `wjz6fU9lDIcLPmX2Sl0xJ8Jc9h+SNRlcY2aL1SDix/k=`
- **Production DB Password**: `K8XTON1/pehxVp2NxG5khEuVLXtqMP/ttb0sc/DBs+M=`

### Application Secrets
- **Staging App Secret**: `cjMeBFZe8SCKZ+PV0Fuj45mGeacCV1mRcD+Ly6Ee+kX7vTTIcuE9GChkOUc1n2P0fcoA/NVLc3Tc4YYdOjTiHw==`
- **Production App Secret**: `59FVjKMvh38llmohzPONBGYPT33tOnkKmNbbFWItCyN/KVkTho5FA5glGiitpXNbLyIiOwlpEgG+1AmgAWRWGA==`

## 🚀 Next Steps for GitHub Actions

### Required GitHub Secrets
Add these secrets to your GitHub repository (`Settings > Secrets and variables > Actions`):

```bash
# Core GCP Configuration
GCP_PROJECT_ID=propods-crm
WIF_PROVIDER=projects/1839988285/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID
WIF_SERVICE_ACCOUNT=twenty-deploy@propods-crm.iam.gserviceaccount.com

# Staging Environment
STAGING_PG_HOST=34.66.240.32
STAGING_PG_USER=twenty-user
STAGING_PG_PASSWORD=wjz6fU9lDIcLPmX2Sl0xJ8Jc9h+SNRlcY2aL1SDix/k=
STAGING_REDIS_URL=redis://10.204.184.243:6379
STAGING_APP_SECRET=cjMeBFZe8SCKZ+PV0Fuj45mGeacCV1mRcD+Ly6Ee+kX7vTTIcuE9GChkOUc1n2P0fcoA/NVLc3Tc4YYdOjTiHw==

# Production Environment
PROD_PG_HOST=35.223.160.163
PROD_PG_USER=twenty-user
PROD_PG_PASSWORD=K8XTON1/pehxVp2NxG5khEuVLXtqMP/ttb0sc/DBs+M=
PROD_REDIS_URL=redis://10.254.128.188:6379
PROD_APP_SECRET=59FVjKMvh38llmohzPONBGYPT33tOnkKmNbbFWItCyN/KVkTho5FA5glGiitpXNbLyIiOwlpEgG+1AmgAWRWGA==
```

### DNS Configuration for Cloudflare
Add these A records to your Cloudflare DNS:

```bash
# Staging Environment
staging-crm.yourdomain.com  A  34.160.160.113

# Production Environment
crm.yourdomain.com  A  34.149.120.90
```

## 🔧 Workload Identity Setup

To complete the GitHub Actions integration, you need to set up Workload Identity Federation:

1. **Create Workload Identity Pool:**
```bash
gcloud iam workload-identity-pools create "github-pool" \
  --project="propods-crm" \
  --location="global" \
  --display-name="GitHub Actions Pool"
```

2. **Create Workload Identity Provider:**
```bash
gcloud iam workload-identity-pools providers create-oidc "github" \
  --project="propods-crm" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

3. **Bind Service Account:**
```bash
gcloud iam service-accounts add-iam-policy-binding \
  "twenty-deploy@propods-crm.iam.gserviceaccount.com" \
  --project="propods-crm" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/1839988285/locations/global/workloadIdentityPools/github-pool/attribute.repository/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME"
```

## 📊 Service Account Details
- **Name**: `twenty-deploy@propods-crm.iam.gserviceaccount.com`
- **Roles**: 
  - `roles/container.developer`
  - `roles/storage.admin` 
  - `roles/cloudsql.client`
  - `roles/secretmanager.secretAccessor`
  - `roles/artifactregistry.writer`

## ✅ Infrastructure Status
- ✅ GKE Clusters (Staging & Production)
- ✅ Cloud SQL Instances (Staging & Production)
- ✅ Redis Instances (Staging & Production)
- ✅ Storage Buckets (Staging & Production)
- ✅ Static IP Addresses Reserved
- ✅ Artifact Registry Repository
- ✅ Service Account with Proper Permissions
- ✅ Database Users Created
- ✅ Kubernetes Manifests Updated

## 🎯 Ready for Deployment!

Your GCP infrastructure is now complete and ready for:
1. Setting up Workload Identity Federation
2. Adding GitHub secrets
3. Configuring DNS
4. Deploying the application

Total setup time: ~30 minutes
Monthly estimated cost: ~$150-300 (depending on usage)