#!/bin/bash
echo "=== Cau hinh quyen thuc thi va khu CRLF toan dien ==="

v8_dir="/onlyoffice/core/Common/3dParty/v8_89"
build_tools_dir="/onlyoffice/build_tools"

# 1. Khu CRLF cho cac file o thu muc goc depot_tools (toi uu maxdepth de tranh scan thu muc lon)
echo "Khu CRLF cho cac file trong depot_tools..."
if [ -d "$v8_dir/depot_tools" ]; then
    find "$v8_dir/depot_tools" -maxdepth 1 -type f \( -name "*.sh" -o -name "*.py" -o -name "pylint-*" -o ! -name "*.*" \) -print | while read -r file; do
        filename=$(basename "$file")
        # Loai tru file binary thuc su de tranh lam hong
        if [[ "$filename" == "git" ]] || [[ "$filename" == "python" ]] || [[ "$filename" == "python3" ]]; then
            chmod +x "$file" 2>/dev/null
        else
            sed -i 's/\r$//' "$file" 2>/dev/null
            if head -n 1 "$file" 2>/dev/null | grep -q "^#!"; then
                chmod +x "$file" 2>/dev/null
            fi
        fi
    done
    # Dam bao file python3 trong python-bin luon duoc khu CRLF va co quyen thuc thi
    if [ -f "$v8_dir/depot_tools/python-bin/python3" ]; then
        sed -i 's/\r$//' "$v8_dir/depot_tools/python-bin/python3" 2>/dev/null
        chmod +x "$v8_dir/depot_tools/python-bin/python3" 2>/dev/null
    fi
fi

# 2. Khu CRLF de quy cac script trong build_tools (loai tru sysroot va out de tang toc va tranh loi)
echo "Khu CRLF cho toan bo cac script trong build_tools..."
if [ -d "$build_tools_dir" ]; then
    find "$build_tools_dir" \( -name "sysroot" -o -name "out" -o -name "python3" -o -name ".git" \) -prune -o -type f \( -name "*.sh" -o -name "*.py" \) -print | while read -r file; do
        sed -i 's/\r$//' "$file" 2>/dev/null
        chmod +x "$file" 2>/dev/null
    done
fi

# 3. Cap quyen thuc thi dac biet cho cac file gn va ninja
gn_files=(
    "$v8_dir/depot_tools/gn"
    "$v8_dir/v8/third_party/depot_tools/gn"
    "$v8_dir/v8/third_party/perfetto/tools/gn"
    "$v8_dir/v8/third_party_new/depot_tools/gn"
    "$v8_dir/v8/third_party_new/perfetto/tools/gn"
    "$v8_dir/v8/third_party/ninja/ninja"
)
for gn in "${gn_files[@]}"; do
    if [ -f "$gn" ]; then
        sed -i 's/\r$//' "$gn" 2>/dev/null
        chmod +x "$gn" 2>/dev/null
    fi
done

# 4. Xoa cac file *_reldir.txt cu cua Windows de ep Linux container tu dong thiet lap
echo "Dang don dep cau hinh duong dan cu cua Windows (*_reldir.txt)..."
if [ -d "$v8_dir/depot_tools" ]; then
    find "$v8_dir/depot_tools" -name "*_reldir.txt" -type f -delete
fi

echo "=== Da hoan thanh cau hinh va khu CRLF toan dien ==="
