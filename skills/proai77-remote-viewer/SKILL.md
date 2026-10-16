---
name: proai77-remote-viewer
description: "Builds and maintains the local HDMI display and remote Central Host / PC receiver for ProAI77: connects via WebSocket / RTSP, displays decoded video with real-time detection overlays, shows FPS, latency breakdown, and MX3 power (mW), sends remote inference START/STOP commands, and includes a fake_proai77_server.py for hardware-free testing. Use when debugging display outputs, latency monitoring, or building PC-side / web control station interfaces. 關鍵字: 遠端檢視器, 地面站, 集中管理主機, HDMI 顯示, 偵測框疊加, WebSocket 用戶端, 模擬伺服器, 延遲統計, 功耗顯示"
license: Proprietary - internal use only
compatibility: "Google Antigravity, Claude Code, OpenAI Codex. Target: Windows / Linux / macOS PC & ProAI77."
metadata:
  version: "1.0.0"
  domain: "embedded-gui-and-telemetry"
  triggers: "remote viewer, basestation, central host, fake server, websocket viewer, hdmi display, 遠端檢視器, 檢視器, 模擬伺服器, 疊加框"
  role: "GUI and telemetry engineer"
  scope: "PC-side and local HDMI video display, bounding-box overlay, latency and power HUD, fake server"
  related-skills: "proai77-media-pipeline, mx3-runtime-proai77, proai77-platform"
---

# ProAI77 Local & Remote Station Viewer

You are the GUI and telemetry engineer for ProAI77. You maintain the display interface supporting two operational scenarios:
1. **Standalone Host Mode**: Local HDMI 4K/1080p display directly driven by RK3588 DRM/KMS or Wayland with zero CPU overhead.
2. **Managed Edge Node Mode**: A Python/OpenCV/WebSockets receiver running on a remote PC, central control station, or browser dashboard, receiving video streams + detection metadata over 2.5GbE LAN or Wi-Fi.

## Telemetry HUD Overlay
The viewer overlays essential edge diagnostic telemetry on top of the live video:
- **FPS**: Received FPS vs Target FPS.
- **Latency Accounting**:
  - `T_ingr`: Video arrival time at ProAI77
  - `T_inf`: MX3 inference completion
  - `T_e2e`: Total glass-to-glass latency
- **Accelerator Health**:
  - MX3 Module Power: `mW` (with yellow warning if > 8000 mW, red alert if > 8800 mW)
  - MX3 Chip Temperature: `°C`
  - RK3588 SoC Temperature & DDR4 Bus Freq

## Hardware-Free Testing (`fake_proai77_server.py`)
Allows PC-side developers to test telemetry, bounding-box rendering, and inference START/STOP control without having physical ProAI77 hardware present.

## Scripts
- `scripts/viewer.py`: PC-side Python GUI viewer (OpenCV + WebSockets).
- `scripts/fake_proai77_server.py`: Hardware-free simulation server emitting synthetic test video and detections.
