#!/bin/bash

# Rollback script for Twenty CRM
# Usage: ./rollback.sh [staging|production] [revision_number]

set -e

ENVIRONMENT=${1:-staging}
REVISION=${2:-""}
PROJECT_ID=${GCP_PROJECT_ID:-"your-project-id"}

if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    echo "❌ Error: Environment must be 'staging' or 'production'"
    echo "Usage: $0 [staging|production] [revision_number]"
    exit 1
fi

echo "🔄 Rolling back Twenty CRM in $ENVIRONMENT environment"

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

# Get cluster credentials
echo "🔧 Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER --zone=$ZONE --project=$PROJECT_ID

# Show current rollout history
echo "📋 Current rollout history:"
kubectl rollout history deployment/twenty-server -n $NAMESPACE
kubectl rollout history deployment/twenty-worker -n $NAMESPACE

# Perform rollback
if [[ -n "$REVISION" ]]; then
    echo "🔄 Rolling back to revision $REVISION..."
    kubectl rollout undo deployment/twenty-server -n $NAMESPACE --to-revision=$REVISION
    kubectl rollout undo deployment/twenty-worker -n $NAMESPACE --to-revision=$REVISION
else
    echo "🔄 Rolling back to previous revision..."
    kubectl rollout undo deployment/twenty-server -n $NAMESPACE
    kubectl rollout undo deployment/twenty-worker -n $NAMESPACE
fi

# Wait for rollback to complete
echo "⏳ Waiting for rollback to complete..."
kubectl rollout status deployment/twenty-server -n $NAMESPACE --timeout=600s
kubectl rollout status deployment/twenty-worker -n $NAMESPACE --timeout=300s

# Verify rollback
echo "🔍 Verifying rollback..."
kubectl get pods -n $NAMESPACE

# Get service URL
if [[ "$ENVIRONMENT" == "staging" ]]; then
    SERVICE_URL="https://staging-crm.yourdomain.com"
else
    SERVICE_URL="https://crm.yourdomain.com"
fi

# Run health check
echo "🏥 Running health check after rollback..."
for i in {1..30}; do
    if curl -f -s "$SERVICE_URL/healthz" > /dev/null; then
        echo "✅ Service is healthy after rollback"
        break
    fi
    echo "⏳ Waiting for service to be ready... ($i/30)"
    sleep 10
done

# Test GraphQL endpoint
echo "🧪 Testing GraphQL endpoint..."
if curl -f -s "$SERVICE_URL/graphql" -H "Content-Type: application/json" -d '{"query":"{ __typename }"}' | grep -q "__typename"; then
    echo "✅ GraphQL endpoint is working after rollback"
else
    echo "❌ GraphQL endpoint test failed after rollback"
    exit 1
fi

echo "✅ Rollback to $ENVIRONMENT completed successfully!"
echo "🌐 Service URL: $SERVICE_URL"

# Show current deployment info
echo ""
echo "📊 Current Deployment Info:"
echo "=========================="
kubectl describe deployment twenty-server -n $NAMESPACE | grep -E "(Image|Replicas)"