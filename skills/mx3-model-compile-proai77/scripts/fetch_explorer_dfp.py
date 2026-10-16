#!/usr/bin/env python3
"""
Downloads pre-compiled DFP models from MemryX Model Explorer (SDK 2.2).
URL Pattern: https://developer.memryx.com/model_explorer/2p2/<Model_Name>.zip
"""
import os
import sys
import argparse
import urllib.request
import zipfile

BASE_URL = "https://developer.memryx.com/model_explorer/2p2"

def download_and_extract(model_name, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    clean_name = model_name.strip('"').strip()
    zip_url = f"{BASE_URL}/{clean_name}.zip"
    zip_path = os.path.join(output_dir, f"{clean_name}.zip")

    print(f"Downloading from: {zip_url} ...")
    try:
        urllib.request.urlretrieve(zip_url, zip_path)
        print(f"[OK] Downloaded: {zip_path}")
        
        with zipfile.ZipFile(zip_path, 'r') as z:
            z.extractall(output_dir)
            print(f"[OK] Extracted contents to {output_dir}:")
            for name in z.namelist():
                print(f"  - {name}")
        
        os.remove(zip_path)
        print("[SUCCESS] Model extraction completed.")
        return 0
    except Exception as e:
        print(f"[ERROR] Failed to download or extract {zip_url}: {e}", file=sys.stderr)
        return 1

def main():
    parser = argparse.ArgumentParser(description="Fetch pre-compiled DFP from MemryX Model Explorer")
    parser.add_argument("-m", "--model", required=True, help="Model name (e.g. 'YOLO26_nano_640_640_3_onnx')")
    parser.add_argument("-o", "--out", default="./models", help="Output directory (default: ./models)")
    args = parser.parse_args()

    return download_and_extract(args.model, args.out)

if __name__ == "__main__":
    sys.exit(main())
