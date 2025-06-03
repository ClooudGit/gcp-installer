#!/bin/bash
# deploy.sh - Deploy Clooud monitoring integration to GCP

set -e

echo "╔══════════════════════════════════════════════════╗"
echo "║     Clooud Monitoring Integration Setup          ║"
echo "╚══════════════════════════════════════════════════╝"
echo

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed. Please install it first."
    exit 1
fi

# Get current project
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [ -z "$CURRENT_PROJECT" ]; then
    echo "❌ No GCP project is set. Please run 'gcloud config set project PROJECT_ID' first."
    exit 1
fi

echo "📋 Current Project: $CURRENT_PROJECT"
echo

# Prompt for required parameters
read -p "Enter your Clooud Team ID: " TEAM_ID
if [ -z "$TEAM_ID" ]; then
    echo "❌ Team ID is required"
    exit 1
fi

read -p "Enter your Clooud User ID: " USER_ID
if [ -z "$USER_ID" ]; then
    echo "❌ User ID is required"
    exit 1
fi

# Select environment
echo
echo "Select environment:"
echo "1) Production (api.clooud.com)"
echo "2) Test (test-api.clooud.com)"
echo "3) Development (ngrok)"
read -p "Enter choice [1-3]: " ENV_CHOICE

case $ENV_CHOICE in
    1)
        WEBHOOK_URL="https://api.clooud.com/api/webhooks/gcp/alarm"
        ENV_NAME="prod"
        ;;
    2)
        WEBHOOK_URL="https://test-api.clooud.com/api/webhooks/gcp/alarm"
        ENV_NAME="test"
        ;;
    3)
        WEBHOOK_URL="https://informed-sunfish-communal.ngrok-free.app/api/webhooks/gcp/alarm"
        ENV_NAME="dev"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

DEPLOYMENT_NAME="clooud-monitoring-${TEAM_ID}"

# Create config file
cat > deployment-config.yaml <<EOF
imports:
- path: clooud-monitoring.jinja

resources:
- name: clooud-integration
  type: clooud-monitoring.jinja
  properties:
    teamId: "${TEAM_ID}"
    userId: "${USER_ID}"
    webhookUrl: "${WEBHOOK_URL}"
    environment: "${ENV_NAME}"
EOF

echo
echo "🔧 Enabling required APIs..."
gcloud services enable deploymentmanager.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com

echo
echo "🚀 Deploying Clooud monitoring integration..."
if gcloud deployment-manager deployments create ${DEPLOYMENT_NAME} --config deployment-config.yaml; then
    echo
    echo "✅ Deployment successful!"
    echo
    echo "📊 Deployment Details:"
    gcloud deployment-manager deployments describe ${DEPLOYMENT_NAME} --format="value(outputs)"
    echo
    echo "🎯 Next Steps:"
    echo "1. Go to Cloud Monitoring in the GCP Console"
    echo "2. Create or edit an alerting policy"
    echo "3. In the notification channel section, select 'Clooud Monitoring Notifications'"
    echo "4. Save your alerting policy"
    echo
    echo "Your alerts will now be sent to Clooud! 🎉"
else
    echo
    echo "❌ Deployment failed. Please check the error messages above."
    echo "To retry, first delete the failed deployment:"
    echo "gcloud deployment-manager deployments delete ${DEPLOYMENT_NAME}"
fi

# Clean up config file
rm -f deployment-config.yaml