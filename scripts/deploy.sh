#!/bin/bash

# Deployment script for Twenty CRM
# Usage: ./deploy.sh [staging|production] [version]

set -e

ENVIRONMENT=${1:-staging}
VERSION=${2:-latest}
PROJECT_ID=${GCP_PROJECT_ID:-"your-project-id"}
REGION="us-central1"

if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    echo "❌ Error: Environment must be 'staging' or 'production'"
    echo "Usage: $0 [staging|production] [version]"
    exit 1
fi

echo "🚀 Deploying Twenty CRM to $ENVIRONMENT environment"
echo "Version: $VERSION"
echo "Project: $PROJECT_ID"

# Set cluster based on environment
if [[ "$ENVIRONMENT" == "staging" ]]; then
    CLUSTER="twenty-staging"
    NAMESPACE="twenty-staging"
    ZONE="us-central1-a"
else
    CLUSTER="twenty-production"
    NAMESPACE="twenty-production"
    ZONE="us-central1-a"
fi

# Authenticate with GCP
echo "🔐 Authenticating with GCP..."
gcloud auth application-default login --quiet

# Get cluster credentials
echo "🔧 Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER --zone=$ZONE --project=$PROJECT_ID

# Verify kubectl connection
echo "✅ Verifying cluster connection..."
kubectl cluster-info

# Create namespace if it doesn't exist
echo "📦 Creating namespace if needed..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Build and push Docker image if version is 'latest'
if [[ "$VERSION" == "latest" ]]; then
    echo "🐳 Building and pushing Docker image..."
    
    # Build image
    docker build -f docker/Dockerfile.prod -t gcr.io/$PROJECT_ID/twenty:$VERSION .
    
    # Push to registry
    docker push gcr.io/$PROJECT_ID/twenty:$VERSION
    
    VERSION=$(docker images gcr.io/$PROJECT_ID/twenty --format "table {{.Tag}}" | head -2 | tail -1)
fi

# Update Kubernetes manifests
echo "📝 Updating Kubernetes manifests..."
cd k8s/$ENVIRONMENT
kustomize edit set image gcr.io/PROJECT_ID/twenty=gcr.io/$PROJECT_ID/twenty:$VERSION

# Apply configurations
echo "⚙️ Applying Kubernetes configurations..."
kustomize build . | kubectl apply -f -

# Wait for rollout to complete
echo "⏳ Waiting for deployment to complete..."
kubectl rollout status deployment/twenty-server -n $NAMESPACE --timeout=600s
kubectl rollout status deployment/twenty-worker -n $NAMESPACE --timeout=300s

# Verify deployment
echo "🔍 Verifying deployment..."
kubectl get pods -n $NAMESPACE
kubectl get services -n $NAMESPACE

# Get service URL
if [[ "$ENVIRONMENT" == "staging" ]]; then
    SERVICE_URL="https://staging-crm.yourdomain.com"
else
    SERVICE_URL="https://crm.yourdomain.com"
fi

# Run health check
echo "🏥 Running health check..."
for i in {1..30}; do
    if curl -f -s "$SERVICE_URL/healthz" > /dev/null; then
        echo "✅ Service is healthy at $SERVICE_URL"
        break
    fi
    echo "⏳ Waiting for service to be ready... ($i/30)"
    sleep 10
done

# Test GraphQL endpoint
echo "🧪 Testing GraphQL endpoint..."
if curl -f -s "$SERVICE_URL/graphql" -H "Content-Type: application/json" -d '{"query":"{ __typename }"}' | grep -q "__typename"; then
    echo "✅ GraphQL endpoint is working"
else
    echo "❌ GraphQL endpoint test failed"
    exit 1
fi

echo "🎉 Deployment to $ENVIRONMENT completed successfully!"
echo "🌐 Service URL: $SERVICE_URL"

# Show deployment info
echo ""
echo "📊 Deployment Summary:"
echo "======================"
echo "Environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"
echo "Version: $VERSION"
echo "URL: $SERVICE_URL"
echo ""
echo "📋 Useful commands:"
echo "kubectl get pods -n $NAMESPACE"
echo "kubectl logs -f deployment/twenty-server -n $NAMESPACE"
echo "kubectl describe deployment twenty-server -n $NAMESPACE"