#!/bin/bash
# generate-pkgbuild.sh

set -e

RELEASE_TAG="$1"
if [ -z "$RELEASE_TAG" ]; then
    echo "错误：未提供版本号参数"
    exit 1
fi

# 验证版本号格式
if [[ ! "$RELEASE_TAG" =~ ^[0-9]{8}$ ]]; then
    echo "错误：版本号 '$RELEASE_TAG' 不是纯日期格式"
    exit 1
fi

DOWNLOAD_URL="https://github.com/TC999/zed-loc/releases/download/$RELEASE_TAG/zed-linux-x86_64.tar.gz"

echo "正在计算文件校验和..."
NEW_SHA512=$(curl -L -f "$DOWNLOAD_URL" | sha512sum | awk '{print $1}')
echo "版本: $RELEASE_TAG"
echo "SHA512: $NEW_SHA512"

# 生成 PKGBUILD 文件
cat > PKGBUILD << EOF
# Maintainer: li0shang <li0shang@163.com>
pkgname="zed-cn"
pkgver=$RELEASE_TAG
_path="zed-dev"
pkgrel=1
pkgdesc=" zed-loc (Zed 汉化) github-TC999/zed-loc"
arch=('x86_64')
license=('custom:"Copyright (c) 2015 Abner Lee All Rights Reserved."')
url="https://github.com/TC999/zed-loc"
provides=("\\$pkgname")
conflicts=("\\$pkgname")
source=("\\$pkgname-\\$pkgver.tar.gz::$DOWNLOAD_URL")
sha512sums=('$NEW_SHA512')

# 解压源码包
prepare() {
  tar -xzf "\\$pkgname-\\$pkgver.tar.gz"
}

# 安装到 /opt
package() {
  # 创建目标目录
  install -d "\\$pkgdir/opt/\\$pkgname"
  
  # 复制所有文件到 /opt/软件名
  cp -r "\\$srcdir/\\$_path.app/"* "\\$pkgdir/opt/\\$pkgname/"
  
  # 设置权限（可选）
  # find "\\$pkgdir/opt/\\$pkgname" -type d -exec chmod 755 {} \\;
  # find "\\$pkgdir/opt/\\$pkgname" -type f -exec chmod 644 {} \\;
  
  # 如果需要：添加可执行文件到系统路径
  install -d "\\$pkgdir/usr/bin"
  ln -s "/opt/\\$pkgname/bin/zed" "\\$pkgdir/usr/bin/zed"
  # 安装图标文件
  _icon_sizes=("512x512" "1024x1024")
  for size in "\\\${_icon_sizes[@]}"; do
    if [ -f "\\$srcdir/\\$_path.app/share/icons/hicolor/\\$size/apps/zed.png" ]; then
      install -Dm644 "\\$srcdir/\\$_path.app/share/icons/hicolor/\\$size/apps/zed.png" \\
        "\\$pkgdir/usr/share/icons/hicolor/\\$size/apps/zed-cn.png"
    fi
  done
  # 如果需要：桌面文件
  install -Dm644 "\\$srcdir/\\$_path.app/share/applications/\\$_path.desktop" "\\$pkgdir/usr/share/applications/zed-cn.desktop"

  # 移除调试符号（避免生成debug包）
  find "\\$pkgdir" -name "*.debug" -delete
  strip --strip-all "\\$pkgdir/opt/\\$pkgname/bin/zed" 2>/dev/null || true
  strip --strip-all "\\$pkgdir/opt/\\$pkgname/libexec/zed-editr" 2>/dev/null || true
  
}
# 明确指定不构建debug包
options=('!debug')
EOF

echo "PKGBUILD 生成完成："
cat PKGBUILD
