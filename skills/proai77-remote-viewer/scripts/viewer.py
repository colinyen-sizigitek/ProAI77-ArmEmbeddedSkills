#!/usr/bin/env python3
"""
ProAI77 Remote Base-Station / PC Display Viewer.
Connects to ProAI77 via WebSocket, decodes video, renders bounding boxes,
and displays HUD telemetry (FPS, Latency, MX3 Power, Temperature).
"""
import asyncio
import json
import sys
import numpy as np
import cv2
import websockets

async def run_viewer(server_uri):
    print(f"Connecting to ProAI77 at {server_uri} ...")
    async with websockets.connect(server_uri) as ws:
        print("[CONNECTED] Receiving live stream. Press 'q' to quit.")
        
        while True:
            data = await ws.recv()
            if isinstance(data, str):
                continue

            # Split JSON metadata and JPEG bytes by delimiter
            delimiter = b"|||"
            parts = data.split(delimiter, 1)
            if len(parts) != 2:
                continue

            meta_json = json.loads(parts[0].decode("utf-8"))
            jpeg_bytes = parts[1]

            nparr = np.frombuffer(jpeg_bytes, np.uint8)
            frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if frame is None:
                continue

            # Render HUD Telemetry
            fps = meta_json.get("fps", 0.0)
            latency = meta_json.get("latency_ms", 0.0)
            power_mw = meta_json.get("mx3_power_mw", 0.0)
            temp_c = meta_json.get("mx3_temp_c", 0.0)

            hud_text1 = f"FPS: {fps:.1f} | Latency: {latency:.1f}ms"
            hud_text2 = f"MX3 Power: {power_mw:.0f} mW (Limit: 9000 mW) | Temp: {temp_c:.1f}C"

            # Color alert if power exceeds 8000 mW
            color = (0, 255, 0)
            if power_mw > 8000:
                color = (0, 165, 255) # Orange
            if power_mw > 8800:
                color = (0, 0, 255) # Red

            cv2.rectangle(frame, (5, 5), (450, 65), (0, 0, 0), -1)
            cv2.putText(frame, hud_text1, (10, 25), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1)
            cv2.putText(frame, hud_text2, (10, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.55, color, 2)

            cv2.imshow("ProAI77 Remote Viewer", frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

    cv2.destroyAllWindows()

if __name__ == "__main__":
    uri = sys.argv[1] if len(sys.argv) > 1 else "ws://localhost:8765"
    asyncio.run(run_viewer(uri))
