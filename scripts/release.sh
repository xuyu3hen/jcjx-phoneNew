#!/bin/bash
# 自动化发布流程脚本
# 使用方法: ./scripts/release.sh [version_type]
# version_type: patch, minor, major (默认: patch)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERSION_TYPE=${1:-patch}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}自动化发布流程${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 检查工作区是否干净
echo -e "${YELLOW}[1/6] 检查 Git 工作区...${NC}"
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${RED}错误: 工作区有未提交的更改${NC}"
    echo "请先提交或暂存所有更改"
    exit 1
fi
echo -e "${GREEN}✓ 工作区干净${NC}"
echo ""

# 2. 运行测试（如果有）
echo -e "${YELLOW}[2/6] 运行测试...${NC}"
if [ -f "test/all_test.dart" ] || [ -d "test" ]; then
    flutter test || {
        echo -e "${RED}测试失败，请修复后再发布${NC}"
        exit 1
    }
    echo -e "${GREEN}✓ 测试通过${NC}"
else
    echo -e "${YELLOW}⚠ 未找到测试文件，跳过测试${NC}"
fi
echo ""

# 3. 更新版本号
echo -e "${YELLOW}[3/6] 更新版本号...${NC}"
dart scripts/bump_version.dart $VERSION_TYPE
NEW_VERSION=$(grep -E '^version:' pubspec.yaml | sed 's/version: //')
echo -e "${GREEN}✓ 版本号已更新为: $NEW_VERSION${NC}"
echo ""

# 4. 提交版本号变更
echo -e "${YELLOW}[4/6] 提交版本号变更...${NC}"
git add pubspec.yaml
git commit -m "chore: 更新版本号到 $NEW_VERSION" || {
    echo -e "${YELLOW}⚠ 没有版本号变更需要提交${NC}"
}
echo -e "${GREEN}✓ 版本号已提交${NC}"
echo ""

# 5. 创建 Git 标签
echo -e "${YELLOW}[5/6] 创建 Git 标签...${NC}"
VERSION_NAME=$(echo $NEW_VERSION | cut -d'+' -f1)
TAG_NAME="v$VERSION_NAME"
git tag -a "$TAG_NAME" -m "发布版本 $VERSION_NAME" || {
    echo -e "${RED}错误: 标签可能已存在${NC}"
    exit 1
}
echo -e "${GREEN}✓ 标签已创建: $TAG_NAME${NC}"
echo ""

# 6. 推送代码和标签
echo -e "${YELLOW}[6/6] 推送代码和标签...${NC}"
read -p "是否推送到远程仓库? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push
    git push --tags
    echo -e "${GREEN}✓ 代码和标签已推送${NC}"
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}发布流程完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "下一步:"
    echo "1. CI/CD 将自动触发构建"
    echo "2. 检查构建状态: $CI_URL (如果配置了 CI)"
    echo "3. 下载构建产物并测试"
    echo "4. 如果一切正常，创建 GitHub/GitLab Release"
else
    echo -e "${YELLOW}⚠ 已跳过推送，请稍后手动推送${NC}"
    echo "推送命令:"
    echo "  git push"
    echo "  git push --tags"
fi
