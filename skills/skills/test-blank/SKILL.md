---
name: test-blank
description: 空白测试技能，用于验证Claude能否正常读取用户级技能并执行脚本操作
version: 1.0.0
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# test-blank

空白测试技能。用于验证 Claude 是否能正确加载用户级技能并执行其定义的脚本操作。

## 测试流程

执行本技能时按以下步骤操作：

### 1. 读取技能自身

确认技能文件结构完整：

```bash
find "%CLAUDE_SKILL_ROOT%" -type f
```

> `%CLAUDE_SKILL_ROOT%` 由 Claude Code 自动注入，指向当前技能所在目录。若该变量不可用，回退到技能基目录。

### 2. 运行测试脚本

执行 Python 测试脚本：

```bash
python "%CLAUDE_SKILL_ROOT%/scripts/test-env.py"
```

> Python 脚本跨平台、原生支持 Unicode，不存在 `.bat` 在 Git Bash 下的中文编码问题。

### 3. 报告结果

将脚本输出整理为以下格式告知用户：

```
## test-blank 测试结果

- 技能加载: [成功/失败]
- 脚本执行: [成功/失败]
- 当前工作目录: ...
- 系统信息: ...
```
