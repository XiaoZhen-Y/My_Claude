#!/bin/bash
# Sync Claude Code config between ~/.claude/ and ~/claude-config/
#
# Usage:
#   ./sync.sh push    从 ~/.claude/ 复制到仓库（保存修改）
#   ./sync.sh pull    从仓库复制到 ~/.claude/（部署到本机）
#
# 每个方向都只同步白名单内的文件，不会覆盖 ignores 里的内容。

set -e

REPO="$HOME/claude-config"
CLAUDE="$HOME/.claude"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

say() { echo -e "${GREEN}[sync]${NC} $1"; }
warn() { echo -e "${RED}[sync]${NC} $1"; }

push_one() {
  local src="$1"
  local dst="$2"
  if [ -e "$src" ]; then
    rm -rf "$dst"
    mkdir -p "$(dirname "$dst")"
    cp -r "$src" "$dst"
    say "push: $src -> $dst"
  fi
}

pull_one() {
  local src="$1"
  local dst="$2"
  if [ -e "$src" ]; then
    rm -rf "$dst"
    mkdir -p "$(dirname "$dst")"
    cp -r "$src" "$dst"
    say "pull: $src -> $dst"
  fi
}

sync_root_files() {
  local direction="$1"
  local files=("CLAUDE.md" "settings.json" "launch.json" "scheduled_tasks.json")
  for f in "${files[@]}"; do
    if [ "$direction" = "push" ]; then
      push_one "$CLAUDE/$f" "$REPO/$f"
    else
      pull_one "$REPO/$f" "$CLAUDE/$f"
    fi
  done
}

sync_project_memory() {
  local direction="$1"
  if [ "$direction" = "push" ]; then
    for proj in "$CLAUDE"/projects/*/; do
      [ -d "$proj" ] || continue
      local name
      name=$(basename "$proj")
      if [ -d "$proj/memory" ] && [ -n "$(ls -A "$proj/memory" 2>/dev/null)" ]; then
        push_one "$proj/memory" "$REPO/projects/$name/memory"
      fi
    done
  else
    for proj in "$REPO"/projects/*/; do
      [ -d "$proj" ] || continue
      local name
      name=$(basename "$proj")
      if [ -d "$proj/memory" ] && [ -n "$(ls -A "$proj/memory" 2>/dev/null)" ]; then
        pull_one "$proj/memory" "$CLAUDE/projects/$name/memory"
      fi
    done
  fi
}

sync_skills() {
  local direction="$1"
  if [ "$direction" = "push" ]; then
    # Remove skills from repo that no longer exist in ~/.claude/skills/
    if [ -d "$REPO/skills" ]; then
      for item in "$REPO"/skills/*; do
        [ -e "$item" ] || continue
        local name
        name=$(basename "$item")
        if [ ! -e "$CLAUDE/skills/$name" ]; then
          rm -rf "$item"
          say "removed stale skill: $name"
        fi
      done
    fi
    push_one "$CLAUDE/skills" "$REPO/skills"
  else
    pull_one "$REPO/skills" "$CLAUDE/skills"
  fi
}

sync_scheduled_tasks() {
  local direction="$1"
  if [ "$direction" = "push" ]; then
    push_one "$CLAUDE/scheduled_tasks.json" "$REPO/scheduled_tasks.json"
    push_one "$CLAUDE/scheduled-tasks" "$REPO/scheduled-tasks"
  else
    pull_one "$REPO/scheduled_tasks.json" "$CLAUDE/scheduled_tasks.json"
    pull_one "$REPO/scheduled-tasks" "$CLAUDE/scheduled-tasks"
  fi
}

# === main ===
case "${1:-}" in
  push)
    say "Pushing from ~/.claude/ to repo..."
    sync_root_files push
    sync_project_memory push
    sync_skills push
    sync_scheduled_tasks push
    say "Done. Review with: cd ~/claude-config && git status"
    ;;
  pull)
    say "Pulling from repo to ~/.claude/..."
    sync_root_files pull
    sync_project_memory pull
    sync_skills pull
    sync_scheduled_tasks pull
    say "Done."
    ;;
  *)
    echo "Usage: ./sync.sh push|pull"
    echo "  push  - copy from ~/.claude/ to repo (save changes)"
    echo "  pull  - copy from repo to ~/.claude/ (deploy to this machine)"
    exit 1
    ;;
esac
