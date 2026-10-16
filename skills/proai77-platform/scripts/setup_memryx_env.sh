#!/usr/bin/env bash
# Dual-Mode Environment Setup Script for ProAI77 (RK3588 + MemryX MX3)
# Supports Mode A (Runtime-only on board) and Mode B (On-Board Full SDK in ~/mx with ZRAM guard)
set -euo pipefail

MODE="runtime-only" # or "full-onboard-sdk"
DRY_RUN=false
CONFIRM=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode) MODE="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --yes) CONFIRM=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "=========================================================="
echo "MemryX SDK Environment Setup for ProAI77 (RK3588)"
echo "Mode: $MODE"
if [ "$DRY_RUN" = true ]; then echo "[DRY RUN MODE - Commands will only be printed]"; fi
echo "=========================================================="

run_cmd() {
    echo ">>> $*"
    if [ "$DRY_RUN" = false ]; then
        eval "$*"
    fi
}

# 1. Base Runtime Installation (Common to Mode A and Mode B)
echo "Step 1: Installing MemryX Kernel Drivers & C++ Runtime..."
if [ "$CONFIRM" = false ] && [ "$DRY_RUN" = false ]; then
    read -p "Install memx-drivers and memx-accl via apt? (y/N) " resp
    if [[ ! "$resp" =~ ^[Yy]$ ]]; then echo "Aborted."; exit 0; fi
fi

run_cmd "sudo apt-get update"
run_cmd "sudo apt-get install -y linux-headers-\$(uname -r) build-essential cmake"
run_cmd "wget -qO- https://developer.memryx.com/deb/memryx.asc | sudo tee /etc/apt/trusted.gpg.d/memryx.asc >/dev/null"
run_cmd "echo 'deb https://developer.memryx.com/deb stable main' | sudo tee /etc/apt/sources.list.d/memryx.list >/dev/null"
run_cmd "sudo apt-get update"
run_cmd "sudo apt-get install -y memx-drivers memx-accl memx-accl-plugins"

# 2. Mode B Specific: On-Board Full SDK with ZRAM/Swap Guardrails
if [ "$MODE" = "full-onboard-sdk" ]; then
    echo ""
    echo "Step 2: Configuring On-Board Full MemryX SDK Tools (Mode B)..."

    # Memory Check & ZRAM Setup
    total_ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    swap_mb=$(free -m | awk '/^Swap:/{print $2}')
    echo "Detected RAM: ${total_ram_mb} MB | Active Swap: ${swap_mb} MB"

    if [ "$swap_mb" -lt 4000 ]; then
        echo "WARNING: Less than 4GB swap detected. Compiling models with mx_nc on 8GB RAM can trigger OOM."
        if [ "$DRY_RUN" = false ]; then
            echo "Setting up 4GB swapfile at /swapfile..."
            run_cmd "sudo fallocate -l 4G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=4096"
            run_cmd "sudo chmod 600 /swapfile"
            run_cmd "sudo mkswap /swapfile"
            run_cmd "sudo swapon /swapfile"
            echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab >/dev/null || true
            echo "[OK] 4GB swap activated."
        fi
    fi

    # Virtual Environment Setup in ~/mx
    VENV_PATH="$HOME/mx"
    echo "Creating Python Virtual Environment in $VENV_PATH..."
    run_cmd "sudo apt-get install -y python3-venv python3-dev libhdf5-dev"
    run_cmd "python3 -m venv $VENV_PATH"
    run_cmd "$VENV_PATH/bin/pip install --upgrade pip wheel"
    run_cmd "$VENV_PATH/bin/pip install --extra-index-url https://developer.memryx.com/pip memryx"

    echo ""
    echo "[SUCCESS] Mode B (On-Board Full SDK) setup complete!"
    echo "Activate anytime with: source ~/mx/bin/activate"
    echo "Verify compiler with: mx_nc --version"
else
    echo ""
    echo "[SUCCESS] Mode A (Runtime-Only) setup complete!"
    echo "Verify driver with: cat /sys/memx0/verinfo"
fi
