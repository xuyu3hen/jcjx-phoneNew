#!/bin/bash
# Flutter 多环境构建脚本
# 使用方法: ./scripts/build.sh [env] [platform] [type]
# 示例: ./scripts/build.sh release android apk

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认参数
ENV=${1:-release}
PLATFORM=${2:-android}
BUILD_TYPE=${3:-apk}

# 验证环境参数
if [[ ! "$ENV" =~ ^(dev|test|release)$ ]]; then
    echo -e "${RED}错误: 无效的环境参数 '$ENV'${NC}"
    echo "可用环境: dev, test, release"
    exit 1
fi

# 验证平台参数
if [[ ! "$PLATFORM" =~ ^(android|ios)$ ]]; then
    echo -e "${RED}错误: 无效的平台参数 '$PLATFORM'${NC}"
    echo "可用平台: android, ios"
    exit 1
fi

# 设置环境变量
case $ENV in
    dev)
        FLAVOR="env_dev"
        MAIN_FILE="lib/main_env_dev.dart"
        APP_NAME="机车检修(本地)"
        ;;
    test)
        FLAVOR="env_test"
        MAIN_FILE="lib/main_env_test.dart"
        APP_NAME="机车检修(测试)"
        ;;
    release)
        FLAVOR="env_release"
        MAIN_FILE="lib/main_env_release.dart"
        APP_NAME="机车检修"
        ;;
esac

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}开始构建 Flutter 应用${NC}"
echo -e "${GREEN}========================================${NC}"
echo "环境: $ENV ($FLAVOR)"
echo "平台: $PLATFORM"
echo "类型: $BUILD_TYPE"
echo "主文件: $MAIN_FILE"
echo ""

# 获取版本号
VERSION=$(grep -E '^version:' pubspec.yaml | sed 's/version: //')
echo -e "${YELLOW}当前版本: $VERSION${NC}"
echo ""

# 清理旧的构建
echo -e "${YELLOW}清理旧的构建文件...${NC}"
flutter clean

# 获取依赖
echo -e "${YELLOW}获取 Flutter 依赖...${NC}"
flutter pub get

# 构建
echo -e "${YELLOW}开始构建...${NC}"

if [ "$PLATFORM" == "android" ]; then
    if [ "$BUILD_TYPE" == "apk" ]; then
        # 构建 APK
        flutter build apk \
            --flavor $FLAVOR \
            -t $MAIN_FILE \
            --target-platform android-arm,android-arm64 \
            --no-tree-shake-icons \
            --release
        
        # 输出文件路径
        OUTPUT_FILE="build/app/outputs/flutter-apk/app-$FLAVOR-release.apk"
        OUTPUT_DIR="build/app/outputs/flutter-apk/"
        
    elif [ "$BUILD_TYPE" == "appbundle" ]; then
        # 构建 App Bundle
        flutter build appbundle \
            --flavor $FLAVOR \
            -t $MAIN_FILE \
            --no-tree-shake-icons \
            --release
        
        OUTPUT_FILE="build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab"
        OUTPUT_DIR="build/app/outputs/bundle/${FLAVOR}Release/"
    else
        echo -e "${RED}错误: 不支持的构建类型 '$BUILD_TYPE'${NC}"
        echo "Android 支持的构建类型: apk, appbundle"
        exit 1
    fi
elif [ "$PLATFORM" == "ios" ]; then
    if [ "$BUILD_TYPE" == "ipa" ]; then
        # 构建 IPA (需要配置签名)
        flutter build ipa \
            --flavor $FLAVOR \
            -t $MAIN_FILE \
            --release
        
        OUTPUT_FILE="build/ios/ipa/*.ipa"
        OUTPUT_DIR="build/ios/ipa/"
    else
        echo -e "${RED}错误: 不支持的构建类型 '$BUILD_TYPE'${NC}"
        echo "iOS 支持的构建类型: ipa"
        exit 1
    fi
fi

# 检查构建结果
if [ -f "$OUTPUT_FILE" ] || [ -d "$OUTPUT_DIR" ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}构建成功！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo "输出文件: $OUTPUT_FILE"
    echo "输出目录: $OUTPUT_DIR"
    
    # 显示文件大小
    if [ -f "$OUTPUT_FILE" ]; then
        FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
        echo "文件大小: $FILE_SIZE"
    fi
    
    echo ""
    echo -e "${YELLOW}提示: 构建文件已生成，可以开始分发${NC}"
else
    echo -e "${RED}错误: 构建失败，未找到输出文件${NC}"
    exit 1
fi
