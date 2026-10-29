#!/usr/bin/env python3
"""
ProAI77 MemryX MX3 Frequency and Power Query Tool.
Filters models by target FPS and enforces the M.2 9W (<= 9000 mW) power ceiling.
"""
import os
import sys
import csv
import re
import argparse

def main():
    parser = argparse.ArgumentParser(description="Query ProAI77 MX3 frequency & power matrix (M.2 <= 9W)")
    parser.add_argument("-m", "--model-regex", default=".*", help="Regex matching model names (e.g. 'YOLO26_nano_640|YOLO_v10')")
    parser.add_argument("-t", "--target-fps", type=float, default=30.0, help="Target application FPS (default: 30)")
    parser.add_argument("-s", "--safety", type=float, default=1.5, help="Safety margin factor (default: 1.5)")
    parser.add_argument("-p", "--max-power-mw", type=float, default=9000.0, help="Maximum M.2 power limit in mW (default: 9000)")
    parser.add_argument("-f", "--max-freq", type=int, default=500, choices=[300, 400, 450, 500], help="Maximum allowed frequency (default: 500)")
    parser.add_argument("--csv", action="store_true", help="Output raw CSV format instead of formatted table")

    args = parser.parse_args()
    required_fps = args.target_fps * args.safety

    script_dir = os.path.dirname(os.path.abspath(__file__))
    matrix_csv = os.path.join(script_dir, "..", "references", "proai77-freq-power-matrix.csv")

    if not os.path.exists(matrix_csv):
        print(f"[ERROR] Matrix file not found: {matrix_csv}", file=sys.stderr)
        return 1

    pattern = re.compile(args.model_regex, re.IGNORECASE)
    
    # model -> list of rows
    models_data = {}
    with open(matrix_csv, "r", encoding="utf-8") as f:
        reader = csv.DictReader((line for line in f if not line.startswith("#")))
        for row in reader:
            m_name = row["model"].strip('"')
            if pattern.search(m_name):
                if m_name not in models_data:
                    models_data[m_name] = []
                models_data[m_name].append(row)

    if not models_data:
        print(f"No models matched regex: {args.model_regex}")
        return 0

    results = []
    for m_name, rows in models_data.items():
        # Sort rows by frequency ascending
        rows_sorted = sorted(rows, key=lambda r: int(r["freq_mhz"]))
        chosen = None

        for r in rows_sorted:
            freq = int(r["freq_mhz"])
            if freq > args.max_freq:
                continue

            status = r["status"].strip()
            if status != "PASS":
                continue

            try:
                fps = float(r["fps"])
                power = float(r["power_mw"])
            except ValueError:
                continue

            # Check 9W power ceiling
            if power > args.max_power_mw:
                continue

            # Check target FPS requirement
            if fps >= required_fps:
                chosen = {
                    "model": m_name,
                    "freq_mhz": freq,
                    "status": "PASS",
                    "fps": fps,
                    "power_mw": power,
                    "margin": fps / args.target_fps,
                    "note": r.get("note", "")
                }
                break # Pick lowest qualifying clock

        if chosen:
            results.append(chosen)
        else:
            # Check why failed
            best_pass = [r for r in rows_sorted if r["status"] == "PASS" and int(r["freq_mhz"]) <= args.max_freq]
            reason = "No PASS row meets FPS requirement or power <= 9000 mW"
            if best_pass:
                max_fps = max(float(r["fps"]) for r in best_pass)
                max_power = max(float(r["power_mw"]) for r in best_pass)
                reason = f"Max FPS: {max_fps:.1f} (need {required_fps:.1f}), Peak Power: {max_power:.0f} mW"

            results.append({
                "model": m_name,
                "freq_mhz": "N/A",
                "status": "NOT RECOMMENDED",
                "fps": 0.0,
                "power_mw": 0.0,
                "margin": 0.0,
                "note": reason
            })

    # Print results
    if args.csv:
        writer = csv.DictWriter(sys.stdout, fieldnames=["model", "freq_mhz", "status", "fps", "power_mw", "margin", "note"])
        writer.writeheader()
        writer.writerows(results)
    else:
        print(f"==========================================================================================")
        print(f"ProAI77 MX3 Model & Frequency Query (Target: {args.target_fps:.1f} fps | Need >= {required_fps:.1f} fps | Max Power <= {args.max_power_mw:.0f} mW)")
        print(f"==========================================================================================")
        print(f"{'Model':<45} | {'Clock':<7} | {'Status':<15} | {'FPS':<7} | {'Power (mW)':<10} | {'Margin'}")
        print(f"-" * 98)
        for r in results:
            if r["status"] == "PASS":
                print(f"{r['model'][:45]:<45} | {str(r['freq_mhz']) + 'MHz':<7} | {r['status']:<15} | {r['fps']:<7.1f} | {r['power_mw']:<10.1f} | {r['margin']:.2f}x")
            else:
                print(f"{r['model'][:45]:<45} | {'--':<7} | {r['status']:<15} | {'--':<7} | {'--':<10} | {r['note'][:25]}")
        print(f"==========================================================================================")

    return 0

if __name__ == "__main__":
    sys.exit(main())
