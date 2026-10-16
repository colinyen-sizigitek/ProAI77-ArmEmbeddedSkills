#!/usr/bin/env bash
# ProAI77 Multimedia & Acceleration Drivers Diagnostic Script
# Verifies MPP VPU, RGA 2D, GStreamer plugins, and Mali OpenCL
set -euo pipefail

echo "=========================================================="
echo "      ProAI77 Multimedia & Preprocess Verification        "
echo "=========================================================="

echo "--- 1. Rockchip MPP VPU Service ---"
if [ -e "/dev/mpp_service" ]; then
    echo "[PASS] /dev/mpp_service exists."
else
    echo "[FAIL] /dev/mpp_service is missing! Hardware decoding will fail."
fi
if [ -f "/proc/mpp_service/version" ]; then
    cat /proc/mpp_service/version
fi

echo ""
echo "--- 2. Rockchip RGA 2D Engine ---"
if [ -e "/dev/rga" ]; then
    echo "[PASS] /dev/rga exists."
else
    echo "[FAIL] /dev/rga is missing! RGA hardware acceleration unavailable."
fi
if [ -f "/sys/kernel/debug/rkrga/driver_version" ]; then
    echo "RGA Driver: $(cat /sys/kernel/debug/rkrga/driver_version)"
fi

echo ""
echo "--- 3. GStreamer Rockchip Hardware Plugins ---"
if command -v gst-inspect-1.0 >/dev/null 2>&1; then
    for plugin in mppvideodec mpph264enc mpph265enc rgaconvert; do
        if gst-inspect-1.0 "$plugin" >/dev/null 2>&1; then
            echo "[PASS] GStreamer plugin: $plugin is installed."
        else
            echo "[WARN] GStreamer plugin: $plugin NOT found."
        fi
    done
else
    echo "[WARN] gst-inspect-1.0 not installed (install gstreamer1.0-tools)."
fi

echo ""
echo "--- 4. Arm Mali-G610 OpenCL Environment ---"
if [ -f "/etc/OpenCL/vendors/mali.icd" ]; then
    echo "[PASS] /etc/OpenCL/vendors/mali.icd found."
else
    echo "[WARN] Mali OpenCL ICD not found in /etc/OpenCL/vendors/."
fi
if command -v clinfo >/dev/null 2>&1; then
    echo "Mali OpenCL Device:"
    clinfo | grep -E "Platform Name|Device Name|Device OpenCL C Version" || true
fi

echo ""
echo "Diagnostic complete."
