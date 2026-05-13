#!/bin/bash
set -e

APP_NAME="WordWhiz"
APP_PATH="DerivedData/Build/Products/Debug/${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"
TEMP_DMG="${APP_NAME}_temp.dmg"
ICON_ICNS="/tmp/WordWhiz.icns"

if [ ! -d "${APP_PATH}" ]; then
    echo "错误：找不到构建产物 ${APP_PATH}"
    exit 1
fi

echo "=== 创建临时 DMG ==="
APP_SIZE=$(du -sm "${APP_PATH}" | cut -f1)
DMG_SIZE=$((APP_SIZE + 10))

rm -f "${DMG_NAME}" "${TEMP_DMG}"
hdiutil create -size "${DMG_SIZE}m" -fs HFS+ -volname "${APP_NAME}" "${TEMP_DMG}"

echo "=== 挂载 DMG ==="
hdiutil attach "${TEMP_DMG}" -nobrowse
sleep 1

VOLUME_PATH=$(ls /Volumes | grep "^${APP_NAME}$" | head -1)
if [ -z "${VOLUME_PATH}" ]; then
    VOLUME_PATH=$(ls /Volumes | grep "^${APP_NAME}" | head -1)
fi
FULL_VOLUME_PATH="/Volumes/${VOLUME_PATH}"
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
