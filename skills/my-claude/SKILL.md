---
name: MyClaude
description: 同步 Claude Code 配置到 GitHub 仓库，支持 push（推送）和 pull（拉取）
---

# MyClaude —— Claude Code 配置同步

将 `~/.claude/` 核心配置同步到 GitHub 仓库 [XiaoZhen-Y/My_Claude](https://github.com/XiaoZhen-Y/My_Claude)。

## 同步范围

| 内容 | 说明 |
|------|------|
| `CLAUDE.md` | 全局行为规则 |
| `settings.json` | 权限、hooks、MCP 配置 |
| `launch.json` | 开发服务器配置 |
| `projects/*/memory/` | 项目持久记忆 |
| `skills/` | 全部 skills |
| `scheduled-tasks/` | 定时任务定义 |

## 使用方式

用户通过 `/MyClaude` 调用，按以下流程操作：

### 推送（将本机配置同步到 GitHub）

```
cd ~/claude-config && ./sync.sh push && git add -A
```

如果 `git diff --cached` 有变更则执行：
```
git commit -m "手动同步 $(date +%Y-%m-%d)" && git push
```

否则输出"配置无变化，跳过推送"。

### 拉取（从 GitHub 同步到本机）

```
cd ~/claude-config && git pull --rebase && ./sync.sh pull
```

## 新设备初始化

在新设备上首次使用时：
```
git clone https://github.com/XiaoZhen-Y/My_Claude.git ~/claude-config
cd ~/claude-config && ./sync.sh pull
```
