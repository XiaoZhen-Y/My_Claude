#!/bin/bash
# 每日首次启动时自动同步 Claude Code 配置
set -e

STAMP="$HOME/.claude/.last-sync"
TODAY=$(date +%Y-%m-%d)
REPO="$HOME/claude-config"

if [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$TODAY" ]; then
  exit 0
fi

echo "[sync] 开始每日配置同步..."

# 1. 拉取远端
cd "$REPO"
if ! git pull --rebase --quiet 2>&1; then
  echo "[sync] 远端冲突，需要 AI 介入处理"
  git rebase --abort 2>/dev/null || true
  exit 2
fi

# 2. 本地 → repo
./sync.sh push

# 3. 检查是否有变更需要推送
git add -A
if git diff --cached --quiet; then
  echo "[sync] 配置无变化"
else
  git commit -m "auto sync $TODAY"
  git push
  echo "[sync] 已推送到远端"
fi

# 4. 标记今日已同步
echo "$TODAY" > "$STAMP"
echo "[sync] 完成"
