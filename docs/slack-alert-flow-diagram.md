# Slack Alert Flow Diagram

Visual representation of how error logs become Slack notifications.

## High-Level Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                     Your Application                           │
│                                                                │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────────┐     │
│  │   Service A  │    │   Service B  │    │   Service C   │     │
│  │  (hrms-uat)  │    │  (hrms-prod) │    │  (api-gateway)│     │
│  └──────┬───────┘    └──────┬───────┘    └────────┬──────┘     │
│         │                    │                    │            │
│         └────────────────────┼────────────────────┘            │
│                              │                                 │
│                    (OTLP - OpenTelemetry)                      │
└──────────────────────────────┼─────────────────────────────────┘
                               │
                               ▼
                    ┌─────────────────┐
                    │  Grafana Alloy  │
                    │  (Collector)    │
                    └────────┬────────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
         ┌──────▼────┐  ┌───▼───┐  ┌───▼────┐
         │Prometheus │  │  Loki  │  │ Tempo  │
         │ (Metrics) │  │ (Logs) │  │(Traces)│
         └───────────┘  └───┬────┘  └────────┘
                            │
                            │ Logs Stored
                            │
                    ┌───────▼────────┐
                    │    Grafana     │
                    │   Alerting     │
                    └───────┬────────┘
                            │
                ┌───────────┼──────────┐
                │           │          │
        ┌───────▼──────┐    │   ┌─────▼────────┐
        │ Alert Rules  │    │   │Contact Points│
        │  (LogQL)     │    │   │   (Slack)    │
        └───────┬──────┘    │   └──────────────┘
                │           │
                │    ┌──────▼──────┐
                └───►│Notification │
                     │  Policies   │
                     └──────┬──────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ Slack Channel│
                    │ 🔔 #alerts   │
                    └──────────────┘
```

## Detailed Alert Processing Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: Error Occurs in Application                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Application Code:                                              │
│  ┌──────────────────────────────────────────────────┐          │
│  │ try {                                             │          │
│  │   database.connect()                              │          │
│  │ } catch (error) {                                 │          │
│  │   logger.error("Database connection failed")      │          │
│  │ }                                                 │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                 │
│  Log Output (JSON):                                             │
│  {                                                              │
│    "severity": "ERROR",                                         │
│    "service_name": "hrms-backend-uat",                          │
│    "service_namespace": "hrms",                                 │
│    "traceid": "86b33d66bc28f7b4f6d2916369f014f5",              │
│    "body": "Database connection failed",                        │
│    "timestamp": "2026-01-30T15:30:45.123Z"                     │
│  }                                                              │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 2: Log Ingested into Loki                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Alloy forwards log to Loki                                     │
│  Loki stores with labels:                                       │
│  - service_name="hrms-backend-uat"                              │
│  - service_namespace="hrms"                                     │
│  - severity="ERROR"                                             │
│                                                                 │
│  Indexed and ready for querying                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 3: Alert Rule Evaluates (Every 1 Minute)                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Alert Rule: "High Error Rate"                                  │
│  ┌──────────────────────────────────────────────────┐          │
│  │ LogQL Query:                                      │          │
│  │ sum(rate({service_name=~".+"}                     │          │
│  │   | json                                          │          │
│  │   | severity="ERROR" [5m]))                       │          │
│  │   by (service_name, service_namespace)            │          │
│  │                                                   │          │
│  │ Threshold: > 5 errors/second                      │          │
│  │ For Duration: 2 minutes                           │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                 │
│  Current Value: 12.5 errors/sec ✅ EXCEEDS THRESHOLD            │
│  Duration Met: 2 minutes ✅                                     │
│                                                                 │
│  🚨 ALERT FIRES! 🚨                                             │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 4: Notification Policy Routes Alert                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Alert Labels:                                                  │
│  - alertname="High Error Rate"                                  │
│  - severity="warning"                                           │
│  - service_name="hrms-backend-uat"                              │
│  - service_namespace="hrms"                                     │
│                                                                 │
│  Routing Decision:                                              │
│  ┌─────────────────────────────────────────┐                   │
│  │ IF severity == "critical"                │                   │
│  │   → slack-critical                       │                   │
│  │ ELSE IF severity == "warning|error"      │                   │
│  │   → slack-errors  ✅ MATCHED             │                   │
│  │ ELSE                                     │                   │
│  │   → slack-errors (default)               │                   │
│  └─────────────────────────────────────────┘                   │
│                                                                 │
│  Grouping: By alertname + service_name                          │
│  Wait: 10 seconds (for more similar alerts)                     │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 5: Contact Point Formats Message                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Contact Point: "slack-errors"                                  │
│  Template Processing:                                           │
│                                                                 │
│  Title:                                                         │
│  🔥 ALERT: {{ .GroupLabels.alertname }}                        │
│  → "🔥 ALERT: High Error Rate"                                 │
│                                                                 │
│  Text:                                                          │
│  *Service:* {{ .Labels.service_name }}                          │
│  *Severity:* {{ .Labels.severity }}                             │
│  *Description:* {{ .Annotations.description }}                  │
│  *Dashboard:* {{ .DashboardURL }}                               │
│                                                                 │
│  → Formatted Slack message ready                                │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 6: Message Sent to Slack                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  HTTP POST to Slack Webhook:                                    │
│  https://hooks.slack.com/services/XXX/YYY/ZZZ                   │
│                                                                 │
│  Payload:                                                       │
│  {                                                              │
│    "username": "Grafana Monitoring",                            │
│    "icon_emoji": ":fire:",                                      │
│    "text": "🔥 ALERT: High Error Rate",                        │
│    "blocks": [                                                  │
│      {                                                          │
│        "type": "section",                                       │
│        "text": "Service: hrms-backend-uat..."                   │
│      }                                                          │
│    ]                                                            │
│  }                                                              │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 7: Team Notified in Slack                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Slack Channel: #monitoring-alerts                              │
│  ┌───────────────────────────────────────────────────┐         │
│  │ 🔥 ALERT: High Error Rate Detected                │         │
│  │                                                    │         │
│  │ *Alert:* High Error Rate Detected                 │         │
│  │ *Severity:* warning                                │         │
│  │ *Service:* hrms-backend-uat                        │         │
│  │ *Namespace:* hrms                                  │         │
│  │ *Status:* firing                                   │         │
│  │                                                    │         │
│  │ *Description:* Service hrms-backend-uat in         │         │
│  │ namespace hrms is experiencing high error rate:    │         │
│  │ 12.5 errors/sec                                    │         │
│  │                                                    │         │
│  │ *Dashboard:* [View in Grafana]                     │         │
│  │ *Time:* 2026-01-30 15:30:45                       │         │
│  │                                                    │         │
│  │ @here                                              │         │
│  └───────────────────────────────────────────────────┘         │
│                                                                 │
│  📱 Team members receive notification                           │
│  🔍 Team investigates using Grafana dashboard                   │
│  🔧 Team resolves issue                                         │
└─────────────────────────────────────────────────────────────────┘
```

## Alert Rule Evaluation Cycle

```
┌─────────────────────────────────────────────┐
│        Grafana Alert Scheduler              │
│     (Runs every 1 minute by default)        │
└────────────────┬────────────────────────────┘
                 │
                 ├─ Evaluation 1 (15:30:00)
                 │  Query Loki → 3 errors/sec
                 │  Threshold: 5
                 │  Status: OK ✅
                 │
                 ├─ Evaluation 2 (15:31:00)
                 │  Query Loki → 7 errors/sec
                 │  Threshold: 5
                 │  Status: PENDING ⏳ (start timer)
                 │
                 ├─ Evaluation 3 (15:32:00)
                 │  Query Loki → 12 errors/sec
                 │  Threshold: 5
                 │  Duration: 1 min (need 2 min)
                 │  Status: PENDING ⏳
                 │
                 ├─ Evaluation 4 (15:33:00)
                 │  Query Loki → 11 errors/sec
                 │  Threshold: 5
                 │  Duration: 2 min ✅
                 │  Status: FIRING 🚨
                 │  → Send to Notification Policy
                 │
                 ├─ Evaluation 5 (15:34:00)
                 │  Query Loki → 8 errors/sec
                 │  Still firing
                 │  Status: FIRING 🚨
                 │  → Suppress (repeat_interval not met)
                 │
                 └─ Evaluation 6 (15:35:00)
                    Query Loki → 2 errors/sec
                    Below threshold
                    Status: RESOLVED ✅
                    → Send RESOLVED message to Slack
```

## Message Grouping Example

```
Multiple alerts firing simultaneously:

Alert 1: High Error Rate (hrms-backend-uat)
Alert 2: High Error Rate (hrms-backend-prod)
Alert 3: Database Errors (hrms-backend-uat)

┌─────────────────────────────────────────┐
│      Notification Policy Groups         │
├─────────────────────────────────────────┤
│                                         │
│ Group 1 (by alertname + service):       │
│  - High Error Rate (hrms-backend-uat)   │
│                                         │
│ Group 2 (by alertname + service):       │
│  - High Error Rate (hrms-backend-prod)  │
│                                         │
│ Group 3 (by alertname + service):       │
│  - Database Errors (hrms-backend-uat)   │
│                                         │
└─────────────────────────────────────────┘
          │                │                │
          ▼                ▼                ▼
    ┌─────────┐      ┌─────────┐      ┌─────────┐
    │Message 1│      │Message 2│      │Message 3│
    └────┬────┘      └────┬────┘      └────┬────┘
         └────────────────┼────────────────┘
                          ▼
              ┌────────────────────┐
              │   Slack Channel    │
              │                    │
              │  📨 Message 1      │
              │  📨 Message 2      │
              │  📨 Message 3      │
              └────────────────────┘

Result: 3 separate Slack messages
(instead of potentially 3+ if not grouped)
```

## Silencing Flow

```
┌────────────────────────────────────┐
│ Admin Creates Silence Rule         │
│                                    │
│ Matchers:                          │
│  service_name = "maintenance-app"  │
│ Duration: 2 hours                  │
└────────────────┬───────────────────┘
                 │
                 ▼
┌────────────────────────────────────┐
│  Alert Fires                       │
│  Labels:                           │
│   - service_name: "maintenance-app"│
└────────────────┬───────────────────┘
                 │
                 ▼
┌────────────────────────────────────┐
│  Notification Policy Checks        │
│                                    │
│  1. Match routing rules ✅         │
│  2. Check silences ⚠️              │
│     → MATCHED silence rule         │
│  3. SUPPRESS notification 🔇       │
└────────────────────────────────────┘

Result: No Slack message sent
```

## Time-based Flow (Complete Lifecycle)

```
Timeline:

15:30:00 │ ERROR logs start appearing
         │ Rate: 7/sec
         │
15:30:30 │ Alert rule evaluates
         │ Status: PENDING (start timer)
         │
15:31:00 │ Error rate increases: 12/sec
         │
15:31:30 │ Alert rule evaluates again
         │ Status: PENDING (1 min elapsed)
         │
15:32:00 │ Error rate: 15/sec
         │
15:32:30 │ Alert rule evaluates
         │ Duration met: 2 minutes
         │ Status: FIRING 🚨
         │
15:32:35 │ Notification grouped (10 sec wait)
         │
15:32:45 │ 🔔 Slack message sent!
         │ Team notified
         │
15:35:00 │ Engineers deploy fix
         │ Error rate drops to 1/sec
         │
15:36:30 │ Alert rule evaluates
         │ Below threshold
         │ Status: RESOLVED ✅
         │
15:36:35 │ ✅ Slack RESOLVED message sent
         │ "Alert is now resolved"
         │
```

## Component Responsibilities

```
┌──────────────────────────────────────────────────┐
│ Loki                                             │
│ • Store logs                                     │
│ • Index by labels                                │
│ • Provide LogQL query interface                  │
│ • Retain for configured period                   │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│ Grafana Alert Rules                              │
│ • Execute LogQL queries                          │
│ • Evaluate thresholds                            │
│ • Track duration ("for" clause)                  │
│ • Determine alert state (OK/PENDING/FIRING)      │
│ • Add annotations and labels                     │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│ Notification Policies                            │
│ • Route alerts to contact points                 │
│ • Group similar alerts                           │
│ • Apply wait times                               │
│ • Check silences                                 │
│ • Control repeat intervals                       │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│ Contact Points (Slack)                           │
│ • Format messages using templates                │
│ • Send HTTP requests to Slack webhook            │
│ • Handle retries on failure                      │
│ • Track delivery status                          │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│ Slack                                            │
│ • Receive webhook POST                           │
│ • Display formatted message                      │
│ • Send push notifications to team               │
│ • Provide threading and reactions               │
└──────────────────────────────────────────────────┘
```

## Data Flow (Technical Details)

```
1. Log Entry:
   {"severity":"ERROR","service_name":"hrms-backend-uat",...}
          ↓
2. Loki Storage:
   /loki/chunks/{stream_hash}/{chunk_id}
   Index: service_name="hrms-backend-uat"
          ↓
3. Alert Query (every 60s):
   POST /loki/api/v1/query_range
   LogQL: sum(rate({service_name=~".+"}|json|severity="ERROR"[5m]))
          ↓
4. Query Result:
   {"status":"success","data":{"result":[{"value":[ts,12.5]}]}}
          ↓
5. Threshold Check:
   12.5 > 5 = true (for 2 minutes)
          ↓
6. Alert State Change:
   OK → PENDING → FIRING
          ↓
7. Notification:
   POST /alertmanager/api/v2/alerts
   Payload: [{labels:{...},annotations:{...}}]
          ↓
8. Routing:
   Match: severity="warning" → contact_point="slack-errors"
          ↓
9. Template Rendering:
   Title: "🔥 ALERT: High Error Rate"
   Text: "Service: hrms-backend-uat..."
          ↓
10. Webhook POST:
    POST https://hooks.slack.com/services/XXX/YYY/ZZZ
    Headers: {Content-Type: application/json}
    Body: {username:"...",text:"...",blocks:[...]}
          ↓
11. Slack Display:
    Message appears in #monitoring-alerts
    Push notifications sent to online users
```

---

This diagram shows the complete flow from application error to Slack notification, including all intermediate processing steps and decision points.
