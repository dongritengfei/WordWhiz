#!/bin/bash
set -e

APP_NAME="WordWhiz"
APP_PATH="DerivedData/Build/Products/Release/${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"
TEMP_DMG="${APP_NAME}_temp.dmg"

if [ ! -d "${APP_PATH}" ]; then
    echo "错误：找不到 Release 构建产物 ${APP_PATH}"
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

echo "=== 卸载并压缩 DMG ==="
hdiutil detach "${FULL_VOLUME_PATH}"
sleep 1

hdiutil convert "${TEMP_DMG}" -format UDZO -o "${DMG_NAME}"
rm -f "${TEMP_DMG}"

echo "=== 完成 ==="
echo "DMG 文件: $(pwd)/${DMG_NAME}"
ls -lh "${DMG_NAME}"
