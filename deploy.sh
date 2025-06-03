#!/bin/bash
# deploy.sh - Deploy Clooud monitoring integration to GCP

set -e

clear
echo "╔══════════════════════════════════════════════════╗"
echo "║     Clooud Monitoring Integration Setup          ║"
echo "╚══════════════════════════════════════════════════╝"
echo

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed. Please install it first."
    exit 1
fi

# Get current user
CURRENT_USER=$(gcloud config get-value account 2>/dev/null)
if [ -z "$CURRENT_USER" ]; then
    echo "❌ Not logged in to GCP. Running 'gcloud auth login'..."
    gcloud auth login
fi

echo "👤 Logged in as: $CURRENT_USER"
echo

# Project selection
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [ -n "$CURRENT_PROJECT" ]; then
    echo "Current project: $CURRENT_PROJECT"
    read -p "Use this project? (Y/n): " USE_CURRENT
    if [[ ! "$USE_CURRENT" =~ ^[Nn]$ ]]; then
        PROJECT_ID=$CURRENT_PROJECT
    fi
fi

if [ -z "$PROJECT_ID" ]; then
    # List available projects
    echo "Available projects:"
    gcloud projects list --format="table(projectId,name)"
    echo
    read -p "Enter the Project ID: " PROJECT_ID
    gcloud config set project $PROJECT_ID
fi

echo
echo "📋 Using Project: $PROJECT_ID"
echo

# Prompt for required parameters
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Please enter your Clooud credentials"
echo "You can find these in your Clooud dashboard"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

read -p "Clooud Team ID: " TEAM_ID
while [ -z "$TEAM_ID" ]; do
    echo "❌ Team ID cannot be empty"
    read -p "Clooud Team ID: " TEAM_ID
done

read -p "Clooud User ID: " USER_ID
while [ -z "$USER_ID" ]; do
    echo "❌ User ID cannot be empty"
    read -p "Clooud User ID: " USER_ID
done

WEBHOOK_URL="https://api.clooud.com/api/webhooks/gcp/alarm"
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
EOF

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Preparing your GCP project..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Enabling required APIs..."

# Enable APIs one by one with progress
apis=(
    "deploymentmanager.googleapis.com"
    "monitoring.googleapis.com"  
    "pubsub.googleapis.com"
    "iam.googleapis.com"
    "cloudresourcemanager.googleapis.com"
)

for api in "${apis[@]}"; do
    echo -n "  - Enabling $api... "
    if gcloud services enable $api --quiet 2>/dev/null; then
        echo "✓"
    else
        echo "⚠️  (may already be enabled)"
    fi
done

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Deploying Clooud monitoring integration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if gcloud deployment-manager deployments create ${DEPLOYMENT_NAME} --config deployment-config.yaml --quiet; then
    echo
    echo "✅ SUCCESS! Deployment completed."
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 What was created:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ Service Account: clooud-monitoring-${TEAM_ID}@${PROJECT_ID}.iam.gserviceaccount.com"
    echo "✓ Pub/Sub Topic: ${DEPLOYMENT_NAME}-clooud-alarms"  
    echo "✓ Webhook Subscription: ${DEPLOYMENT_NAME}-webhook-push"
    echo "✓ Notification Channel: Clooud Monitoring Notifications"
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 Next Steps:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. Go to Cloud Monitoring: https://console.cloud.google.com/monitoring/alerting/policies?project=${PROJECT_ID}"
    echo "2. Create or edit an alerting policy"
    echo "3. In 'Notifications', add 'Clooud Monitoring Notifications'"
    echo "4. Save your policy"
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