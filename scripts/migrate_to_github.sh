#!/bin/bash
# 从 Gitee 迁移到 GitHub 的辅助脚本
# 使用方法: ./scripts/migrate_to_github.sh [github_repo_url]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GITHUB_URL=$1

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Gitee 到 GitHub 迁移助手${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查参数
if [ -z "$GITHUB_URL" ]; then
    echo -e "${YELLOW}请输入 GitHub 仓库 URL${NC}"
    echo "使用方法: ./scripts/migrate_to_github.sh https://github.com/USERNAME/REPO.git"
    echo ""
    read -p "GitHub 仓库 URL: " GITHUB_URL
fi

# 验证 URL 格式
if [[ ! "$GITHUB_URL" =~ ^https://github.com/ ]] && [[ ! "$GITHUB_URL" =~ ^git@github.com: ]]; then
    echo -e "${RED}错误: GitHub URL 格式不正确${NC}"
    echo "应该是: https://github.com/USERNAME/REPO.git 或 git@github.com:USERNAME/REPO.git"
    exit 1
fi

echo -e "${YELLOW}[1/6] 检查 Git 状态...${NC}"
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}警告: 工作区有未提交的更改${NC}"
    read -p "是否继续? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo -e "${GREEN}✓ Git 状态检查完成${NC}"
echo ""

echo -e "${YELLOW}[2/6] 查看当前远程仓库...${NC}"
git remote -v
echo ""

echo -e "${YELLOW}[3/6] 检查是否已存在 github 远程仓库...${NC}"
if git remote | grep -q "^github$"; then
    echo -e "${YELLOW}已存在 github 远程仓库，是否更新? (y/n)${NC}"
    read -p "" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git remote set-url github "$GITHUB_URL"
        echo -e "${GREEN}✓ 已更新 github 远程仓库 URL${NC}"
    else
        echo -e "${YELLOW}跳过添加 github 远程仓库${NC}"
    fi
else
    git remote add github "$GITHUB_URL"
    echo -e "${GREEN}✓ 已添加 github 远程仓库${NC}"
fi
echo ""

echo -e "${YELLOW}[4/6] 验证远程仓库连接...${NC}"
if git ls-remote --heads github &>/dev/null; then
    echo -e "${GREEN}✓ GitHub 仓库连接成功${NC}"
else
    echo -e "${RED}错误: 无法连接到 GitHub 仓库${NC}"
    echo "请检查:"
    echo "  1. URL 是否正确"
    echo "  2. 是否有访问权限"
    echo "  3. 是否已配置认证（SSH 密钥或 Personal Access Token）"
    exit 1
fi
echo ""

echo -e "${YELLOW}[5/6] 查看所有分支和标签...${NC}"
echo "本地分支:"
git branch
echo ""
echo "远程分支:"
git branch -r
echo ""
echo "标签:"
git tag -l
echo ""

echo -e "${YELLOW}[6/6] 准备推送...${NC}"
read -p "是否推送所有分支和标签到 GitHub? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}推送所有分支...${NC}"
    git push github --all || {
        echo -e "${RED}推送分支失败，尝试逐个推送${NC}"
        for branch in $(git branch | sed 's/^[ *]*//'); do
            echo "推送分支: $branch"
            git push github "$branch" || echo -e "${YELLOW}分支 $branch 推送失败，跳过${NC}"
        done
    }
    
    echo -e "${YELLOW}推送所有标签...${NC}"
    git push github --tags || {
        echo -e "${RED}推送标签失败${NC}"
    }
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}迁移完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "下一步:"
    echo "1. 在 GitHub 上验证所有分支和标签"
    echo "2. 启用 GitHub Actions"
    echo "3. 更新文档中的链接"
    echo "4. 通知团队成员更新仓库地址"
else
    echo -e "${YELLOW}已取消推送${NC}"
    echo ""
    echo "手动推送命令:"
    echo "  git push github --all      # 推送所有分支"
    echo "  git push github --tags      # 推送所有标签"
fi

echo ""
echo -e "${BLUE}当前远程仓库配置:${NC}"
git remote -v
