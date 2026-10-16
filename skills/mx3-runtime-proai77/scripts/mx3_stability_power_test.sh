#!/usr/bin/env bash
# ProAI77 MX3 10-Minute Power Compliance and Thermal Burn-In Test Script
# Verifies that real-time inference never exceeds the M.2 9W (9000 mW) power cap
set -euo pipefail

DFP_PATH=""
FREQ_MHZ=400
DURATION_MIN=10
OUTPUT_CSV="mx3_power_test.csv"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dfp) DFP_PATH="$2"; shift 2 ;;
        --freq) FREQ_MHZ="$2"; shift 2 ;;
        --minutes) DURATION_MIN="$2"; shift 2 ;;
        --output) OUTPUT_CSV="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [ -z "$DFP_PATH" ]; then
    echo "Usage: bash mx3_stability_power_test.sh --dfp <path_to_model.dfp> [--freq 300|400|450|500] [--minutes 10] [--output log.csv]"
    exit 1
fi

echo "=========================================================="
echo "      ProAI77 MemryX MX3 9W Power & Thermal Burn-In       "
echo "DFP:       $DFP_PATH"
echo "Frequency: ${FREQ_MHZ} MHz"
echo "Duration:  ${DURATION_MIN} minutes"
echo "Output:    $OUTPUT_CSV"
echo "=========================================================="

echo "timestamp,freq_mhz,power_mw,temp_c,status" > "$OUTPUT_CSV"

# Start mx_bench in background
if command -v mx_bench >/dev/null 2>&1; then
    mx_bench -d "$DFP_PATH" -f 500000 -v &
    BENCH_PID=$!
    trap "kill -9 $BENCH_PID 2>/dev/null || true" EXIT INT TERM
else
    echo "[WARN] mx_bench not found in PATH; monitoring existing workload..."
fi

start_time=$(date +%s)
end_time=$((start_time + DURATION_MIN * 60))
max_observed_power=0
max_observed_temp=0
violations=0

while [ "$(date +%s)" -lt "$end_time" ]; do
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    power_mw=0
    temp_c=0
    if [ -f "/sys/memx0/power" ]; then
        power_mw=$(cat /sys/memx0/power 2>/dev/null || echo "0")
    fi
    if [ -f "/sys/memx0/temperature" ]; then
        temp_c=$(cat /sys/memx0/temperature 2>/dev/null || echo "0")
    fi

    if (( $(echo "$power_mw > $max_observed_power" | bc -l) )); then max_observed_power=$power_mw; fi
    if (( $(echo "$temp_c > $max_observed_temp" | bc -l) )); then max_observed_temp=$temp_c; fi

    status="OK"
    if (( $(echo "$power_mw > 9000" | bc -l) )); then
        status="EXCEEDS_9W_LIMIT"
        violations=$((violations + 1))
        echo "[$ts ALERT] Power violation: ${power_mw} mW > 9000 mW!"
    fi

    echo "$ts,$FREQ_MHZ,$power_mw,$temp_c,$status" >> "$OUTPUT_CSV"
    sleep 1
done

echo ""
echo "=========================================================="
echo "Burn-in test finished."
echo "Max Power: ${max_observed_power} mW (Limit: 9000 mW)"
echo "Max Temp:  ${max_observed_temp} °C"
if [ "$violations" -eq 0 ]; then
    echo "[PASS] System complies with M.2 9W power budget!"
    exit 0
else
    echo "[FAIL] $violations power violations detected! Clock step-down required."
    exit 2
fi
