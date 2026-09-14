#!/bin/sh
# check-telemetry-invariants.sh - assert HRMS telemetry pipeline invariants.
#
# Usage:
#   ./check-telemetry-invariants.sh [uat|uat-indo|testing|prod|all]
#   PROM_URL=http://host:9090 LOKI_URL=http://host:3100 ./check-telemetry-invariants.sh uat
#
# With no argument all four environments are checked.
#
# Each invariant prints exactly one OK / FAIL line. A FAIL line always names
# the invariant AND prints the observed value - a bare "FAILED" costs more
# time than it saves.
#
# Exit status: 0 when every hard invariant (1-6) holds, 1 otherwise.
# Invariant 7 (cadence) is WARNING-ONLY and never affects the exit code:
# export intervals, scrape alignment and remote-write batching make exact
# cadence assertions flap, and a flaky check erodes trust faster than a
# missing one. Investigate repeated WARNs, but do not gate deploys on them.
#
# Design notes:
# - Metrics reach Prometheus by remote-write only. There is NO scrape target,
#   so there is NO `up` series and no staleness markers. Liveness assertions
#   therefore use last_over_time(...) range queries, never instant absent().
# - Invariant 3 asserts metric family PRESENCE only, never non-zero values:
#   UAT is genuinely idle, so value-based assertions would fail permanently.
# - Needs only POSIX sh + curl + grep + sed. No jq (not installed on the
#   monitoring host), no python, no framework.
#
# Run this after any deploy and after any monitoring config change.

set -u

PROM_URL="${PROM_URL:-http://localhost:9090}"
LOKI_URL="${LOKI_URL:-http://localhost:3100}"
# Configured OTel metric export interval in seconds. Environments still running
# a build that predates the 5s -> 15s change will WARN on invariant 7 until they
# are redeployed; invariant 7 is warning-only, so this never gates anything.
EXPORT_INTERVAL_S=15

case "${1:-all}" in
    all|"") ENVS="uat uat-indo testing prod" ;;
    uat|uat-indo|testing|prod) ENVS="$1" ;;
    *) echo "usage: $0 [uat|uat-indo|testing|prod|all]" >&2; exit 2 ;;
esac

FAIL=0

pass() { printf 'OK   - %s\n' "$1"; }
fail() { printf 'FAIL - %s\n' "$1"; FAIL=1; }
warn() { printf 'WARN - %s\n' "$1"; }

# prom_q <promql> : print raw Prometheus instant-query response body.
prom_q() {
    curl -s -m 20 -G "$PROM_URL/api/v1/query" --data-urlencode "query=$1"
}

# loki_q <logql> : print raw Loki instant-query response body.
loki_q() {
    curl -s -m 25 -G "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=$1"
}

# body_ok <body> : true when the API reports success (guards against curl
# failures and API errors being misread as "zero series").
body_ok() {
    case "$1" in *'"status":"success"'*) return 0;; *) return 1;; esac
}

# body_val <body> : first scalar value from an instant-query vector, or empty.
body_val() {
    printf '%s' "$1" | grep -oE '"value":\[[^]]+\]' | head -1 \
        | sed -E 's/.*"([^"]+)"\]$/\1/'
}


printf 'telemetry invariants: envs=[%s] prom=%s loki=%s\n' "$ENVS" "$PROM_URL" "$LOKI_URL"

for env in $ENVS; do
    job="hrms/hrms-backend-$env"
    svc="hrms-backend-$env"
    legacy="hrms/hrms-backend-$env"

    # --- Invariant 1: exactly one target_info series per environment.
    # (Caught: 4 JVMs all writing hrms-backend-uat.)
    # Identity lives in the `job` label: target_info carries no service_name.
    b=$(prom_q "count(target_info{job=\"$job\"})")
    if ! body_ok "$b"; then
        fail "inv1 ($env): Prometheus query failed (observed=query-error)"
    else
        n=$(body_val "$b")
        [ -z "$n" ] && n=0
        if [ "$n" = "1" ]; then
            pass "inv1 ($env): exactly one target_info series"
        else
            fail "inv1 ($env): expected 1 target_info series (observed=$n)"
        fi
    fi

    # --- Invariant 2: no container/process/os/distro labels on HRMS series.
    # (Caught: pool gauges reading double after a deploy.)
    # Inspect a real metric series, NOT target_info. target_info is *designed* to
    # carry every resource attribute, so that attributes deliberately left off the
    # metric labels stay reachable by join; asserting against it fails forever.
    # last_over_time() bounds the check to series still receiving samples —
    # retired series keep their old labels for the whole retention window, so
    # without that bound a correct fix keeps failing for 7 days.
    b=$(prom_q "last_over_time(jvm_thread_count{job=\"$job\"}[2m])")
    if ! body_ok "$b"; then
        fail "inv2 ($env): Prometheus query failed (observed=query-error)"
    elif [ -z "$(body_val "$b")" ]; then
        warn "inv2 ($env): no live jvm_thread_count series to inspect (observed=none)"
    else
        bad=$(printf '%s' "$b" \
            | grep -oE '"(container_id|process_[a-z_0-9]+|os_[a-z_0-9]+|host_[a-z_0-9]+|telemetry_distro_[a-z_0-9]+)"' \
            | sort -u | tr '\n' ' ')
        if [ -z "$bad" ]; then
            pass "inv2 ($env): no forbidden resource labels on HRMS series"
        else
            fail "inv2 ($env): forbidden labels present (observed=$bad)"
        fi
    fi

    # --- Invariant 3: expected metric families present (presence only).
    # (Caught: Hikari metrics silently absent before the bridge was enabled.)
    for fam in hikaricp_connections executor jvm http_server; do
        b=$(prom_q "count({__name__=~\"${fam}_.*\",job=\"$job\"})")
        if ! body_ok "$b"; then
            fail "inv3 ($env): family $fam query failed (observed=query-error)"
        else
            n=$(body_val "$b")
            [ -z "$n" ] && n=0
            if [ "$n" != "0" ]; then
                pass "inv3 ($env): family $fam present (series=$n)"
            else
                fail "inv3 ($env): family $fam missing (observed=0 series)"
            fi
        fi
    done

    # --- Invariant 4: exactly one Hikari series per pool per environment.
    # (Caught: HrmsBulkPool invisible; duplicate pool series.)
    b=$(prom_q "count by (pool) (hikaricp_connections_active{job=\"$job\"})")
    if ! body_ok "$b"; then
        fail "inv4 ($env): Prometheus query failed (observed=query-error)"
    else
        pairs=$(printf '%s' "$b" | grep -oE '"pool":"[^"]+"|"value":\[[^]]+\]' \
            | sed -E 's/"pool":"([^"]+)"/pool=\1/; s/"value":\[[^,]+,"([^"]+)"\]/count=\1/' \
            | awk -F= '/^pool=/{p=$2} /^count=/{print p" "$2}')
        if [ -z "$pairs" ]; then
            fail "inv4 ($env): no hikaricp series at all (observed=0 series)"
        else
            bad4=""
            while read -r pool cnt; do
                [ -z "$pool" ] && continue
                if [ "$cnt" != "1" ]; then
                    bad4="${bad4}${pool}=${cnt} "
                fi
            done <<EOF
$pairs
EOF
            if [ -z "$bad4" ]; then
                pools=$(printf '%s' "$pairs" | awk '{print $1}' | tr '\n' ' ')
                pass "inv4 ($env): one series per pool (observed pools: $pools)"
            else
                fail "inv4 ($env): pool series count != 1 (observed: $bad4)"
            fi
        fi
    fi

    # --- Invariant 5: one Loki line per emitted log line.
    # The legacy hrms/* dual-write stream must NOT be growing.
    b=$(loki_q "sum(count_over_time({service_name=\"$legacy\"}[10m]))")
    if ! body_ok "$b"; then
        fail "inv5 ($env): Loki query failed (observed=query-error)"
    else
        n=$(body_val "$b")
        [ -z "$n" ] && n=0
        # count_over_time returns an integer string; strip any decimal part.
        n=${n%%.*}
        if [ "$n" = "0" ]; then
            pass "inv5 ($env): legacy stream not growing (0 lines/10m)"
        else
            fail "inv5 ($env): legacy stream growing (observed=$n lines/10m)"
        fi
    fi

    # --- Invariant 6: this environment reports separately under its own job.
    # last_over_time (not instant presence) so stale remote-write series from
    # dead containers do not count as "reporting".
    b=$(prom_q "count(last_over_time(target_info{job=\"$job\"}[15m]))")
    if ! body_ok "$b"; then
        fail "inv6 ($env): Prometheus query failed (observed=query-error)"
    else
        n=$(body_val "$b")
        [ -z "$n" ] && n=0
        if [ "$n" != "0" ]; then
            pass "inv6 ($env): reporting under its own job (series=$n)"
        else
            fail "inv6 ($env): not reporting (observed=0 live series in 15m)"
        fi
    fi

    # --- Invariant 7 (WARNING ONLY): sample cadence ~= export interval.
    # max (not avg) so stale series from dead containers cannot dilute the
    # live cadence. Nominal = 300s / EXPORT_INTERVAL_S; tolerate 0.5x-2x.
    # Never touches the exit code - see header comment.
    b=$(prom_q "max(count_over_time(target_info{job=\"$job\"}[5m]))")
    if ! body_ok "$b"; then
        warn "inv7 ($env): cadence query failed (observed=query-error)"
    else
        n=$(body_val "$b")
        if [ -z "$n" ]; then
            warn "inv7 ($env): no samples, cadence unknown (observed=empty)"
        else
            n=${n%%.*}
            # Nominal = 300s window / export interval; tolerate 0.5x-2x.
            nominal=$((300 / EXPORT_INTERVAL_S))
            if [ "$n" -ge $((nominal / 2)) ] && [ "$n" -le $((nominal * 2)) ]; then
                pass "inv7 ($env): cadence sane (observed=$n samples/5m, expect ~$nominal)"
            else
                warn "inv7 ($env): cadence off (observed=$n samples/5m, expect ~$nominal)"
            fi
        fi
    fi
done

if [ "$FAIL" -ne 0 ]; then
    printf 'RESULT: FAIL\n'
    exit 1
fi
printf 'RESULT: PASS\n'
exit 0
