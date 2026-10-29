# ProAI77 & MemryX MX3 ARM Embedded Skills and Tools

一套專為 **ProAI77 (Rockchip RK3588 + MemryX MX3 M.2 4-Chip AI 模組)** 邊緣運算平台打造的專業級嵌入式開發技能庫與工程工具套件。

適用於 **Google Antigravity、Claude Code、OpenAI Codex**。

---

## 平台規格核心概要
- **SoC**：Rockchip **RK3588**（8nm 製程，4× Cortex-A76 @ 2.4GHz + 4× Cortex-A55 @ 1.8GHz，**Armv8.2-A**）。
- **記憶體與儲存**：**8GB DDR4**（統一記憶體總線）+ **64GB eMMC**。
- **主 AI 加速卡**：**MemryX Cascade 100M M.2**（4 顆 MX3 晶片，PCIe Gen3，最高 24 TFLOPS，~42M 8-bit 片上靜態 SRAM 權重，無外掛 DRAM）。
- **插槽功率上限**：**M.2 插槽最大供電限制為 9W (`<= 9000 mW`)**。
- **硬體多媒體與圖形加速**：
  - **MPP**：8K 視訊硬體解碼（H.264/H.265/VP9/AV1/MJPEG）與編碼（H.264/H.265 多路並行）。
  - **RGA (`librga` im2d)**：硬體 2D 縮放、裁切、旋轉、Letterbox 填充與 NV12 ↔ RGB 色彩空間零拷貝轉換。
  - **GPU**：Arm Mali-G610 MP4（OpenCL 2.2 / GLES 3.2，支援張量正規化與自訂著色器）。
  - **輔助 NPU**：RK3588 內建 **6 TOPS NPU**（`RKNPU2` + `RKLLM`，共享 8GB DDR4）。
- **介面與部署型態**：
  - 雙 2.5GbE 網路埠、HDMI 輸出、USB 3.0/2.0/Type-C、RS232/UART/GPIO。
  - 支援「**單機獨立工作站**」（接螢幕本機開發/執行）或「**集中管理之邊緣節點**」（遠端 SSH、多路 RTSP、WebRTC/WebSocket 串流回傳）。

---

## 技能庫架構 (Skills Overview)

| Skill 名稱 | 適用情境與主要職責 |
|---|---|
| **`proai77-platform`** | 硬體狀態與驅動偵測、雙軌 SDK 環境安裝 (Mode A PC編譯部署 / Mode B 板端完整SDK)、CMake 與 systemd 服務管理 |
| **`proai77-media-pipeline`** | 多路 RTSP/UVC 擷取、MPP 硬解硬編、RGA/GPU 零拷貝前處理、HDMI/RTSP/WebSocket 輸出管線 |
| **`proai77-perf-optimization`** | Cortex-A76/A55 big.LITTLE 綁核、Armv8.2-A NEON 向量化、DDR4 頻寬防塞車、零拷貝緩衝池優化 |
| **`proai77-mx3-model-selection`** | 依據目標 FPS 與 **M.2 ≤ 9W** 限制篩選 579 模型與時脈，整合 Model Explorer，提供 RK NPU 協同評估 |
| **`proai77-mx3-model-compile`** | Model Explorer 預編譯 DFP 下載、x86 PC/WSL2 `mx_nc` 編譯部署 (Mode A)、板端 `~/mx` 防 OOM 編譯 (Mode B) |
| **`proai77-mx3-runtime`** | C++ (`MxAcclMT`) 與 Python (`AsyncAccl`/`MultiStreamAsyncAccl`) 執行期整合、時脈設定、9W 功耗與溫度守護 |
| **`proai77-rk3588-npu-coexecution`** | RK3588 6 TOPS NPU 協同處理：LLM/VLM (`rknn-llm`)、語音/OCR、次要 ROI 模型並行、DDR4 頻寬與延遲檢核 |
| **`proai77-remote-viewer`** | 本地 HDMI 顯示與遠端 Central Host / Browser 檢視器（支援 RTSP/WebRTC/WebSocket、延遲與功耗 HUD 疊加） |
| **`proai77-code-review`** | 依據專案規範與 Arm 最佳實踐進行 C++17 / Python 程式碼審查（檢查 9W 規範、硬體解碼落實度、綁核與記憶體洩漏） |

---

## 核心設計決策與規則

1. **三級語言與硬體加速策略**：
   - **Tier 1 (Python)**：PoC、單路串流、中低複雜度。必須搭配 GStreamer (`mppvideodec` + `rgaconvert`) 或 `MxPrepost`，杜絕 CPU 軟解與軟體縮放。
   - **Tier 2 (C++17)**：多路串流、高並行、低延遲生產環境。全面使用 `librockchip_mpp` + `librga` DMA-BUF zero-copy + `MxAcclMT`。
   - **Tier 3 (Hybrid)**：C++ 封裝底層零拷貝前處理與推論，透過 `pybind11` 導出給 Python 控制層。
2. **M.2 9W 功率與時脈規則**：
   - 僅允許選擇 `status == PASS` 且 **`power_mw <= 9000`** 的項目（9W 內部已包含硬體安全裕度）。
   - 從 300 / 400 / 450 / 500 MHz 中選擇能滿足 `FPS >= Target * 1.5` 的最低時脈（優先 300/400 MHz；450/500 MHz 須通過 10 分鐘燒機測試）。
3. **雙軌 SDK 開發環境**：
   - **Mode A (首選)**：PC/WSL2 負責訓練、ONNX 匯出、`mx_nc` 編譯與 `mx_sim` 模擬；ProAI77 僅安裝輕量 Runtime。
   - **Mode B (板端完整 SDK)**：ProAI77 本機安裝完整 `memryx` pip 工具包，並設定 Swap/ZRAM 防範 8GB RAM 編譯大型模型時 OOM。
4. **MemryX MX3 與 RK3588 NPU 任務分工**：
   - 所有標準視覺推論一律預設由 **MemryX MX3** 完成。
   - 當涉及 (1) 大語言/多模態模型 (`rknn-llm`)、(2) 語音/變長 OCR、(3) 避免 MX3 權重切換的次要 ROI 模型、(4) 多模型平行或串聯時，主動提醒使用 **RK NPU + MX3 協同架構**，並對 **DDR4 總線頻寬爭搶與跨硬體同步延遲** 進行嚴格把關。

---

## 安裝方式

支援一鍵安裝至當前專案或本機使用者目錄：

### Windows (PowerShell)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File install\install.ps1 -Target all -Scope project
```

### Linux / WSL (Bash)
```bash
bash install/install.sh --target all --scope project
```

- `-Target`: 可指定 `antigravity`、`claude`、`codex` 或 `all`。
- `-Scope`: 可指定 `project`（安裝至專案 `.agents/skills`）或 `user`（安裝至全域使用者配置）。
- `-DryRun`: 僅模擬並列出安裝步驟，不實際寫入檔案。

---

## 驗證與健康檢查

執行內建驗證工具，確保所有 Skills、YAML 前導資訊、Markdown 連結與查詢腳本語法正確：
```bash
python scripts/validate.py
```

測試 9W 功耗與時脈篩選工具：
```bash
python skills/proai77-mx3-model-selection/scripts/freq_power_query.py --model-regex "YOLO26_nano_640" --target-fps 30 --max-power-mw 9000
```
