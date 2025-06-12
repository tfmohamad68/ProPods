#!/bin/bash

# Validation script to check GCP setup
# Usage: ./validate-setup.sh

echo "🔍 Validating Twenty CRM GCP Setup..."
echo "======================================"

# Check GCP project
echo "📋 Checking GCP project..."
PROJECT=$(gcloud config get-value project)
if [ "$PROJECT" = "propods-crm" ]; then
    echo "✅ Project: $PROJECT"
else
    echo "❌ Wrong project: $PROJECT (expected: propods-crm)"
fi

# Check clusters
echo ""
echo "⚙️ Checking GKE clusters..."
STAGING_CLUSTER=$(gcloud container clusters list --filter="name=twenty-staging" --format="value(name)" 2>/dev/null)
PROD_CLUSTER=$(gcloud container clusters list --filter="name=twenty-production" --format="value(name)" 2>/dev/null)

if [ "$STAGING_CLUSTER" = "twenty-staging" ]; then
    echo "✅ Staging cluster: $STAGING_CLUSTER"
else
    echo "❌ Staging cluster not found"
fi

if [ "$PROD_CLUSTER" = "twenty-production" ]; then
    echo "✅ Production cluster: $PROD_CLUSTER"
else
    echo "❌ Production cluster not found"
fi

# Check SQL instances
echo ""
echo "🗄️ Checking Cloud SQL instances..."
STAGING_DB=$(gcloud sql instances list --filter="name=twenty-staging-db" --format="value(name)" 2>/dev/null)
PROD_DB=$(gcloud sql instances list --filter="name=twenty-production-db" --format="value(name)" 2>/dev/null)

if [ "$STAGING_DB" = "twenty-staging-db" ]; then
    echo "✅ Staging database: $STAGING_DB"
else
    echo "❌ Staging database not found"
fi

if [ "$PROD_DB" = "twenty-production-db" ]; then
    echo "✅ Production database: $PROD_DB"
else
    echo "❌ Production database not found"
fi

# Check Redis instances  
echo ""
echo "🔴 Checking Redis instances..."
STAGING_REDIS=$(gcloud redis instances list --region=us-central1 --filter="name=twenty-staging-redis" --format="value(name)" 2>/dev/null)
PROD_REDIS=$(gcloud redis instances list --region=us-central1 --filter="name=twenty-production-redis" --format="value(name)" 2>/dev/null)

if [ "$STAGING_REDIS" = "twenty-staging-redis" ]; then
    echo "✅ Staging Redis: $STAGING_REDIS"
else
    echo "❌ Staging Redis not found"
fi

if [ "$PROD_REDIS" = "twenty-production-redis" ]; then
    echo "✅ Production Redis: $PROD_REDIS"
else
    echo "❌ Production Redis not found"
fi

# Check static IPs
echo ""
echo "🌐 Checking static IP addresses..."
STAGING_IP=$(gcloud compute addresses list --global --filter="name=twenty-staging-ip" --format="value(address)" 2>/dev/null)
PROD_IP=$(gcloud compute addresses list --global --filter="name=twenty-production-ip" --format="value(address)" 2>/dev/null)

if [ -n "$STAGING_IP" ]; then
    echo "✅ Staging IP: $STAGING_IP"
else
    echo "❌ Staging IP not found"
fi

if [ -n "$PROD_IP" ]; then
    echo "✅ Production IP: $PROD_IP"
else
    echo "❌ Production IP not found"
fi

# Check Artifact Registry
echo ""
echo "📦 Checking Artifact Registry..."
REGISTRY=$(gcloud artifacts repositories list --location=us-central1 --filter="name:twenty-crm" --format="value(name)" 2>/dev/null)

if [[ "$REGISTRY" == *"twenty-crm"* ]]; then
    echo "✅ Artifact Registry: twenty-crm"
else
    echo "❌ Artifact Registry not found"
fi

# Check service account
echo ""
echo "👤 Checking service account..."
SERVICE_ACCOUNT=$(gcloud iam service-accounts list --filter="email=twenty-deploy@propods-crm.iam.gserviceaccount.com" --format="value(email)" 2>/dev/null)

if [ "$SERVICE_ACCOUNT" = "twenty-deploy@propods-crm.iam.gserviceaccount.com" ]; then
    echo "✅ Service account: $SERVICE_ACCOUNT"
else
    echo "❌ Service account not found"
fi

# Check Workload Identity Pool
echo ""
echo "🔐 Checking Workload Identity..."
WI_POOL=$(gcloud iam workload-identity-pools list --location=global --filter="name:github-pool" --format="value(name)" 2>/dev/null)

if [[ "$WI_POOL" == *"github-pool"* ]]; then
    echo "✅ Workload Identity Pool: github-pool"
else
    echo "❌ Workload Identity Pool not found"
fi

echo ""
echo "🎯 Summary:"
echo "==========="
echo "All core GCP infrastructure should be ✅"
echo ""
echo "📋 Next Steps:"
echo "1. Set up your GitHub repository"
echo "2. Add GitHub secrets (see GITHUB_SETUP_INSTRUCTIONS.md)"
echo "3. Configure DNS in Cloudflare"
echo "4. Update domain names: ./scripts/update-domain.sh yourdomain.com"
echo "5. Deploy!"