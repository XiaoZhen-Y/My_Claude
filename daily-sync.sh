#!/bin/bash
# 每天首次触发时同步配置（由 UserPromptSubmit hook 调用）
set -e

STAMP="$HOME/.claude/.last-sync"
TODAY=$(date +%Y-%m-%d)
REPO="$HOME/claude-config"

# 今天已经同步过则跳过
if [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$TODAY" ]; then
  exit 0
fi

cd "$REPO"

# 1. 拉取远端变更
git pull --rebase --quiet 2>/dev/null || true

# 2. 远端配置写入 ~/.claude/
./sync.sh pull

# 3. 推送本机变更
./sync.sh push
git add -A
if ! git diff --cached --quiet; then
  git commit -m "auto sync $TODAY" --quiet
  git push --quiet 2>/dev/null || true
fi

# 4. 标记今日已同步
echo "$TODAY" > "$STAMP"
