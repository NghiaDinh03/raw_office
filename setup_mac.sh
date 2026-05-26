#!/bin/bash

# Script tự động cài đặt môi trường biên dịch ONLYOFFICE Desktop Editors trên macOS mới.
# Hướng dẫn chạy trên máy Mac:
#   1. Chép file này sang máy Mac mới.
#   2. Mở Terminal tại thư mục chứa file.
#   3. Chạy lệnh: chmod +x setup_mac.sh && ./setup_mac.sh

echo "================================================================="
echo " BẮT ĐẦU CÀI ĐẶT MÔI TRƯỜNG BIÊN DỊCH ONLYOFFICE TRÊN MACOS      "
echo "================================================================="

# 1. Kiểm tra hệ điều hành
if [ "$(uname)" != "Darwin" ]; then
    echo "Lỗi: Script này chỉ hỗ trợ chạy trên hệ điều hành macOS!"
    exit 1
fi

# 2. Cài đặt Xcode Command Line Tools
echo -e "\n>>> 1. Kiểm tra Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
    echo "Xcode Command Line Tools đã được cài đặt."
else
    echo "Đang tiến hành cài đặt Xcode Command Line Tools..."
    xcode-select --install
    echo "Vui lòng hoàn tất cửa sổ cài đặt Xcode xuất hiện trên màn hình trước khi nhấn tiếp tục..."
    read -p "Sau khi cài đặt xong Xcode Command Line Tools, nhấn Enter để tiếp tục..."
fi

# 3. Cài đặt Homebrew
echo -e "\n>>> 2. Kiểm tra và cài đặt Homebrew..."
if command -v brew &>/dev/null; then
    echo "Homebrew đã được cài đặt."
else
    echo "Đang cài đặt Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Cấu hình PATH cho Homebrew tùy theo chip Intel hoặc Apple Silicon
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
    fi
fi

# 4. Cài đặt các package cần thiết qua Homebrew
echo -e "\n>>> 3. Cài đặt các biên dịch viên và công cụ lập trình..."
brew update
brew install git python cmake ninja autoconf automake libtool pkg-config node

# 5. Cài đặt Python aqtinstall để cài đặt Qt tự động
echo -e "\n>>> 4. Cài đặt aqtinstall (công cụ tải Qt nhanh)..."
pip3 install --upgrade pip
pip3 install aqtinstall

# 6. Cài đặt Qt Framework qua aqt
echo -e "\n>>> 5. Tải và cài đặt Qt Framework..."
# Thư mục cài đặt Qt sẽ nằm ở thư mục hiện tại/Qt_SDK
QT_VERSION="5.15.2"
QT_DIR="$HOME/Qt_SDK"
if [ ! -d "$QT_DIR" ]; then
    mkdir -p "$QT_DIR"
    echo "Đang tải Qt $QT_VERSION về thư mục $QT_DIR..."
    aqt install-qt --outputdir "$QT_DIR" mac desktop "$QT_VERSION" clang_64
else
    echo "Thư mục Qt_SDK đã tồn tại tại $QT_DIR."
fi

# 7. Cài đặt các công cụ đóng gói Node.js & Ruby
echo -e "\n>>> 6. Cài đặt Bundler cho Ruby và appdmg cho Node.js..."
gem install bundler
npm install -g appdmg

echo "================================================================="
echo " CÀI ĐẶT HOÀN TẤT!                                               "
echo "================================================================="
echo "Để biên dịch ONLYOFFICE:"
echo "1. Cấu hình đường dẫn Qt compiler cho build_tools:"
echo "   Đường dẫn Qmake của bạn nằm tại: $QT_DIR/$QT_VERSION/clang_64"
echo "2. Lệnh ví dụ để biên dịch Core:"
echo "   python configure.py --platform mac_arm64 --qt-dir $QT_DIR/$QT_VERSION --module desktop"
echo "   python make.py"
echo "3. Lệnh ví dụ để đóng gói native app và DMG:"
echo "   cd desktop-apps/macos && bundle install"
echo "   bundle exec fastlane release_arm"
echo "================================================================="
