#!/bin/bash
set -e

APP_NAME="WordWhiz"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DMG_NAME="${APP_NAME}.dmg"
TEMP_DMG="${APP_NAME}_temp.dmg"
ICON_ICNS="${SCRIPT_DIR}/WordWhiz.icns"

# 默认使用 Release 构建
APP_PATH="${SCRIPT_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app"
if [ ! -d "${APP_PATH}" ] || [ ! -f "${APP_PATH}/Contents/Resources/Assets.car" ]; then
    echo "=== 执行 Release 构建 ==="
    xcodebuild -project "${SCRIPT_DIR}/WordWhiz.xcodeproj" -scheme WordWhiz -configuration Release \
        -derivedDataPath "${SCRIPT_DIR}/DerivedData" build 2>&1 | tail -5
fi

# 回退到 Debug（仅当 Release 构建失败时）
if [ ! -d "${APP_PATH}" ] || [ ! -f "${APP_PATH}/Contents/Resources/Assets.car" ]; then
    APP_PATH="${SCRIPT_DIR}/DerivedData/Build/Products/Debug/${APP_NAME}.app"
    if [ -d "${APP_PATH}" ]; then
        echo "警告: Release 构建不存在或不完整，使用 Debug 构建"
    fi
fi

if [ ! -d "${APP_PATH}" ]; then
    echo "错误：找不到构建产物 ${APP_PATH}"
    echo "请先运行: xcodebuild -project WordWhiz.xcodeproj -scheme WordWhiz -configuration Release -derivedDataPath ./DerivedData build"
    exit 1
fi

# 验证构建产物包含图标资源
if [ ! -f "${APP_PATH}/Contents/Resources/Assets.car" ]; then
    echo "错误：构建产物缺少 Assets.car 图标资源"
    exit 1
fi

# 清理旧的 WordWhiz 挂载（避免卷名冲突导致只读挂载）
echo "=== 清理旧挂载 ==="
hdiutil info | grep -B1 "WordWhiz" | grep "^/dev/" | awk '{print $1}' | while read -r disk; do
    hdiutil detach "$disk" -force 2>/dev/null || true
done

echo "=== 创建临时 DMG ==="
APP_SIZE=$(du -sm "${APP_PATH}" | cut -f1)
DMG_SIZE=$((APP_SIZE + 10))

rm -f "${DMG_NAME}" "${TEMP_DMG}"
hdiutil create -size "${DMG_SIZE}m" -fs HFS+ -volname "${APP_NAME}" "${TEMP_DMG}"

echo "=== 挂载 DMG ==="
# 从 hdiutil attach 输出提取挂载路径（兼容空格卷名）
FULL_VOLUME_PATH=$(hdiutil attach "${TEMP_DMG}" -nobrowse | awk '/\/Volumes\// {i=index($0,"/Volumes/"); print substr($0,i); exit}')
if [ -z "${FULL_VOLUME_PATH}" ]; then
    echo "错误：无法获取挂载路径"
    exit 1
fi
echo "挂载路径: ${FULL_VOLUME_PATH}"

echo "=== 复制应用到 DMG ==="
cp -R "${APP_PATH}" "${FULL_VOLUME_PATH}/"

echo "=== 创建 Applications 链接 ==="
ln -s /Applications "${FULL_VOLUME_PATH}/Applications"

echo "=== 设置 DMG 卷图标 ==="
if [ -f "${ICON_ICNS}" ]; then
    cp "${ICON_ICNS}" "${FULL_VOLUME_PATH}/.VolumeIcon.icns"
    SetFile -a C "${FULL_VOLUME_PATH}"
    echo "图标已设置"
else
    echo "警告: 未找到图标文件 ${ICON_ICNS}"
fi

echo "=== 卸载并压缩 DMG ==="
hdiutil detach "${FULL_VOLUME_PATH}"
sleep 1

hdiutil convert "${TEMP_DMG}" -format UDZO -o "${DMG_NAME}"
rm -f "${TEMP_DMG}"

echo "=== 设置 DMG 文件图标 ==="
osascript -l JavaScript <<JXAEOF
ObjC.import('Cocoa');
var image = $.NSImage.alloc.initWithContentsOfFile('${ICON_ICNS}');
var ws = $.NSWorkspace.sharedWorkspace;
ws.setIconForFileOptions(image, '$(pwd)/${DMG_NAME}', 0);
JXAEOF

echo "=== 完成 ==="
echo "DMG 文件: $(pwd)/${DMG_NAME}"
ls -lh "${DMG_NAME}"
