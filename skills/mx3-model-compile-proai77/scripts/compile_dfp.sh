#!/usr/bin/env bash
# ProAI77 Unified DFP Model Compilation Script (x86 WSL2 / On-Board ARM64)
# Verifies environment, checks RAM/Swap guardrails on ARM64, and runs mx_nc
set -euo pipefail

ONNX_MODEL=""
INPUT_SHAPE="640,640,3"
CHIP_COUNT=4
OUTPUT_DFP=""
EXTRA_ARGS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--model) ONNX_MODEL="$2"; shift 2 ;;
        -s|--shape) INPUT_SHAPE="$2"; shift 2 ;;
        -c|--chips) CHIP_COUNT="$2"; shift 2 ;;
        -o|--out) OUTPUT_DFP="$2"; shift 2 ;;
        --) shift; EXTRA_ARGS="$*"; break ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [ -z "$ONNX_MODEL" ]; then
    echo "Usage: bash compile_dfp.sh -m <model.onnx> [-s H,W,C] [-c chips] [-o output.dfp] [-- extra_mx_nc_flags]"
    exit 1
fi

echo "=========================================================="
echo "          MemryX DFP Model Compiler (ProAI77)             "
echo "Model:  $ONNX_MODEL"
echo "Shape:  $INPUT_SHAPE (NHWC without batch)"
echo "Chips:  $CHIP_COUNT"
echo "=========================================================="

# Check host architecture and RAM guardrail
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    echo "Compiling on native ARM64 (ProAI77)..."
    swap_free=$(free -m | awk '/^Swap:/{print $4}')
    ram_free=$(free -m | awk '/^Mem:/{print $7}')
    echo "Available RAM: ${ram_free} MB | Available Swap: ${swap_free} MB"
    if [ "$((ram_free + swap_free))" -lt 4000 ]; then
        echo "[ERROR] Insufficient free memory + swap (< 4GB). Activate swapfile before compiling."
        exit 2
    fi
fi

if ! command -v mx_nc >/dev/null 2>&1; then
    echo "[ERROR] mx_nc command not found! Activate MemryX virtual environment (e.g. source ~/mx/bin/activate)."
    exit 1
fi

DFP_FLAG=""
if [ -n "$OUTPUT_DFP" ]; then
    DFP_FLAG="-dfp $OUTPUT_DFP"
fi

cmd="mx_nc -m $ONNX_MODEL -c $CHIP_COUNT -is \"$INPUT_SHAPE\" --autocrop $DFP_FLAG $EXTRA_ARGS"
echo "Executing: $cmd"
eval "$cmd"

echo "[SUCCESS] Compilation completed successfully."
