# GitHub Repository Setup Instructions

## 🔐 Step 1: Complete Workload Identity Setup

Once you have your GitHub repository ready, run this command to bind the service account:

```bash
gcloud iam service-accounts add-iam-policy-binding \
  "twenty-deploy@propods-crm.iam.gserviceaccount.com" \
  --project="propods-crm" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/1839988285/locations/global/workloadIdentityPools/github-pool/attribute.repository/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME"
```

**Replace `YOUR_GITHUB_USERNAME/YOUR_REPO_NAME` with your actual GitHub repository path!**

## 🔑 Step 2: Add GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add these secrets one by one:

### Core GCP Configuration
```
Name: GCP_PROJECT_ID
Value: propods-crm
```

```
Name: WIF_PROVIDER
Value: projects/1839988285/locations/global/workloadIdentityPools/github-pool/providers/github
```

```
Name: WIF_SERVICE_ACCOUNT
Value: twenty-deploy@propods-crm.iam.gserviceaccount.com
```

### Staging Environment Secrets
```
Name: STAGING_PG_HOST
Value: 34.66.240.32
```

```
Name: STAGING_PG_USER
Value: twenty-user
```

```
Name: STAGING_PG_PASSWORD
Value: wjz6fU9lDIcLPmX2Sl0xJ8Jc9h+SNRlcY2aL1SDix/k=
```

```
Name: STAGING_REDIS_URL
Value: redis://10.204.184.243:6379
```

```
Name: STAGING_APP_SECRET
Value: cjMeBFZe8SCKZ+PV0Fuj45mGeacCV1mRcD+Ly6Ee+kX7vTTIcuE9GChkOUc1n2P0fcoA/NVLc3Tc4YYdOjTiHw==
```

### Production Environment Secrets
```
Name: PROD_PG_HOST
Value: 35.223.160.163
```

```
Name: PROD_PG_USER
Value: twenty-user
```

```
Name: PROD_PG_PASSWORD
Value: K8XTON1/pehxVp2NxG5khEuVLXtqMP/ttb0sc/DBs+M=
```

```
Name: PROD_REDIS_URL
Value: redis://10.254.128.188:6379
```

```
Name: PROD_APP_SECRET
Value: 59FVjKMvh38llmohzPONBGYPT33tOnkKmNbbFWItCyN/KVkTho5FA5glGiitpXNbLyIiOwlpEgG+1AmgAWRWGA==
```

## 🌐 Step 3: Configure DNS in Cloudflare

1. Log in to your Cloudflare dashboard
2. Select your domain
3. Go to DNS → Records
4. Add these A records:

### Staging Environment
```
Type: A
Name: staging-crm
Content: 34.160.160.113
Proxy status: DNS only (gray cloud)
TTL: Auto
```

### Production Environment
```
Type: A
Name: crm
Content: 34.149.120.90
Proxy status: DNS only (gray cloud)
TTL: Auto
```

## 📝 Step 4: Update Domain References

Update the following files with your actual domain name:

1. **k8s/staging/kustomization.yaml**: Replace `staging-crm.yourdomain.com` with `staging-crm.YOURDOMAIN.com`
2. **k8s/production/kustomization.yaml**: Replace `crm.yourdomain.com` with `crm.YOURDOMAIN.com`
3. **k8s/base/configmap.yaml**: Replace `CRM_DOMAIN` placeholders
4. **k8s/base/ingress.yaml**: Replace `CRM_DOMAIN` placeholders

## 🚀 Step 5: Test the Setup

1. **Push to develop branch** to trigger staging deployment
2. **Push to main branch** to trigger production deployment

## 🔍 Step 6: Monitor Deployment

Check the GitHub Actions tab in your repository to monitor:
- Build and test jobs
- Docker image creation
- Kubernetes deployment
- Health checks

## 📊 Useful Commands for Monitoring

```bash
# Check cluster status
gcloud container clusters get-credentials twenty-staging --zone=us-central1-a
kubectl get pods -n twenty-staging

# Check application logs
kubectl logs -f deployment/twenty-server -n twenty-staging

# Check service status
kubectl get services -n twenty-staging
```

## 🆘 Troubleshooting

If deployments fail:

1. **Check GitHub Actions logs** for detailed error messages
2. **Verify all secrets** are correctly set
3. **Check Kubernetes events**: `kubectl get events -n twenty-staging --sort-by='.lastTimestamp'`
4. **Verify DNS propagation**: `nslookup staging-crm.yourdomain.com`

## ✅ Checklist

- [ ] GitHub repository created/updated with code
- [ ] Workload Identity binding completed with actual repo name
- [ ] All GitHub secrets added
- [ ] DNS A records added in Cloudflare
- [ ] Domain names updated in Kubernetes manifests
- [ ] First deployment triggered
- [ ] Services accessible via URLs

Once you complete these steps, your Twenty CRM will be fully deployed and accessible!