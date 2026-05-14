---
name: screenshot via doubao
description: 当前模型无法直接看截图时，通过豆包网页版上传截图获取视觉描述
type: feedback
originSessionId: 7017fce4-ec7e-4761-9530-bcf37a96b3be
---
当前接入的模型不具备多模态能力，无法直接查看截图。涉及需要"看"截图的场景时：
1. 用 browser-harness 截图
2. 打开豆包网页版，上传截图
3. 让豆包描述截图内容
4. 读取豆包返回的文字描述，基于描述继续操作

**Why:** 弥补模型无视觉能力的限制，豆包作为免费的视觉代理。

**How to apply:** 每次 browser-harness 截图后需要"看"时，走这个流程获取文字描述。
