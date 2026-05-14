#!/bin/bash
# 每天首次触发时同步配置（由 SessionStart hook 调用）
# 退出码: 0=成功或跳过, 2=冲突需 AI 介入

STAMP="$HOME/.claude/.last-sync"
TODAY=$(date +%Y-%m-%d)
REPO="$HOME/claude-config"

# 今天已经同步过则跳过
if [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$TODAY" ]; then
  exit 0
fi

cd "$REPO"

# 1. 拉取远端变更（冲突时通知 AI）
if ! git pull --rebase --quiet 2>&1; then
  echo "[sync] 远端冲突，需要 AI 介入处理"
  echo "[sync] 冲突文件："
  git diff --name-only --diff-filter=U 2>/dev/null || true
  exit 2
fi

# 2. 远端配置写入 ~/.claude/
./sync.sh pull

# 3. 推送本机变更
./sync.sh push
git add -A
if ! git diff --cached --quiet; then
  git commit -m "auto sync $TODAY" --quiet
  if ! git push --quiet 2>&1; then
    echo "[sync] 推送失败，请检查网络或权限"
    exit 2
  fi
fi

# 4. 标记今日已同步
echo "$TODAY" > "$STAMP"
