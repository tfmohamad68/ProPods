#!/bin/bash

# Script to update domain names in Kubernetes manifests
# Usage: ./update-domain.sh yourdomain.com

DOMAIN=${1}

if [ -z "$DOMAIN" ]; then
    echo "❌ Error: Please provide your domain name"
    echo "Usage: $0 yourdomain.com"
    exit 1
fi

echo "🌐 Updating domain references to: $DOMAIN"

# Update staging kustomization
sed -i.bak "s/staging-crm.yourdomain.com/staging-crm.$DOMAIN/g" k8s/staging/kustomization.yaml
echo "✅ Updated staging kustomization"

# Update production kustomization  
sed -i.bak "s/crm.yourdomain.com/crm.$DOMAIN/g" k8s/production/kustomization.yaml
echo "✅ Updated production kustomization"

# Update configmap
sed -i.bak "s/CRM_DOMAIN/$DOMAIN/g" k8s/base/configmap.yaml
echo "✅ Updated configmap"

# Update ingress
sed -i.bak "s/CRM_DOMAIN/$DOMAIN/g" k8s/base/ingress.yaml
echo "✅ Updated ingress"

# Update deployment workflows
sed -i.bak "s/staging-crm.yourdomain.com/staging-crm.$DOMAIN/g" .github/workflows/deploy-staging.yml
sed -i.bak "s/crm.yourdomain.com/crm.$DOMAIN/g" .github/workflows/deploy-prod.yml
echo "✅ Updated GitHub workflows"

# Clean up backup files
rm -f k8s/staging/kustomization.yaml.bak
rm -f k8s/production/kustomization.yaml.bak  
rm -f k8s/base/configmap.yaml.bak
rm -f k8s/base/ingress.yaml.bak
rm -f .github/workflows/deploy-staging.yml.bak
rm -f .github/workflows/deploy-prod.yml.bak

echo ""
echo "🎉 Domain update complete!"
echo ""
echo "📋 Next steps:"
echo "1. Add DNS A records in Cloudflare:"
echo "   staging-crm.$DOMAIN → 34.160.160.113"
echo "   crm.$DOMAIN → 34.149.120.90"
echo ""
echo "2. Commit and push changes:"
echo "   git add -A"
echo "   git commit -m 'Update domain configuration'"
echo "   git push"