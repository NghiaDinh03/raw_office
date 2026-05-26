#!/usr/bin/env python3
import urllib.request
import zipfile
import io
import os
import sys

def download_file(url, target_dir, target_name):
    os.makedirs(target_dir, exist_ok=True)
    target_path = os.path.join(target_dir, target_name)
    if not os.path.exists(target_path):
        print(f"=== Downloading Linux {target_name} binary ===")
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req) as response:
                zip_data = response.read()
            with zipfile.ZipFile(io.BytesIO(zip_data)) as zip_ref:
                zip_ref.extractall(target_dir)
            os.chmod(target_path, 0o755)
            print(f"=== {target_name} binary downloaded and prepared successfully ===")
        except Exception as e:
            print(f"Error downloading {target_name}: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print(f"=== {target_name} binary already exists ===")

def main():
    # 1. Download gn
    gn_dir = "/onlyoffice/core/Common/3dParty/v8_89/v8/buildtools/linux64/gn"
    gn_url = "https://chrome-infra-packages.appspot.com/dl/gn/gn/linux-amd64/+/latest"
    download_file(gn_url, gn_dir, "gn")

    # 2. Download ninja
    ninja_dir = "/onlyoffice/core/Common/3dParty/v8_89/v8/third_party/ninja"
    ninja_url = "https://github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-linux.zip"
    download_file(ninja_url, ninja_dir, "ninja")

if __name__ == "__main__":
    main()
