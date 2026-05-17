---
name: vision
description: 图片识别与描述——让不具备原生视觉能力的模型通过外部 API 获得识图能力。当用户分享图片路径、要求分析/描述/识别图片内容、或消息中出现 "Saved attachments:" 列出图片时，务必使用此技能。即使图片无法直接渲染（显示为 [Unsupported Image]），也应调用 vision.js 获取图片的文字描述。
---

# Vision — 识图技能

你的底层模型不具备原生识图能力。遇到任何图片时，使用 `vision.js` 脚本获取文字描述。

## 首次配置

用户首次要求安装/配置识图时，**必须先确认以下信息再动手**：

### 1. 确认服务商和计划类型

询问用户用哪个服务。如果用户提到 **MiMo / 小米 / xiaomimimo**，**必须追问**是哪种计划：

| 计划类型 | 特征 | API 地址 | Key 格式 |
|---------|------|----------|----------|
| **按量付费（标准）** | 余额充值，Key 以 `sk-` 开头 | `https://api.xiaomimimo.com/v1` | `sk-xxx` |
| **Token Plan（订阅）** | 固定套餐，Key 以 `tp-` 开头 | `https://token-plan-cn.xiaomimimo.com/v1` | `tp-xxx` |

> **不可混淆**：Token Plan 的地址和 Key 不能用于按量付费，反之亦然。搞错会 401 或路由到错误模型。

### 2. 确认模型名

MiMo 视觉模型命名区分大小写：
- `mimo-v2.5`（标准版，支持视觉）
- `mimo-v2.5-pro`（加强版）

用户提供的模型名必须与 API 实际支持的名称一致。不确定时先用 `mimo-v2.5`。

### 3. 验证连通性

配置完成后，**先用纯文本请求验证**，再测试图片：

```bash
# 先测试文本——input_tokens 应该在数十级别
curl -s -X POST "<BASE_URL>/chat/completions" \
  -H "Authorization: Bearer <KEY>" \
  -H "Content-Type: application/json" \
  -d '{"model":"mimo-v2.5","max_tokens":50,"messages":[{"role":"user","content":"say hi"}]}'
```

- 返回 401 → Key 无效或 Base URL 与计划类型不匹配
- 返回 400 + "Codex Provider" → 计划类型用错（Token Plan vs 标准）
- 返回 200 且 model 字段不是请求的模型 → 代理在偷偷换模型，地址有问题
- 返回 200 且 model 匹配 → 通过，继续测试图片

### 4. 配置写入位置

用户级 skill 安装到 `~/.claude/skills/vision/`，项目级安装到项目根目录。

---

## 工作流程

**每次处理图片时，按以下步骤操作：**

### 1. 归档图片到工作目录

先将图片保存到当前工作目录下的 `image/` 子目录中：

```bash
mkdir -p ./image && cp "<图片路径>" "./image/$(date +%Y%m%d_%H%M%S)_$(basename '<图片路径>' | sed 's/.*\/tmp\/[^/]*_//')" 2>/dev/null || cp "<图片路径>" "./image/$(date +%Y%m%d_%H%M%S).png"
```

> 文件名带时间戳前缀，避免覆盖。URL 图片跳过归档。

### 2. 调用 vision.js 识图

```bash
node "%CLAUDE_SKILL_ROOT%/scripts/vision.js" "<图片路径>" "用中文描述这张图片"
```

网络 URL：

```bash
node "%CLAUDE_SKILL_ROOT%/scripts/vision.js" --url "<图片URL>" "用中文描述这张图片"
```

---

## 触发场景

- 用户分享图片路径（本地绝对路径或相对路径）
- 消息中出现 "Saved attachments:" 并列出图片文件
- 用户要求分析、描述、识别图片内容
- 图片显示为 `[Unsupported Image]` —— 先找 /tmp 下最新图片，再归档+识图

## 查找未显示为路径的图片

```bash
ls -t /tmp/*.png /tmp/*.jpg /tmp/*.jpeg /tmp/*.webp /tmp/*.gif 2>/dev/null | head -5
```

取最新文件作为图片路径，然后按上述工作流程处理。

---

## 故障排查

| 现象 | 可能原因 | 解决 |
|------|---------|------|
| 401 Invalid API Key | Key 与计划类型不匹配，或 Key 无效 | 确认 Key 前缀（`sk-` vs `tp-`）对应正确地址 |
| 400 Codex Provider 错误 | Token Plan 地址配了标准 Key（或反之） | 对齐 Base URL 和 Key 类型 |
| 200 但模型不是你请求的 | 代理降级/兜底到其他模型 | 检查 Base URL 是否正确 |
| 200 但说"看不到图片" | input_tokens 太低（~十几）说明图片未送达 | 用 `input_tokens` 数值验证：带图片应 > 100 |
| 系统代理干扰 | `HTTPS_PROXY` 或 Windows 系统代理拦截 | 设置 `HTTPS_PROXY=` 清除代理后再试 |

## 当前配置

API 配置位于 `scripts/vision.js`（默认值）和 `scripts/.env`（环境变量）。当前使用 MiMo 标准按量付费 API（`api.xiaomimimo.com`，`mimo-v2.5`）。
