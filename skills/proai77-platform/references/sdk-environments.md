# Dual SDK Environments: Mode A vs. Mode B

MemryX SDK 2.2 provides native Linux ARM64 support for both runtime drivers and the `mx_nc` compiler. We support two clear workflows:

---

## Mode A: PC-Train, Compile and Deploy to Board Runtime (Preferred)

Recommended for team workflows, CI/CD, and fast model iteration.

```
[ x86_64 Dev Machine (Linux / WSL2 Ubuntu 22.04) ]
   1. Train or export model to ONNX (YOLOv10, YOLO26, YOLO11, YOLOX).
   2. Run mx_nc in Python 3.10-3.12 venv:
      mx_nc -m model.onnx -c 4 -is "640,640,3" --autocrop
   3. Run mx_sim to validate quantization accuracy against float baseline.
   4. scp model_c4.dfp to ProAI77: /opt/proai77/models/
          |
          v (Deploy .dfp via scp / rsync)
[ ProAI77 Board (RK3588 + MX3) ]
   1. Lightweight Runtime only:
      sudo apt-get install memx-drivers memx-accl memx-accl-plugins
   2. C++ application loads model_c4.dfp using MX::Runtime::MxAcclMT.
   3. Python application loads model_c4.dfp using memryx.AsyncAccl.
```

---

## Mode B: On-Board Full SDK on ProAI77 (Self-Contained)

For developers who wish to train (or download) and compile models directly on the ProAI77 edge device without an x86 machine.

### Important Considerations on RK3588:
- **ARM64 Support**: `mx_nc` compiler, `mx_bench`, and runtime are fully supported on ARM64 Linux.
- **Simulator (`mx_sim`)**: **Not available on ARM64**. Hardware validation is performed directly on the MX3 hardware using `mx_bench` or test scripts.
- **Memory & OOM Prevention**: ProAI77 has 8 GB RAM. Compiling large ONNX models can consume 4–6 GB of memory. If other services are running simultaneously, the kernel OOM killer may terminate the compiler.
  - **Remedy**: Always activate at least **4 GB swap or ZRAM** (`scripts/setup_memryx_env.sh --mode full-onboard-sdk`) before running `mx_nc`.

### Setup Commands (Mode B):
```bash
# 1. Install kernel headers and runtime packages
sudo apt-get update
sudo apt-get install -y linux-headers-$(uname -r) build-essential python3-venv python3-dev libhdf5-dev

# 2. Add MemryX apt repository & install runtime
wget -qO- https://developer.memryx.com/deb/memryx.asc | sudo tee /etc/apt/trusted.gpg.d/memryx.asc >/dev/null
echo 'deb https://developer.memryx.com/deb stable main' | sudo tee /etc/apt/sources.list.d/memryx.list >/dev/null
sudo apt-get update
sudo apt-get install -y memx-drivers memx-accl memx-accl-plugins

# 3. Create virtual environment in ~/mx and install full SDK tools
python3 -m venv ~/mx
source ~/mx/bin/activate
pip install --upgrade pip wheel
pip install --extra-index-url https://developer.memryx.com/pip memryx

# 4. Verify compiler on ProAI77
mx_nc --version
```
