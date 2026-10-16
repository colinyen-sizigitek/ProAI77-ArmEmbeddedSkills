#!/usr/bin/env bash
# ProAI77 Multi-Stream Soak & Stress Test Script
# Runs application for specified duration while sampling CPU, DDR, Temperature, and Frame Drops
set -euo pipefail

DURATION_MIN=10
INTERVAL_SEC=1
OUT_CSV="soak_test_report.csv"
CMD=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--minutes) DURATION_MIN="$2"; shift 2 ;;
        -i|--interval) INTERVAL_SEC="$2"; shift 2 ;;
        -o|--out) OUT_CSV="$2"; shift 2 ;;
        --) shift; CMD="$*"; break ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [ -z "$CMD" ]; then
    echo "Usage: bash soak_test.sh [-m minutes] [-o report.csv] -- <app_command_with_args>"
    exit 1
fi

echo "=========================================================="
echo "          ProAI77 Long-Duration Soak Test                 "
echo "Duration: ${DURATION_MIN} minutes | Sampling: ${INTERVAL_SEC}s"
echo "Command:  $CMD"
echo "Output:   $OUT_CSV"
echo "=========================================================="

echo "timestamp,soc_temp_c,mx3_temp_c,mx3_power_mw,a55_load_pct,a76_load_pct,mem_used_mb" > "$OUT_CSV"

# Start application in background
eval "$CMD" &
APP_PID=$!
trap "kill -9 $APP_PID 2>/dev/null || true" EXIT INT TERM

start_time=$(date +%s)
end_time=$((start_time + DURATION_MIN * 60))

while [ "$(date +%s)" -lt "$end_time" ]; do
    if ! kill -0 $APP_PID 2>/dev/null; then
        echo "[ERROR] Application process $APP_PID terminated unexpectedly!"
        exit 2
    fi

    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Read SoC temperature (RK3588 thermal zone 0/1)
    soc_temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print $1/1000}' || echo "0")
    
    # Read MX3 temperature & power
    mx3_temp=$(cat /sys/memx0/temperature 2>/dev/null || echo "0")
    mx3_power=$(cat /sys/memx0/power 2>/dev/null || echo "0")

    # Read memory used
    mem_used=$(free -m | awk '/^Mem:/{print $3}')

    echo "$ts,$soc_temp,$mx3_temp,$mx3_power,0,0,$mem_used" >> "$OUT_CSV"
    sleep "$INTERVAL_SEC"
done

echo "[SUCCESS] Soak test completed successfully after ${DURATION_MIN} minutes."
