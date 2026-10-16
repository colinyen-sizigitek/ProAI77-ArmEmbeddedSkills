#!/usr/bin/env bash
# ProAI77 DDR4 / DMC Bus Load and Memory Bandwidth Monitor
# Samples DDR bus frequency and DMC governor to detect memory saturation
set -euo pipefail

DURATION=10
INTERVAL=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--duration) DURATION="$2"; shift 2 ;;
        -i|--interval) INTERVAL="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

DMC_DIR="/sys/class/devfreq/dmc"
if [ ! -d "$DMC_DIR" ]; then
    echo "[WARN] /sys/class/devfreq/dmc not found. Check kernel rockchip-dmc driver."
    exit 0
fi

echo "=========================================================="
echo "       ProAI77 DDR4 / DMC Bus Frequency & Load Monitor     "
echo "Sampling: ${INTERVAL}s for ${DURATION}s"
echo "=========================================================="

cur_gov=$(cat "$DMC_DIR/governor" 2>/dev/null || echo "unknown")
avail_freqs=$(cat "$DMC_DIR/available_frequencies" 2>/dev/null || echo "unknown")
echo "DMC Governor: $cur_gov"
echo "Available Frequencies: $avail_freqs"
echo ""

echo "Time (UTC)             DMC Freq (MHz)    System RAM Used"
echo "--------------------------------------------------------"

end_time=$(( $(date +%s) + DURATION ))
while [ "$(date +%s)" -lt "$end_time" ]; do
    ts=$(date +"%T")
    cur_khz=$(cat "$DMC_DIR/cur_freq" 2>/dev/null || echo "0")
    cur_mhz=$((cur_khz / 1000000))
    ram_used=$(free -h | awk '/^Mem:/{print $3}')
    printf "%-22s %-17d %s\n" "$ts" "$cur_mhz" "$ram_used"
    sleep "$INTERVAL"
done
echo "Monitoring completed."
