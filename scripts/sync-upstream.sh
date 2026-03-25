#!/bin/bash
# sync-upstream.sh - 同步上游仓库更新

set -e

echo "🔄 开始同步上游更新..."

# 确保 upstream remote 存在
git remote add upstream https://github.com/anthropics/knowledge-work-plugins.git 2>/dev/null || true

# 获取上游更新
echo "📥 获取 upstream/main..."
git fetch upstream

# 切换到 main 分支
echo "🔀 切换到 main 分支..."
git checkout main

# 合并上游变更
echo "🔗 合并上游变更..."
git merge upstream/main

# 推送更新
echo "📤 推送到 origin..."
git push origin main

echo "✅ 同步完成！"
