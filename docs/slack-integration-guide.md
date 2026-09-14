# Slack Integration Guide - Error Log Notifications

Complete guide for setting up Slack notifications for error logs and alerts from your monitoring stack.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Slack Webhook Setup](#slack-webhook-setup)
- [Configuration](#configuration)
- [Alert Rules](#alert-rules)
- [Testing Alerts](#testing-alerts)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)

## Overview

This integration sends real-time Slack notifications when:
- ✅ High error rates are detected in application logs
- ✅ Critical error patterns appear (exceptions, panics, database errors)
- ✅ Database connection issues occur
- ✅ Application startup failures happen
- ✅ Unusual log volume spikes are detected
- ✅ Slow response times are identified

### Architecture

```
Application Logs → Loki → Grafana Alert Rules → Slack Webhook → Slack Channel
                             ↓
                    Prometheus Metrics → Alert Rules → Slack
```

## Prerequisites

- Grafana monitoring stack running
- Slack workspace with admin access
- Ability to create Slack Incoming Webhooks

## Quick Start

### 1. Create Slack Webhook

1. Go to https://api.slack.com/apps
2. Click **"Create New App"** → **"From scratch"**
3. Name your app (e.g., "Monitoring Alerts")
4. Select your workspace
5. Click **"Incoming Webhooks"** in the left sidebar
6. Toggle **"Activate Incoming Webhooks"** to ON
7. Click **"Add New Webhook to Workspace"**
8. Select the channel for alerts (e.g., #monitoring-alerts)
9. Click **"Allow"**
10. **Copy the Webhook URL** (looks like: `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX`)

### 2. Configure Environment Variables

Create a `.env` file in the monitoring directory:

```bash
cd /path/to/monitoring
cp .env.example .env
nano .env  # or use your preferred editor
```

Add your Slack webhook URL:

```env
# For error alerts
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# For critical alerts (optional - can use same URL)
SLACK_WEBHOOK_URL_CRITICAL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### 3. Restart Grafana

```bash
docker-compose restart grafana

# Or restart entire stack
docker-compose down
docker-compose up -d
```

### 4. Verify Alert Configuration

1. Open Grafana: http://localhost:3002
2. Login (admin/admin)
3. Navigate to **Alerting** → **Contact points**
4. Verify "slack-errors" and "slack-critical" appear
5. Click **"Test"** to send a test notification

## Slack Webhook Setup

### Detailed Steps

#### Create Slack App

1. **Navigate to Slack API**
   - Go to https://api.slack.com/apps
   - Sign in to your Slack workspace

2. **Create App**
   - Click "Create New App"
   - Choose "From scratch"
   - App Name: `Monitoring Alerts` (or your preference)
   - Workspace: Select your workspace
   - Click "Create App"

3. **Enable Incoming Webhooks**
   - In the left sidebar, click "Incoming Webhooks"
   - Toggle the switch to "On"
   - Scroll down and click "Add New Webhook to Workspace"

4. **Configure Webhook**
   - Select target channel (e.g., #monitoring-alerts)
   - Click "Allow"
   - **Copy the Webhook URL** - you'll need this!

#### Optional: Create Multiple Channels

For better alert organization, create separate webhooks:

- **#monitoring-errors** - Warning and error level alerts
- **#monitoring-critical** - Critical alerts requiring immediate attention
- **#monitoring-performance** - Performance degradation alerts

Create a webhook for each channel and configure them in `.env`:

```env
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/XXX/YYY/zzz  # errors
SLACK_WEBHOOK_URL_CRITICAL=https://hooks.slack.com/services/AAA/BBB/ccc  # critical
```

## Configuration

### Environment Variables

All configuration is done via the `.env` file:

```env
# Required
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Optional
SLACK_WEBHOOK_URL_CRITICAL=https://hooks.slack.com/services/YOUR/CRITICAL/WEBHOOK
GF_SERVER_ROOT_URL=http://localhost:3002
```

### Contact Points

Contact points are defined in `stack/grafana/provisioning/alerting/slack-contact-point.yaml`:

**Default Contact Points:**
1. **slack-errors** - For warning and error level alerts
2. **slack-critical** - For critical alerts

**Message Format:**
```
🔥 ALERT: High Error Rate Detected

Alert: High Error Rate Detected
Severity: warning
Service: hrms-backend-uat
Namespace: hrms
Status: firing

Description: Service hrms-backend-uat in namespace hrms is experiencing high error rate: 12.5 errors/sec

Dashboard: View in Grafana
Time: 2026-01-30 15:30:45
```

### Notification Policies

Routing rules are in `stack/grafana/provisioning/alerting/notification-policies.yaml`:

**Default Routing:**
- **Critical severity** → slack-critical (repeat every 30 min)
- **Error/Warning severity** → slack-errors (repeat every 1 hour)
- **All other alerts** → slack-errors (repeat every 3 hours)

**Grouping:**
Alerts are grouped by:
- `alertname`
- `service_name`
- `service_namespace`

This prevents notification spam when multiple instances fail simultaneously.

## Alert Rules

### Pre-configured Alert Rules

Located in `stack/grafana/provisioning/alerting/alert-rules.yaml`:

#### 1. High Error Rate
- **Trigger:** > 5 errors/second for 2 minutes
- **Severity:** Warning
- **Query:** `sum(rate({service_name=~".+"} | json | severity="ERROR" [5m]))`

#### 2. Critical Error Pattern
- **Trigger:** > 10 critical errors in 5 minutes
- **Severity:** Critical
- **Patterns:** exception, fatal, panic, out of memory, connection refused

#### 3. Database Errors
- **Trigger:** > 5 database errors in 5 minutes
- **Severity:** Critical
- **Patterns:** database error, connection timeout, SQL exception, deadlock

#### 4. Application Startup Failures
- **Trigger:** > 1 startup failure in 10 minutes
- **Severity:** Critical
- **Patterns:** failed to start, initialization error, bootstrap error

#### 5. Log Volume Spike
- **Trigger:** > 100 logs/second for 3 minutes
- **Severity:** Warning
- **Purpose:** Detect runaway logging or log storms

#### 6. Slow Response Times
- **Trigger:** > 10 slow requests in 5 minutes
- **Severity:** Warning
- **Patterns:** slow query, timeout, took XXXXms

### Alert Rule Structure

```yaml
- uid: unique_alert_id
  title: Alert Name
  condition: C  # Final threshold condition
  data:
    - refId: A  # LogQL query from Loki
      datasourceUid: P8E80F9AEF21F6940
      model:
        expr: |
          sum(rate({service_name=~".+"} | json | severity="ERROR" [5m]))
    - refId: B  # Reduce to single value
      datasourceUid: __expr__
      model:
        type: reduce
        expression: A
        reducer: last
    - refId: C  # Threshold check
      datasourceUid: __expr__
      model:
        type: threshold
        expression: B
        conditions:
          - evaluator:
              params: [5]  # Threshold value
              type: gt
  for: 2m  # Must be true for 2 minutes
  annotations:
    description: 'Error description with {{ $labels.service_name }}'
    summary: 'Alert summary'
  labels:
    severity: warning
```

## Testing Alerts

### Method 1: Grafana UI Test

1. Open Grafana → **Alerting** → **Contact points**
2. Find "slack-errors"
3. Click **"Test"** button
4. Check your Slack channel for test message

### Method 2: Trigger Real Alert

Generate errors in your application:

```bash
# Example: Generate ERROR logs
for i in {1..20}; do
  echo "Test ERROR message $(date)" | logger -t test-app -p user.error
  sleep 1
done
```

Or use curl to send logs to Loki directly:

```bash
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d '{
    "streams": [
      {
        "stream": {
          "service_name": "test-app",
          "severity": "ERROR"
        },
        "values": [
          ["'$(date +%s)000000000'", "Test error message for Slack alerting"]
        ]
      }
    ]
  }'
```

### Method 3: Manual Alert Test

1. Go to **Alerting** → **Alert rules**
2. Find an alert rule (e.g., "High Error Rate")
3. Click the alert name
4. Click **"Evaluate"** button
5. If conditions match, it will trigger

## Customization

### Modify Alert Thresholds

Edit `stack/grafana/provisioning/alerting/alert-rules.yaml`:

```yaml
# Change error rate threshold from 5 to 10
- evaluator:
    params:
      - 10  # Changed from 5
    type: gt
```

### Add Custom Alert Rules

Create a new rule in `alert-rules.yaml`:

```yaml
- uid: custom_alert
  title: Custom Error Pattern
  condition: C
  data:
    - refId: A
      datasourceUid: P8E80F9AEF21F6940
      model:
        expr: |
          count_over_time({service_name="my-app"}
            | json
            | body =~ "CustomErrorPattern" [5m])
    - refId: B
      datasourceUid: __expr__
      model:
        type: reduce
        expression: A
        reducer: last
    - refId: C
      datasourceUid: __expr__
      model:
        type: threshold
        expression: B
        conditions:
          - evaluator:
              params: [1]
              type: gt
  for: 1m
  annotations:
    description: 'Custom error detected'
  labels:
    severity: warning
```

### Customize Slack Message Format

Edit `stack/grafana/provisioning/alerting/slack-contact-point.yaml`:

```yaml
title: |
  🔔 {{ .GroupLabels.alertname }}

text: |
  *Service:* {{ .Labels.service_name }}
  *Message:* {{ .Annotations.description }}
  *Custom Field:* {{ .Labels.custom_label }}
```

**Available Variables:**
- `{{ .Status }}` - firing or resolved
- `{{ .GroupLabels.alertname }}` - Alert name
- `{{ .Labels.service_name }}` - Service name
- `{{ .Labels.severity }}` - Severity level
- `{{ .Annotations.description }}` - Description text
- `{{ .StartsAt }}` - Alert start time
- `{{ .DashboardURL }}` - Link to dashboard

### Add Mentions for Critical Alerts

Edit the critical contact point:

```yaml
settings:
  mention_channel: 'channel'  # @channel
  mention_users: 'U01234567,U89012345'  # Specific users
  mention_groups: 'S01234567'  # User groups
```

## Troubleshooting

### Alerts Not Firing

**Check Alert Rules Status:**
```bash
# View Grafana logs
docker logs grafana | grep -i alert

# Check alert evaluation
curl -u admin:admin http://localhost:3002/api/alertmanager/grafana/api/v2/alerts
```

**Common Issues:**
1. **Loki datasource UID mismatch**
   - Go to Settings → Data Sources → Loki
   - Copy the UID
   - Update `datasourceUid` in alert-rules.yaml

2. **Alert evaluation disabled**
   - Check `GF_ALERTING_ENABLED=true` in docker-compose.yml
   - Restart Grafana

3. **Query returns no data**
   - Test query in Explore view
   - Verify logs are reaching Loki
   - Check label matchers

### Slack Messages Not Sending

**Verify Webhook URL:**
```bash
# Test webhook directly
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H 'Content-Type: application/json' \
  -d '{"text":"Test message from monitoring stack"}'
```

**Check Grafana Configuration:**
1. Go to Alerting → Contact points
2. Click "slack-errors"
3. Click "Test" button
4. Check for error messages

**Common Issues:**
1. **Invalid webhook URL**
   - Verify URL in `.env` file
   - Ensure no extra spaces or quotes
   - Restart Grafana after changing

2. **Webhook expired/revoked**
   - Regenerate webhook in Slack
   - Update `.env` file

3. **Network issues**
   - Check Grafana can reach internet
   - Verify no firewall blocking outbound HTTPS

### Environment Variables Not Loading

```bash
# Check if .env file exists
ls -la .env

# Verify variables are loaded
docker exec grafana env | grep SLACK

# Restart with explicit env file
docker-compose --env-file .env up -d
```

### Alert Spam (Too Many Notifications)

**Increase repeat interval:**

Edit `notification-policies.yaml`:
```yaml
repeat_interval: 6h  # Changed from 1h
```

**Adjust grouping:**
```yaml
group_by: ['alertname', 'service_name']
group_interval: 10m  # Group alerts for 10 minutes
```

## Best Practices

### 1. Alert Severity Levels

Use appropriate severity:
- **Critical**: Requires immediate action (page on-call)
- **Warning**: Needs attention within business hours
- **Info**: FYI, no action needed

### 2. Alert Fatigue Prevention

- Set reasonable thresholds
- Use `for` duration to avoid flapping
- Group related alerts
- Use long repeat intervals for non-critical alerts

### 3. Runbook Links

Always include runbook URLs in alerts:
```yaml
annotations:
  runbook_url: 'https://wiki.company.com/runbooks/high-error-rate'
```

### 4. Testing

- Test alerts in development first
- Use separate Slack channels for dev/staging/prod
- Regularly review and tune thresholds

### 5. Documentation

Document:
- What each alert means
- How to investigate
- Who to contact
- Resolution steps

## Advanced Configuration

### Multiple Slack Workspaces

Create separate contact points for different teams:

```yaml
contactPoints:
  - name: slack-backend-team
    receivers:
      - type: slack
        settings:
          url: ${SLACK_WEBHOOK_BACKEND}

  - name: slack-devops-team
    receivers:
      - type: slack
        settings:
          url: ${SLACK_WEBHOOK_DEVOPS}
```

### Environment-Specific Routing

Route alerts based on environment:

```yaml
routes:
  - receiver: slack-production
    matchers:
      - deployment_environment_name = production

  - receiver: slack-staging
    matchers:
      - deployment_environment_name = staging
```

### Silence Rules

Temporarily silence alerts:

```bash
# Via Grafana UI
Alerting → Silences → New Silence

# Match specific labels
service_name = "maintenance-service"
```

## Metrics & Monitoring

Track alerting system health:

```promql
# Alert evaluation time
grafana_alerting_rule_evaluation_duration_seconds

# Alert delivery success
grafana_alerting_notifications_sent_total

# Failed notifications
grafana_alerting_notifications_failed_total
```

## References

- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks)
- [Grafana Alerting Docs](https://grafana.com/docs/grafana/latest/alerting/)
- [LogQL for Alerting](https://grafana.com/docs/loki/latest/logql/)
- [Alert Rule Examples](https://grafana.com/docs/grafana/latest/alerting/alerting-rules/)

## Support

For issues:
1. Check Grafana logs: `docker logs grafana`
2. Verify alert rules: Grafana → Alerting → Alert rules
3. Test contact points: Grafana → Alerting → Contact points → Test
4. Review this guide's troubleshooting section
