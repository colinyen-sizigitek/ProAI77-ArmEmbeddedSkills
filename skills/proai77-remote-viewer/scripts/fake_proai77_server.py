#!/usr/bin/env python3
"""
Hardware-Free Simulation Server for ProAI77.
Generates synthetic video stream with simulated bounding-box detections,
latency accounting, and MX3 power telemetry for PC viewer testing.
"""
import asyncio
import json
import time
import numpy as np
import cv2
import websockets

PORT = 8765

async def handler(websocket):
    print(f"Client connected from {websocket.remote_address}")
    frame_id = 0
    start_time = time.time()

    try:
        while True:
            frame_id += 1
            now = time.time()
            elapsed = now - start_time

            # Generate synthetic 640x480 test image
            img = np.zeros((480, 640, 3), dtype=np.uint8)
            cv2.putText(img, f"ProAI77 Simulator - Frame {frame_id}", (30, 40),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)

            # Draw a moving simulated detection box
            cx = int(320 + 200 * np.sin(elapsed * 2))
            cy = int(240 + 100 * np.cos(elapsed * 2))
            cv2.rectangle(img, (cx - 40, cy - 40), (cx + 40, cy + 40), (0, 0, 255), 2)
            cv2.putText(img, "person: 0.94", (cx - 40, cy - 48),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 1)

            # Telemetry packet
            telemetry = {
                "frame_id": frame_id,
                "timestamp_us": int(now * 1e6),
                "fps": 30.0,
                "mx3_power_mw": 4250.0 + 300.0 * np.sin(elapsed),
                "mx3_temp_c": 52.0 + 2.0 * np.cos(elapsed),
                "soc_temp_c": 48.5,
                "latency_ms": 32.4,
                "detections": [
                    {"label": "person", "score": 0.94, "box": [cx - 40, cy - 40, cx + 40, cy + 40]}
                ]
            }

            _, jpeg_bytes = cv2.imencode(".jpg", img, [cv2.IMWRITE_JPEG_QUALITY, 80])
            
            # Send JSON metadata followed by JPEG binary
            msg = json.dumps(telemetry) + "|||"
            await websocket.send(msg.encode("utf-8") + jpeg_bytes.tobytes())
            await asyncio.sleep(1.0 / 30.0)

    except websockets.exceptions.ConnectionClosed:
        print("Client disconnected.")

async def main():
    print(f"Starting ProAI77 simulation server on ws://0.0.0.0:{PORT} ...")
    async with websockets.serve(handler, "0.0.0.0", PORT):
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())
