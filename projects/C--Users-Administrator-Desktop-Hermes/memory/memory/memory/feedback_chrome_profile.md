---
name: chrome default profile
description: browser-harness 连接 Chrome 时优先使用用户的默认 profile
type: feedback
originSessionId: 7017fce4-ec7e-4761-9530-bcf37a96b3be
---
使用 browser-harness 时，Chrome 应该以默认 profile 启动（只加 `--remote-debugging-port=9222`），不要传 `--user-data-dir`。这样能保留用户的所有登录态、cookie、插件等。

**Why:** 用户需要已登录的网站状态，空白 profile 没有意义。

**How to apply:** 启动 Chrome 用于 browser-harness 时，命令应为：
```
chrome.exe --remote-debugging-port=9222
```
不带 `--user-data-dir` 参数。
