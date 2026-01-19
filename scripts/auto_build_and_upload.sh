#!/bin/bash
# 本地自动打包并上传到内网分发服务器 (Linux/macOS)
# 使用方法: ./scripts/auto_build_and_upload.sh [env] [version_type] [server_url]
# 示例: ./scripts/auto_build_and_upload.sh release patch https://10.102.12.211:8443

set -e

# 默认参数
ENV=${1:-release}
VERSION_TYPE=${2:-patch}
SERVER_URL=${3:-https://10.102.12.211:8443}

# 验证环境参数
if [[ ! "$ENV" =~ ^(dev|test|release)$ ]]; then
    echo "错误: 无效的环境参数 '$ENV'"
    echo "可用环境: dev, test, release"
    exit 1
fi

echo "========================================"
echo "本地自动打包并上传到内网服务器"
echo "========================================"
echo "环境: $ENV"
echo "版本类型: $VERSION_TYPE"
echo "服务器地址: $SERVER_URL"
echo ""

# 设置环境变量
case $ENV in
    dev)
        FLAVOR=env_dev
        MAIN_FILE=lib/main_env_dev.dart
        APP_NAME="机车检修(本地)"
        ;;
    test)
        FLAVOR=env_test
        MAIN_FILE=lib/main_env_test.dart
        APP_NAME="机车检修(测试)"
        ;;
    release)
        FLAVOR=env_release
        MAIN_FILE=lib/main_env_release.dart
        APP_NAME="机车检修"
        ;;
esac

# 1. 更新版本号
echo "[1/5] 更新版本号..."
dart scripts/bump_version.dart $VERSION_TYPE

# 读取新版本号
NEW_VERSION=$(grep -E "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
VERSION_NAME=$(echo $NEW_VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $NEW_VERSION | cut -d'+' -f2)
echo "✓ 版本号已更新为: $NEW_VERSION (版本名: $VERSION_NAME, 构建号: $BUILD_NUMBER)"
echo ""

# 2. 清理并获取依赖
echo "[2/5] 清理并获取依赖..."
flutter clean > /dev/null 2>&1
flutter pub get
echo "✓ 依赖已获取"
echo ""

# 3. 构建 APK
echo "[3/5] 构建 APK..."
flutter build apk --flavor $FLAVOR -t $MAIN_FILE --target-platform android-arm,android-arm64 --no-tree-shake-icons --release

# 确定输出文件路径
APK_FILE="build/app/outputs/flutter-apk/app-${FLAVOR}-release.apk"
if [ ! -f "$APK_FILE" ]; then
    echo "错误: 找不到构建的 APK 文件: $APK_FILE"
    exit 1
fi

# 生成带版本号的文件名
APK_NAME="jcjx-phone-${VERSION_NAME}-build${BUILD_NUMBER}-${ENV}.apk"
APK_NEW_PATH="build/app/outputs/flutter-apk/$APK_NAME"

cp "$APK_FILE" "$APK_NEW_PATH"
echo "✓ APK 构建完成: $APK_NEW_PATH"
echo ""

# 4. 上传到服务器
echo "[4/5] 上传 APK 到服务器..."
if command -v curl &> /dev/null; then
    RESPONSE=$(curl -k -X POST "${SERVER_URL}/api/apk/upload" \
        -F "file=@${APK_NEW_PATH}" \
        -F "version=${VERSION_NAME}" \
        -F "buildNumber=${BUILD_NUMBER}" \
        -F "env=${ENV}" \
        -F "description=自动构建上传" \
        2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✓ APK 已上传到服务器"
        echo "响应: $RESPONSE"
    else
        echo "⚠ 上传失败: $RESPONSE"
        echo "请手动上传 APK 文件: $APK_NEW_PATH"
    fi
else
    echo "⚠ curl 未安装，请手动上传 APK 文件"
    echo "APK 文件位置: $APK_NEW_PATH"
    echo "服务器地址: ${SERVER_URL}/api/apk/upload"
fi
echo ""

# 5. 提交版本号变更（可选）
echo "[5/5] 提交版本号变更到 Git..."
read -p "是否提交版本号变更到 Git? (y/n) " COMMIT
if [[ "$COMMIT" =~ ^[Yy]$ ]]; then
    git add pubspec.yaml
    git commit -m "chore: 自动构建版本 $NEW_VERSION ($ENV环境)"
    echo "✓ 版本号已提交到 Git"
else
    echo "⚠ 已跳过 Git 提交"
fi
echo ""

echo "========================================"
echo "自动打包完成！"
echo "========================================"
echo "APK 文件: $APK_NEW_PATH"
echo "版本号: $NEW_VERSION"
echo "服务器: $SERVER_URL"
echo ""
echo "提示: 请在内网服务器上验证 APK 是否已成功上传"
