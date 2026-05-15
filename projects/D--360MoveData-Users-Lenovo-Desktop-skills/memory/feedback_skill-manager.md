---
name: skill-manager design rules
description: 技能管理器的设计原则：远程仓库地址固化、先读索引、分类目录结构
type: feedback
originSessionId: 5cea68dd-5bbe-4342-bd15-a403e81acf31
---
skill-manager SKILL.md 中必须体现以下三条规则：

1. **远程仓库地址固化**：`https://gitee.com/YSZ333/cw_-skills.git` 直接写死在 SKILL.md 中，不要在运行时询问用户仓库地址。
2. **先读索引再操作**：任何命令（list/install/push/validate）执行前，先读取本地 `index.json` 了解当前仓库状态。
3. **目录结构是 分类 → skill**：仓库根目录下先按分类分组，分类目录下才是具体的技能目录。不是扁平结构。

**Why:** 用户在使用过程中发现每次询问远程地址效率低，且流程设计不符合实际使用习惯。
**How to apply:** 修改 SKILL.md 时确保这些规则体现在所有命令流程的开头步骤中。
