#!/bin/bash
echo "=== DOCKER STARTUP OPTIMIZATION ==="

HOST_DEPOT_TOOLS="/onlyoffice/core/Common/3dParty/v8_89/depot_tools"
LOCAL_DEPOT_TOOLS="/root/depot_tools"

# 1. Khoi tao volume ao depot_tools tu du lieu goc neu trong
if [ -z "$(ls -A "$LOCAL_DEPOT_TOOLS" 2>/dev/null)" ]; then
    echo "Khoi tao volume ao depot_tools tu du lieu goc tren Host..."
    mkdir -p "$LOCAL_DEPOT_TOOLS"
    if [ -d "$HOST_DEPOT_TOOLS" ]; then
        cp -a "$HOST_DEPOT_TOOLS/." "$LOCAL_DEPOT_TOOLS/"
        echo "Da sao chep du lieu depot_tools thanh cong!"
    else
        echo "Canh bao: Khong tim thay thu muc depot_tools goc!"
    fi
fi

# Luon dong bo file python-bin/python3 sieu toi uu tu Host vao Volume de dam bao su dung Python he thong Linux native
if [ -f "$HOST_DEPOT_TOOLS/python-bin/python3" ]; then
    echo "Dong bo python3 sieu toi uu tu Host vao Volume..."
    mkdir -p "$LOCAL_DEPOT_TOOLS/python-bin"
    cp -f "$HOST_DEPOT_TOOLS/python-bin/python3" "$LOCAL_DEPOT_TOOLS/python-bin/python3"
fi

# 2. Anh xa volume ao depot_tools qua mount --bind de toi uu hieu nang I/O
echo "Anh xa volume ao depot_tools..."
mount --bind "$LOCAL_DEPOT_TOOLS" "$HOST_DEPOT_TOOLS"
if [ $? -eq 0 ]; then
    echo "Da anh xa thanh cong volume ao qua mount --bind!"
else
    echo "Khong the thuc hien mount --bind. Thu phuong an di chuyen vat ly..."
    if [ -d "$HOST_DEPOT_TOOLS" ] && [ ! -L "$HOST_DEPOT_TOOLS" ]; then
        rm -rf "$HOST_DEPOT_TOOLS"
        ln -s "$LOCAL_DEPOT_TOOLS" "$HOST_DEPOT_TOOLS"
        echo "Da tao lien ket mem sang volume ao!"
    fi
fi

# Chay script fix quyen thuc thi
bash fix_crlf.sh

# Cai dat ninja-build, cmake, nodejs va npm he thong
echo "=== Installing system ninja-build, cmake, nodejs and npm ==="
apt-get update && apt-get install -y ninja-build cmake nodejs npm

# Cai dat grunt-cli global de phuc vu dong goi web-apps/sdkjs
echo "=== Installing global grunt-cli ==="
npm install -g grunt-cli

# Ghi de cmake he thong bang mot bash script wrapper de tranh loi GLIBCXX tu sysroot
echo "=== Enforcing system cmake wrapper ==="
if [ ! -f /usr/bin/cmake.real ]; then
    mv /usr/bin/cmake /usr/bin/cmake.real
fi
cat << 'EOF' > /usr/bin/cmake
#!/bin/bash
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6
exec /usr/bin/cmake.real "$@"
EOF
chmod +x /usr/bin/cmake

# Tai gn binary tu dong neu chua co
echo "Kiem tra va tai gn binary..."
python3 download_gn.py

# Ghi de file ninja bi loi bang mot bash script wrapper sieu thong minh de tranh loi GLIBCXX tu sysroot
echo "=== Enforcing system ninja wrapper ==="
mkdir -p /onlyoffice/core/Common/3dParty/v8_89/v8/third_party/ninja
cat << 'EOF' > /onlyoffice/core/Common/3dParty/v8_89/v8/third_party/ninja/ninja
#!/bin/bash
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6
exec /usr/bin/ninja "$@"
EOF
chmod +x /onlyoffice/core/Common/3dParty/v8_89/v8/third_party/ninja/ninja

# Thiet lap pkg-config cho sysroot de bien dich cheo dung chuan (tranh loi thieu gtk+-3.0)
SYSROOT_DIR="/onlyoffice/build_tools/tools/linux/sysroot/ubuntu16-amd64-sysroot"
if [ ! -d "$SYSROOT_DIR" ]; then
    SYSROOT_DIR="/onlyoffice/build_tools/tools/linux/sysroot/ubuntu16-arm64-sysroot"
fi

if [ -d "$SYSROOT_DIR" ]; then
    export PKG_CONFIG_SYSROOT_DIR="$SYSROOT_DIR"
    export PKG_CONFIG_LIBDIR=""
    for pc_dir in "/usr/lib/pkgconfig" "/usr/lib/x86_64-linux-gnu/pkgconfig" "/usr/lib/aarch64-linux-gnu/pkgconfig" "/usr/share/pkgconfig"; do
        if [ -d "$SYSROOT_DIR$pc_dir" ]; then
            if [ -z "$PKG_CONFIG_LIBDIR" ]; then
                PKG_CONFIG_LIBDIR="$SYSROOT_DIR$pc_dir"
            else
                PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR:$SYSROOT_DIR$pc_dir"
            fi
        fi
    done
    echo "=== Pkg-config sysroot configuration active ==="
    echo "PKG_CONFIG_SYSROOT_DIR: $PKG_CONFIG_SYSROOT_DIR"
    echo "PKG_CONFIG_LIBDIR: $PKG_CONFIG_LIBDIR"
fi

echo "Khoi chay tien trinh bien dich OnlyOffice..."
python3 -u automate.py desktop --update=0 --clean=0 && python3 -u ../../make_package.py -P linux_x86_64 -T desktop
