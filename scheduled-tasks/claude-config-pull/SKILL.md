---
name: claude-config-pull
description: 每天上午同步远端配置到本机
---

执行以下命令同步 Claude Code 配置：

```bash
cd ~/claude-config && git pull --rebase && ./sync.sh pull
```

如果 git pull 有冲突，跳过并提醒用户手动处理。