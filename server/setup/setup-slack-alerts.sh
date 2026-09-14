#!/bin/bash

# Slack Alerts Setup Script
# Interactive setup for Slack webhook integration

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Resolve paths relative to the server/ directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/alerting-templates"
PROVISIONING_DIR="$SERVER_DIR/stack/grafana/provisioning/alerting"

echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}   Slack Alerts Setup for Monitoring Stack${NC}"
echo -e "${BOLD}================================================${NC}"
echo ""

# Verify templates exist
if [ ! -f "$TEMPLATES_DIR/slack-contact-point.yaml" ]; then
    echo -e "${RED}Error: Template files not found in $TEMPLATES_DIR${NC}"
    echo "Expected: slack-contact-point.yaml and notification-policies.yaml"
    exit 1
fi

# Check if .env exists
cd "$SERVER_DIR"
if [ -f ".env" ]; then
    echo -e "${YELLOW}! .env file already exists${NC}"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
    cp .env ".env.backup.$(date +%s)"
    echo -e "${GREEN}+${NC} Backed up existing .env file"
fi

# Create .env from template
if [ -f ".env.example" ]; then
    cp .env.example .env
    echo -e "${GREEN}+${NC} Created .env file from template"
else
    echo -e "${YELLOW}!${NC} .env.example not found, creating new .env"
    touch .env
fi

echo ""
echo -e "${BOLD}Step 1: Slack Webhook Setup${NC}"
echo "-----------------------------------"
echo ""
echo "To get your Slack webhook URL:"
echo "  1. Go to https://api.slack.com/apps"
echo "  2. Click 'Create New App' -> 'From scratch'"
echo "  3. Name it 'Monitoring Alerts' and select your workspace"
echo "  4. Click 'Incoming Webhooks' and toggle it ON"
echo "  5. Click 'Add New Webhook to Workspace'"
echo "  6. Select your alert channel (e.g., #monitoring-alerts)"
echo "  7. Copy the webhook URL"
echo ""

read -p "Press Enter when you have your webhook URL ready..."

echo ""
read -p "Paste your Slack webhook URL for error alerts: " WEBHOOK_URL

if [ -z "$WEBHOOK_URL" ]; then
    echo -e "${RED}Error: Webhook URL is required for Slack alerting.${NC}"
    echo "You can set SLACK_WEBHOOK_URL manually in .env and re-run this script."
    exit 1
fi

# Update SLACK_WEBHOOK_URL
if grep -q "^SLACK_WEBHOOK_URL=" .env; then
    sed -i.bak "s|^SLACK_WEBHOOK_URL=.*|SLACK_WEBHOOK_URL=$WEBHOOK_URL|" .env
else
    echo "SLACK_WEBHOOK_URL=$WEBHOOK_URL" >> .env
fi
echo -e "${GREEN}+${NC} Webhook URL configured"

echo ""
read -p "Do you want a separate webhook for CRITICAL alerts? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Paste your Slack webhook URL for critical alerts: " CRITICAL_WEBHOOK_URL
    if [ ! -z "$CRITICAL_WEBHOOK_URL" ]; then
        if grep -q "^SLACK_WEBHOOK_URL_CRITICAL=" .env; then
            sed -i.bak "s|^SLACK_WEBHOOK_URL_CRITICAL=.*|SLACK_WEBHOOK_URL_CRITICAL=$CRITICAL_WEBHOOK_URL|" .env
        else
            echo "SLACK_WEBHOOK_URL_CRITICAL=$CRITICAL_WEBHOOK_URL" >> .env
        fi
        echo -e "${GREEN}+${NC} Critical webhook URL configured"
    fi
else
    # Use same webhook for critical
    if grep -q "^SLACK_WEBHOOK_URL_CRITICAL=" .env; then
        sed -i.bak "s|^SLACK_WEBHOOK_URL_CRITICAL=.*|SLACK_WEBHOOK_URL_CRITICAL=$WEBHOOK_URL|" .env
    else
        echo "SLACK_WEBHOOK_URL_CRITICAL=$WEBHOOK_URL" >> .env
    fi
fi

echo ""
echo -e "${BOLD}Step 2: Optional Configuration${NC}"
echo "-----------------------------------"
echo ""

read -p "Set Grafana admin password (default: admin): " ADMIN_PASS
if [ ! -z "$ADMIN_PASS" ]; then
    if grep -q "^GF_SECURITY_ADMIN_PASSWORD=" .env; then
        sed -i.bak "s|^GF_SECURITY_ADMIN_PASSWORD=.*|GF_SECURITY_ADMIN_PASSWORD=$ADMIN_PASS|" .env
    else
        echo "GF_SECURITY_ADMIN_PASSWORD=$ADMIN_PASS" >> .env
    fi
fi

read -p "Set Grafana server URL (default: http://localhost:3002): " SERVER_URL
if [ ! -z "$SERVER_URL" ]; then
    if grep -q "^GF_SERVER_ROOT_URL=" .env; then
        sed -i.bak "s|^GF_SERVER_ROOT_URL=.*|GF_SERVER_ROOT_URL=$SERVER_URL|" .env
    else
        echo "GF_SERVER_ROOT_URL=$SERVER_URL" >> .env
    fi
fi

echo ""
echo -e "${BOLD}Step 3: Install Slack Alerting Config${NC}"
echo "-----------------------------------"
echo ""

# Copy templates to provisioning directory
cp "$TEMPLATES_DIR/slack-contact-point.yaml" "$PROVISIONING_DIR/slack-contact-point.yaml"
cp "$TEMPLATES_DIR/notification-policies.yaml" "$PROVISIONING_DIR/notification-policies.yaml"
echo -e "${GREEN}+${NC} Copied Slack contact point config to provisioning"
echo -e "${GREEN}+${NC} Copied notification policies to provisioning"

echo ""
echo -e "${BOLD}Step 4: Verify Configuration${NC}"
echo "-----------------------------------"
echo ""
echo "Your .env file contains:"
grep -E "^(SLACK_WEBHOOK_URL|GF_)" .env | sed 's/=.*/=***REDACTED***/' || echo "No configuration found"

echo ""
echo -e "${BOLD}Step 5: Restart Grafana${NC}"
echo "-----------------------------------"
echo ""

read -p "Do you want to restart Grafana now? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "Restarting Grafana..."
    docker-compose restart grafana

    echo ""
    echo "Waiting for Grafana to start..."
    sleep 5

    if docker ps | grep -q grafana; then
        echo -e "${GREEN}+${NC} Grafana restarted successfully"
    else
        echo -e "${YELLOW}!${NC} Grafana may not be running. Check with: docker-compose logs grafana"
    fi
fi

echo ""
echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}   Setup Complete!${NC}"
echo -e "${BOLD}================================================${NC}"
echo ""
echo -e "${GREEN}+${NC} Slack webhook configured"
echo -e "${GREEN}+${NC} Alerting config provisioned"
echo -e "${GREEN}+${NC} Notification policies provisioned"
echo ""
echo "Next steps:"
echo "  1. Open Grafana: http://localhost:3002"
echo "  2. Go to Alerting -> Contact points"
echo "  3. Find 'slack-errors' and click 'Test' to verify"
echo "  4. Check your Slack channel for the test message"
echo ""
echo "To disable Slack alerting later, re-run or see:"
echo "  quick-start/SLACK-ALERTS-README.md"
echo ""
