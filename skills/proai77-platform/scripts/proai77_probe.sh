#!/usr/bin/env bash
# ProAI77 Hardware & Driver Sanity Probe Script
# Read-only audit of RK3588 SoC, Memory, PCIe, MPP, RGA, NPU, and MemryX MX3
set -euo pipefail

echo "=========================================================="
echo "          ProAI77 Hardware & Driver Sanity Probe           "
echo "=========================================================="
date -u +"Timestamp (UTC): %Y-%m-%dT%H:%M:%SZ"
echo ""

echo "--- 1. CPU & Architecture ---"
lscpu | grep -E "Model name|Architecture|CPU\(s\):|Thread|Vendor ID" || true
echo "CPU Clusters:"
for pol in /sys/devices/system/cpu/cpufreq/policy*; do
    if [ -d "$pol" ]; then
        cpus=$(cat "$pol/affected_cpus" 2>/dev/null || echo "unknown")
        cur_khz=$(cat "$pol/scaling_cur_freq" 2>/dev/null || echo "unknown")
        gov=$(cat "$pol/scaling_governor" 2>/dev/null || echo "unknown")
        echo "  Cluster $pol: CPUs [$cpus] | Governor: $gov | Freq: $((cur_khz / 1000)) MHz"
    fi
done
echo ""

echo "--- 2. Memory & Storage ---"
free -h
echo "Swap / ZRAM Status:"
swapon --show || echo "No swap/zram active!"
echo "Disk Space (eMMC / Root):"
df -h /
echo ""

echo "--- 3. MemryX MX3 AI Accelerator (PCIe) ---"
if command -v lspci >/dev/null 2>&1; then
    lspci | grep -i -E "memx|memryx|processing accelerators" || echo "MemryX PCIe device not found in lspci list!"
    echo "PCIe Link Capabilities & Status:"
    sudo -n lspci -vv -d 1fe1: 2>/dev/null | grep -E "LnkCap|LnkSta" || true
fi
if [ -d "/sys/memx0" ]; then
    echo "MemryX sysfs node found: /sys/memx0"
    if [ -f "/sys/memx0/verinfo" ]; then
        echo "Driver Verinfo:"
        cat /sys/memx0/verinfo || true
    fi
    if [ -f "/sys/memx0/temperature" ]; then
        echo "MX3 Chip Temperature: $(cat /sys/memx0/temperature) °C"
    fi
else
    echo "WARNING: /sys/memx0 not found. Check if memx kernel driver is loaded!"
fi
echo ""

echo "--- 4. Rockchip Multimedia Accelerators (MPP & RGA) ---"
echo -n "MPP Service (/dev/mpp_service): "
if [ -e "/dev/mpp_service" ]; then echo "FOUND"; else echo "NOT FOUND"; fi
if [ -f "/proc/mpp_service/version" ]; then
    echo "MPP Version: $(cat /proc/mpp_service/version)"
fi

echo -n "RGA 2D Device (/dev/rga): "
if [ -e "/dev/rga" ]; then echo "FOUND"; else echo "NOT FOUND"; fi
if [ -f "/sys/kernel/debug/rkrga/driver_version" ]; then
    echo "RGA Driver Version: $(cat /sys/kernel/debug/rkrga/driver_version)"
fi
echo ""

echo "--- 5. Rockchip NPU Status (RKNPU2 / RKLLM) ---"
echo -n "RKNPU Device (/dev/rknpu): "
if [ -e "/dev/rknpu" ]; then echo "FOUND"; else echo "NOT FOUND"; fi
if [ -f "/sys/kernel/debug/rknpu/version" ]; then
    echo "RKNPU Driver Version: $(cat /sys/kernel/debug/rknpu/version)"
fi
echo ""

echo "--- 6. Installed MemryX / Rockchip Packages ---"
dpkg -l | grep -E "memx|mpp|rga|rknn" || true

echo ""
echo "=========================================================="
echo "Probe completed."
