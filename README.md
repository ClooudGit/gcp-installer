# Clooud GCP Monitoring Integration

One-click deployment for integrating Google Cloud Monitoring with Clooud.

## Quick Deploy

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/ClooudGit/gcp-monitoring-integration&cloudshell_print=instructions.txt&cloudshell_open_in_editor=deploy.sh)

## What This Does

This deployment creates:
- A service account for Clooud to access your monitoring data
- A Pub/Sub topic to receive monitoring alerts  
- A webhook subscription to forward alerts to Clooud
- A notification channel for Cloud Monitoring
- Necessary IAM permissions for read-only monitoring access

## Manual Installation

1. Clone this repository
2. Run `chmod +x deploy.sh`
3. Run `./deploy.sh`
4. Follow the prompts

## Required Information

- **Clooud Team ID**: Available in your Clooud dashboard
- **Clooud User ID**: Available in your Clooud dashboard

## After Deployment

1. Go to Cloud Monitoring in GCP Console
2. Create or edit an alerting policy
3. Add "Clooud Monitoring Notifications" as a notification channel
4. Save your policy

## Support

For help, visit [docs.clooud.com](https://docs.clooud.com) or contact support@clooud.com