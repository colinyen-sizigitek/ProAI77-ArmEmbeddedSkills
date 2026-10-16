#!/usr/bin/env bash
# Hardware PMUv3 Profiler Script for ProAI77 (RK3588 big.LITTLE)
# Measures CPI, Cache Misses, and Branch Mispredictions across A76 and A55 cores
set -euo pipefail

DURATION=5
TARGET_PID=""
CMD=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--duration) DURATION="$2"; shift 2 ;;
        -p|--pid) TARGET_PID="$2"; shift 2 ;;
        --) shift; CMD="$*"; break ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if ! command -v perf >/dev/null 2>&1; then
    echo "[ERROR] Linux 'perf' tool not installed. Run: sudo apt-get install linux-tools-common linux-tools-\$(uname -r)"
    exit 1
fi

echo "=========================================================="
echo "      RK3588 PMUv3 Hardware Counter Profiler              "
echo "Duration: ${DURATION}s"
if [ -n "$TARGET_PID" ]; then echo "Target PID: $TARGET_PID"; fi
if [ -n "$CMD" ]; then echo "Command: $CMD"; fi
echo "=========================================================="

# Counter groups supported by Arm PMUv3
EVENTS="cycles,instructions,cache-misses,cache-references,branch-misses,branches"

if [ -n "$TARGET_PID" ]; then
    perf stat -e "$EVENTS" -p "$TARGET_PID" -- sleep "$DURATION"
elif [ -n "$CMD" ]; then
    perf stat -e "$EVENTS" -- $CMD
else
    echo "Profiling system-wide for ${DURATION}s..."
    perf stat -e "$EVENTS" -a -- sleep "$DURATION"
fi
