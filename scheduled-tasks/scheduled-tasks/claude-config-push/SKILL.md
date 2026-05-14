---
name: claude-config-push
description: 每天傍晚推送本机配置变更到远端
---

执行以下命令将本机配置同步到仓库并推送：

```bash
cd ~/claude-config && ./sync.sh push && git add -A && git diff --cached --quiet && exit 0; git commit -m "auto sync $(date +%Y-%m-%d)" && git push
```

如果工作区干净（无变更），跳过提交直接退出。