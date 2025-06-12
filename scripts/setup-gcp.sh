#!/bin/bash

# GCP Setup Script for Twenty CRM
# This script sets up the Google Cloud Platform infrastructure

set -e

# Configuration
PROJECT_ID="${1:-your-project-id}"
REGION="us-central1"
ZONE="us-central1-a"

echo "🚀 Setting up GCP infrastructure for Twenty CRM"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"

# Authenticate and set project
echo "📋 Setting up GCP project..."
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "🔧 Enabling required APIs..."
gcloud services enable \
  container.googleapis.com \
  sql-component.googleapis.com \
  sqladmin.googleapis.com \
  redis.googleapis.com \
  storage.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com

# Create Artifact Registry repository
echo "📦 Creating Artifact Registry..."
gcloud artifacts repositories create twenty-crm \
  --repository-format=docker \
  --location=$REGION \
  --description="Twenty CRM Docker images" || echo "Repository may already exist"

# Create service account for GitHub Actions
echo "👤 Creating service account for deployments..."
gcloud iam service-accounts create twenty-deploy \
  --display-name="Twenty CRM Deployment Service Account" \
  --description="Service account for deploying Twenty CRM via GitHub Actions" || echo "Service account may already exist"

SERVICE_ACCOUNT="twenty-deploy@$PROJECT_ID.iam.gserviceaccount.com"

# Grant necessary permissions to service account
echo "🔐 Granting permissions to service account..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/container.developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/cloudsql.client"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/artifactregistry.writer"

# Create GKE clusters
echo "⚙️ Creating GKE staging cluster..."
gcloud container clusters create twenty-staging \
  --zone=$ZONE \
  --machine-type=e2-standard-2 \
  --num-nodes=2 \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=5 \
  --enable-autorepair \
  --enable-autoupgrade \
  --network=default \
  --subnetwork=default \
  --enable-ip-alias \
  --enable-network-policy \
  --enable-shielded-nodes \
  --disk-size=50GB \
  --disk-type=pd-ssd || echo "Staging cluster may already exist"

echo "⚙️ Creating GKE production cluster..."
gcloud container clusters create twenty-production \
  --zone=$ZONE \
  --machine-type=e2-standard-4 \
  --num-nodes=3 \
  --enable-autoscaling \
  --min-nodes=2 \
  --max-nodes=10 \
  --enable-autorepair \
  --enable-autoupgrade \
  --network=default \
  --subnetwork=default \
  --enable-ip-alias \
  --enable-network-policy \
  --enable-shielded-nodes \
  --disk-size=100GB \
  --disk-type=pd-ssd \
  --enable-monitoring \
  --enable-logging || echo "Production cluster may already exist"

# Create Cloud SQL instances
echo "🗄️ Creating Cloud SQL staging instance..."
gcloud sql instances create twenty-staging-db \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=$REGION \
  --storage-type=SSD \
  --storage-size=20GB \
  --storage-auto-increase \
  --backup-start-time=03:00 \
  --enable-bin-log \
  --maintenance-window-day=SUN \
  --maintenance-window-hour=04 \
  --maintenance-release-channel=production || echo "Staging DB may already exist"

echo "🗄️ Creating Cloud SQL production instance..."
gcloud sql instances create twenty-production-db \
  --database-version=POSTGRES_15 \
  --tier=db-custom-2-4096 \
  --region=$REGION \
  --storage-type=SSD \
  --storage-size=100GB \
  --storage-auto-increase \
  --backup-start-time=02:00 \
  --enable-bin-log \
  --maintenance-window-day=SUN \
  --maintenance-window-hour=03 \
  --maintenance-release-channel=production \
  --availability-type=REGIONAL || echo "Production DB may already exist"

# Create databases
echo "📊 Creating databases..."
gcloud sql databases create twenty --instance=twenty-staging-db || echo "Staging database may already exist"
gcloud sql databases create twenty --instance=twenty-production-db || echo "Production database may already exist"

# Create database users
echo "👤 Creating database users..."
STAGING_DB_PASSWORD=$(openssl rand -base64 32)
PROD_DB_PASSWORD=$(openssl rand -base64 32)

gcloud sql users create twenty-user \
  --instance=twenty-staging-db \
  --password=$STAGING_DB_PASSWORD || echo "Staging user may already exist"

gcloud sql users create twenty-user \
  --instance=twenty-production-db \
  --password=$PROD_DB_PASSWORD || echo "Production user may already exist"

# Create Redis instances
echo "🔴 Creating Redis staging instance..."
gcloud redis instances create twenty-staging-redis \
  --size=1 \
  --region=$REGION \
  --redis-version=redis_7_0 \
  --tier=basic || echo "Staging Redis may already exist"

echo "🔴 Creating Redis production instance..."
gcloud redis instances create twenty-production-redis \
  --size=5 \
  --region=$REGION \
  --redis-version=redis_7_0 \
  --tier=standard \
  --replica-count=1 || echo "Production Redis may already exist"

# Create storage buckets
echo "🪣 Creating storage buckets..."
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://twenty-storage-staging-$PROJECT_ID || echo "Staging bucket may already exist"
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://twenty-storage-production-$PROJECT_ID || echo "Production bucket may already exist"

# Set bucket permissions
gsutil iam ch serviceAccount:$SERVICE_ACCOUNT:objectAdmin gs://twenty-storage-staging-$PROJECT_ID
gsutil iam ch serviceAccount:$SERVICE_ACCOUNT:objectAdmin gs://twenty-storage-production-$PROJECT_ID

# Create secrets in Secret Manager
echo "🔐 Creating secrets in Secret Manager..."
echo -n "$STAGING_DB_PASSWORD" | gcloud secrets create staging-db-password --data-file=- || echo "Staging DB secret may already exist"
echo -n "$PROD_DB_PASSWORD" | gcloud secrets create prod-db-password --data-file=- || echo "Production DB secret may already exist"

# Generate app secrets
STAGING_APP_SECRET=$(openssl rand -base64 64)
PROD_APP_SECRET=$(openssl rand -base64 64)

echo -n "$STAGING_APP_SECRET" | gcloud secrets create staging-app-secret --data-file=- || echo "Staging app secret may already exist"
echo -n "$PROD_APP_SECRET" | gcloud secrets create prod-app-secret --data-file=- || echo "Production app secret may already exist"

# Reserve static IP addresses
echo "🌐 Reserving static IP addresses..."
gcloud compute addresses create twenty-staging-ip --global || echo "Staging IP may already exist"
gcloud compute addresses create twenty-production-ip --global || echo "Production IP may already exist"

# Get connection details
echo "📋 Getting connection details..."
STAGING_DB_IP=$(gcloud sql instances describe twenty-staging-db --format="value(ipAddresses[0].ipAddress)")
PROD_DB_IP=$(gcloud sql instances describe twenty-production-db --format="value(ipAddresses[0].ipAddress)")

STAGING_REDIS_IP=$(gcloud redis instances describe twenty-staging-redis --region=$REGION --format="value(host)")
PROD_REDIS_IP=$(gcloud redis instances describe twenty-production-redis --region=$REGION --format="value(host)")

STAGING_STATIC_IP=$(gcloud compute addresses describe twenty-staging-ip --global --format="value(address)")
PROD_STATIC_IP=$(gcloud compute addresses describe twenty-production-ip --global --format="value(address)")

echo "✅ GCP Infrastructure Setup Complete!"
echo ""
echo "📋 Connection Details:"
echo "========================"
echo "Staging Database IP: $STAGING_DB_IP"
echo "Production Database IP: $PROD_DB_IP"
echo "Staging Redis IP: $STAGING_REDIS_IP"
echo "Production Redis IP: $PROD_REDIS_IP"
echo "Staging Static IP: $STAGING_STATIC_IP"
echo "Production Static IP: $PROD_STATIC_IP"
echo ""
echo "🔐 Secrets created in Secret Manager:"
echo "- staging-db-password"
echo "- prod-db-password"
echo "- staging-app-secret"
echo "- prod-app-secret"
echo ""
echo "🚀 Next Steps:"
echo "1. Configure GitHub secrets with the connection details above"
echo "2. Update your domain DNS to point to the static IPs"
echo "3. Run the deployment workflows"
echo ""
echo "📝 GitHub Secrets to add:"
echo "GCP_PROJECT_ID=$PROJECT_ID"
echo "STAGING_PG_HOST=$STAGING_DB_IP"
echo "PROD_PG_HOST=$PROD_DB_IP"
echo "STAGING_REDIS_URL=redis://$STAGING_REDIS_IP:6379"
echo "PROD_REDIS_URL=redis://$PROD_REDIS_IP:6379"