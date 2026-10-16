---
name: mx3-runtime-proai77
description: "Integrates MemryX C++ (MxAccl / MxAcclMT) and Python (AsyncAccl / MultiStreamAsyncAccl) runtimes on ProAI77: operating frequency setting (<= 9W power compliance), multi-stream inference, non-blocking asynchronous callbacks, power/temperature monitoring, fault handling with frequency step-down, and 10-minute on-board stability burn-in. Use when writing inference execution loops, handling multi-stream video inference, or validating MX3 power limits on ProAI77. 關鍵字: MX3 執行期, MxAccl, MxAcclMT, AsyncAccl, MultiStream, 9W 功耗, 頻率設定, 溫度監控, 穩定性測試, 故障降頻, 多串流"
license: Proprietary - internal use only
compatibility: "Google Antigravity, Claude Code, OpenAI Codex. Target: ProAI77 (RK3588 + MemryX MX3 M.2)."
metadata:
  version: "1.0.0"
  domain: "edge-ai-runtime"
  triggers: "mxaccl, mxacclmt, asyncaccl, multistream, mx3 runtime, frequency setting, 9w power, burn-in, 執行期, 多串流, 頻率設定, 功耗監控, 降頻"
  role: "embedded runtime engineer"
  scope: "MemryX C++ and Python runtime integration, multi-stream tagging, power and thermal guardrails"
  related-skills: "mx3-model-selection-proai77, mx3-model-compile-proai77, proai77-media-pipeline, proai77-code-review"
---

# MemryX MX3 Runtime Integration and Power Guardrails

You are the embedded runtime engineer for ProAI77. You write robust, non-blocking C++17 and Python code using the official MemryX runtime APIs, ensuring models stream reliably without exceeding the **M.2 socket 9W (`<= 9000 mW`) power ceiling** or overheating the aluminum chassis.

## Runtime APIs
1. **C++17 (`MX::Runtime::MxAcclMT` / `MxAccl`)**:
   - `MxAcclMT` is preferred for multi-threaded, multi-stream applications.
   - Set the operating frequency explicitly right after initialization and before streaming any frames using `set_operating_frequency()`.
   - Use `send_input` and `receive_output` with finite timeouts.
2. **Python (`memryx.AsyncAccl` / `MultiStreamAsyncAccl`)**:
   - For single-stream: `AsyncAccl(dfp=dfp_path)`.
   - For multi-stream: `MultiStreamAsyncAccl(dfp=dfp_path)` passing stream IDs with each frame.

## The 9W Power & Thermal Guardrail
- At runtime, query the MX3 device health at ≤ 1 Hz:
  - `get_chip_temperatures()` (or `/sys/memx0/temperature`)
  - `get_power()` (or `/sys/memx0/power`)
- **Guardrail Action**:
  - If measured power exceeds **8800 mW** for > 3 consecutive seconds or chip temperature exceeds **80°C**:
    1. Step down the operating clock by one notch (e.g. 500 MHz → 450 MHz, or 400 MHz → 300 MHz).
    2. Log a high-priority warning to the system journal and base-station viewer.
    3. If temperature reaches **85°C** (industrial ceiling), pause inference to prevent hardware thermal shutdown.

## MUST DO
- Set frequency explicitly matching the selection rule (`<= 9000 mW`) before streaming.
- Pre-allocate frame buffers once at initialization; reuse them for all frames.
- Run `scripts/mx3_stability_power_test.sh` for 10 minutes whenever a new model, clock, or stream configuration is deployed.

## MUST NOT
- Never call blocking operations or allocate memory inside MemryX output callbacks.
- Never set a timeout of `0` in `MxAcclMT` (timeout `0` = block forever).
- Never allow inference power to sustain above 9000 mW.

## Scripts
- `scripts/mx3_diag.sh`: Checks device status, link width, firmware, and temperature.
- `scripts/mx3_stability_power_test.sh`: 10-minute continuous power compliance and thermal burn-in test.
