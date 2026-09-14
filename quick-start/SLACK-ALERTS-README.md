# Slack Alerts - Setup Guide

Get Slack notifications for errors and alerts from your monitoring stack.

> **Note:** Slack alerting is **not enabled by default**. The monitoring stack starts
> cleanly without it. Alert rules are pre-configured and evaluate automatically —
> this guide adds Slack as the notification channel.

## Quick Start (Script)

### Linux/macOS
```bash
cd server
./setup/setup-slack-alerts.sh
```

### Windows
```batch
cd server
setup\setup-slack-alerts.bat
```

The script will:
1. Ask for your Slack webhook URL
2. Create the `.env` file with your config
3. Copy Slack alerting configs into Grafana provisioning
4. Restart Grafana

---

## Manual Setup

### Step 1: Create a Slack Webhook

1. Go to https://api.slack.com/apps
2. **Create New App** > **From scratch**
3. Name: `Monitoring Alerts`, select your workspace
4. Go to **Incoming Webhooks** > Toggle **ON**
5. Click **Add New Webhook to Workspace**
6. Select channel (e.g., `#monitoring-alerts`)
7. Copy the webhook URL

### Step 2: Configure Environment

```bash
cd server

# Create .env from template
cp .env.example .env
```

Edit `.env` and set your webhook URLs:

```env
# Required
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Optional: separate channel for critical alerts (defaults to same as above)
SLACK_WEBHOOK_URL_CRITICAL=https://hooks.slack.com/services/YOUR/CRITICAL/WEBHOOK
```

### Step 3: Enable Slack Provisioning

Copy the alerting templates into Grafana's provisioning directory:

```bash
cd server

# Copy contact point and notification policy configs
cp setup/alerting-templates/slack-contact-point.yaml \
   stack/grafana/provisioning/alerting/slack-contact-point.yaml

cp setup/alerting-templates/notification-policies.yaml \
   stack/grafana/provisioning/alerting/notification-policies.yaml
```

### Step 4: Restart Grafana

```bash
cd server
docker-compose restart grafana
```

### Step 5: Verify

1. Open Grafana: http://localhost:3002 (admin/admin)
2. Go to **Alerting** > **Contact points**
3. Find `slack-errors` and click **Test**
4. Check your Slack channel for the test message

---

## Alternative: Configure via Grafana UI

If you prefer not to use provisioning files, you can set up Slack entirely through the Grafana UI:

1. Open Grafana: http://localhost:3002
2. Go to **Alerting** > **Contact points**
3. Click **Add contact point**
4. Name: `slack-errors`
5. Integration: **Slack**
6. Webhook URL: paste your Slack webhook URL
7. Click **Test** to verify, then **Save**
8. Go to **Alerting** > **Notification policies**
9. Edit the default policy > set **Default contact point** to `slack-errors`
10. Save

---

## Pre-Configured Alert Rules

These alert rules are active by default and evaluate automatically.
Without Slack configured, they fire to Grafana's built-in default contact point (no-op).

| Alert | Trigger | Severity |
|-------|---------|----------|
| **High Error Rate** | > 5 errors/sec for 2 min | Warning |
| **Critical Error Pattern** | > 10 exceptions in 5 min | Critical |
| **Database Errors** | > 5 DB errors in 5 min | Critical |
| **Startup Failures** | > 1 startup failure | Critical |
| **Log Volume Spike** | > 100 logs/sec for 3 min | Warning |
| **Slow Responses** | > 10 slow requests in 5 min | Warning |

## Alert Severity Routing

Once Slack is configured, alerts route by severity:

| Severity | Contact Point | Mention | Repeat Interval |
|----------|---------------|---------|-----------------|
| Critical | slack-critical | @channel | 30 minutes |
| Error/Warning | slack-errors | @here | 1 hour |

## Testing Alerts

### Test Contact Point (UI)

```
Grafana > Alerting > Contact points > slack-errors > Test
```

### Test Webhook Directly

```bash
curl -X POST YOUR_SLACK_WEBHOOK_URL \
  -H 'Content-Type: application/json' \
  -d '{"text":"Test from monitoring stack"}'
```

### Generate Test Error Logs

```bash
# Send test error logs to Loki to trigger alert rules
for i in $(seq 1 10); do
  curl -X POST http://localhost:3100/loki/api/v1/push \
    -H "Content-Type: application/json" \
    -d '{
      "streams": [{
        "stream": {"service_name": "test-app", "severity": "ERROR"},
        "values": [["'$(date +%s)000000000'", "{\"body\":\"Test error '$i'\",\"severity\":\"ERROR\"}"]]
      }]
    }'
  sleep 1
done
```

## Customization

### Change Alert Thresholds

Edit `stack/grafana/provisioning/alerting/alert-rules.yaml`:

```yaml
- evaluator:
    params:
      - 10  # Change threshold (e.g., from 5 to 10 errors/sec)
    type: gt
```

Then restart Grafana: `docker-compose restart grafana`

### Customize Slack Message Format

Edit `stack/grafana/provisioning/alerting/slack-contact-point.yaml`
(only after Slack is enabled):

```yaml
settings:
  title: |
    Custom Alert Title: {{ .GroupLabels.alertname }}
  text: |
    *Service:* {{ .Labels.service_name }}
    *Description:* {{ .Annotations.description }}
  icon_emoji: ':bell:'
  username: My Alert Bot
```

### Disable Slack Alerting

To revert to default (no Slack notifications):

```bash
cd server

# Restore empty configs
cat > stack/grafana/provisioning/alerting/slack-contact-point.yaml << 'EOF'
apiVersion: 1
contactPoints: []
EOF

cat > stack/grafana/provisioning/alerting/notification-policies.yaml << 'EOF'
apiVersion: 1
policies: []
EOF

docker-compose restart grafana
```

## Troubleshooting

### Grafana won't start after enabling Slack

Check that `.env` has valid webhook URLs:
```bash
cat .env | grep SLACK_WEBHOOK_URL
# Should show: SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
```

If URLs are missing, restore the empty configs:
```bash
cd server
cp setup/alerting-templates/slack-contact-point.yaml \
   stack/grafana/provisioning/alerting/slack-contact-point.yaml
# Then edit .env and fix the webhook URL
```

### No Slack Messages

1. Verify webhook: `curl -X POST YOUR_URL -d '{"text":"test"}'`
2. Check Grafana logs: `docker-compose logs grafana | grep -i slack`
3. Test via UI: Grafana > Alerting > Contact points > Test

### Alerts Not Firing

1. Check alert rules: Grafana > Alerting > Alert rules
2. Verify Loki has data: Grafana > Explore > Loki > `{service_name=~".+"}`
3. Test LogQL: `{service_name=~".+"} | json | severity="ERROR"`

## File Reference

```
server/
  .env.example                                    # Environment template
  .env                                            # Your config (created by setup)
  setup/
    setup-slack-alerts.sh                         # Setup script (Linux/macOS)
    setup-slack-alerts.bat                        # Setup script (Windows)
    alerting-templates/
      slack-contact-point.yaml                    # Slack config template
      notification-policies.yaml                  # Routing config template
  stack/grafana/provisioning/alerting/
    alert-rules.yaml                              # Alert rules (always active)
    slack-contact-point.yaml                      # Empty until Slack is enabled
    notification-policies.yaml                    # Empty until Slack is enabled
```
