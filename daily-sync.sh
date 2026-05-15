#!/bin/bash
# 每日首次启动时通知 AI 执行配置同步
STAMP="$HOME/.claude/.last-sync"
TODAY=$(date +%Y-%m-%d)

if [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$TODAY" ]; then
  exit 0
fi

echo "[sync] 今日配置同步待执行"
exit 2
