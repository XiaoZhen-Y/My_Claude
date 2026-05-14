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

## AI 驱动的同步流程

调用 `/MyClaude` 时，**由 AI 直接执行 git 命令并判断结果**，不要委托给脚本。两个方向：

### 推送（用户说 push / 推送 / 上传）

```
cd ~/claude-config
git pull --rebase
```

**检查 rebase 结果**：
- 如果 `git pull --rebase` 失败 → `git rebase --abort` 中止，把冲突文件内容展示给用户，询问用户选择：
  1. 保留本机版本
  2. 保留远端版本
  3. 手动编辑
- 然后重新 `git pull --rebase`，继续

```
./sync.sh push
git add -A
git diff --cached --stat
```

- 如果 `git diff --cached` 有变更 → `git commit -m "手动同步 $(date +%Y-%m-%d)" && git push`
- 如果没有变更 → 直接告诉用户"配置无变化，跳过推送"
- 推送失败 → 告诉用户具体错误信息，不要吞掉

### 拉取（用户说 pull / 拉取 / 下载）

```
cd ~/claude-config
git fetch origin
git log HEAD..origin/master --oneline
```

- 如果没有新提交 → 告诉用户"远端无新变更"
- 如果有新提交 → 展示新增的 commit，然后：

```
git pull --rebase
```

- 如果冲突 → `git rebase --abort`，展示冲突内容，询问用户如何解决
- 如果成功 → `./sync.sh pull`，列出哪些文件被更新了

## 注意事项

- **永远不要**在 git 命令后面加 `|| true` 或 `2>/dev/null`
- **永远不要**吞掉 git 的输出，必须检查并报告
- 冲突时**必须**询问用户，不要自动选择版本
- 使用 Bash 工具直接执行命令，不要写临时脚本
