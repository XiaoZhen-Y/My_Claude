---
name: BrowserSync
description: 同步 browser-harness 用户定制内容（agent_helpers、domain-skills）到 GitHub
---

# BrowserSync —— browser-harness 用户定制同步

只同步用户在 `~/browser-harness/` 中**自己创建的内容**，官方代码不参与同步（通过 `git clone` 获取即可）。

## 同步范围

| 文件/目录 | 说明 |
|-----------|------|
| `agent-workspace/agent_helpers.py` | 自定义浏览器操作原语 |
| `agent-workspace/domain-skills/` | 自定义站点 skill（未来） |

## 仓库结构

```
~/browser-config/                          ← GitHub 仓库
├── agent-workspace/
│   └── agent_helpers.py                   ← 用户定制
└── sync.sh                                ← 双向同步脚本

~/browser-harness/                         ← 官方 clone（不参与 sync）
├── agent-workspace/
│   └── agent_helpers.py                   ← sync 会覆盖/拉取到这里
└── ...
```

仓库地址：[XiaoZhen-Y/WebControl_Browser-Harness](https://github.com/XiaoZhen-Y/WebControl_Browser-Harness)

## AI 驱动的同步流程

调用 `/BrowserSync` 时，**由 AI 直接执行命令并判断结果**。

### 推送（用户说 push / 推送）

```
cd ~/browser-config
./sync.sh push
git add -A
git diff --cached --stat
```

- 有变更 → `git commit -m "手动同步 $(date +%Y-%m-%d)" && git push`
- 无变更 → "定制内容无变化"

### 拉取（用户说 pull / 拉取）

```
cd ~/browser-config
git pull --rebase
```

- 冲突 → `git rebase --abort`，展示冲突，询问用户
- 成功 → `./sync.sh pull`，报告更新了什么

### 新设备初始化

```bash
# 1. 克隆官方 browser-harness
git clone https://github.com/browser-use/browser-harness.git ~/browser-harness

# 2. 克隆用户定制
git clone https://github.com/XiaoZhen-Y/WebControl_Browser-Harness.git ~/browser-config

# 3. 拉取定制到 browser-harness
cd ~/browser-config && ./sync.sh pull
```

## 注意事项

- **永远不要**在 git 命令后面加 `|| true` 或 `2>/dev/null`
- 冲突时**必须**询问用户
- `agent_helpers.py` 新增函数后记得推送
