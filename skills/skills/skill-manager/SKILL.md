---
name: skill-manager
description: 单仓库技能管理（Gitee + Claude Code 本地目录）- 管理技能的安装、推送、列表和验证
---

# 单仓库技能管理器

管理基于 Gitee 的单仓库技能系统。**任何操作前先读取 `index.json`** 了解当前仓库状态。

## 仓库目录结构

```
/
├── index.json              # 技能索引（名称、分类、摘要、版本、依赖、路径）← 操作前先读这里
├── 索引.md                  # 由 index.json 自动生成，便于浏览
├── _tmp/                    # 临时文件目录（按 CLAUDE.md 规则）
├── <分类A>/                  # 先按分类分组，分类下才是技能目录
│   ├── <skill-1>/
│   │   └── ...
│   └── <skill-2>/
│       └── ...
└── <分类B>/
    └── <skill-3>/
        └── ...
```

## 远程仓库

| 项目 | 值 |
|------|-----|
| 远程名称 | `gitee-origin` |
| 远程地址 | `https://gitee.com/YSZ333/cw_-skills.git` |
| 主分支 | `main` |
| 推送分支 | `sync/<user>/<timestamp>` |

---

## 命令参考

> **通用原则**：每个命令执行前，先读取本地 `index.json`（若有）了解当前仓库状态。

当用户输入以下命令时，执行对应流程。

### list [分类]

列出可用技能列表。

**步骤：**
1. 检查本地 `index.json` 是否存在，若不存在则提示先运行 `validate` 初始化
2. 读取 `index.json`，解析为 JSON 数组
3. 如果传入了 `[分类]` 参数，按分类过滤
4. 按分类分组展示：

   ```
   === 分类A ===
   skill-1    v1.0.0  简短描述
   skill-2    v1.2.0  简短描述

   === 分类B ===
   skill-3    v0.5.0  简短描述
   ```

5. 若筛选后无结果，提示"该分类下暂无技能"

### install <name>

从 Gitee 远程拉取指定技能及所有依赖。

**步骤：**
1. 检查 `gitee-origin` 远程是否存在，若否则提示用户先配置
2. `git fetch gitee-origin main` 拉取最新远程数据
3. 从远程 `main` 分支读取 `index.json`：`git show gitee-origin/main:index.json`
4. 在远程 index.json 中查找目标技能 `<name>`，若不存在则报错退出
5. 解析该技能的 `dependencies` 数组，递归收集所有依赖技能（拓扑排序，依赖优先）
6. 对每个技能（包括目标技能本身和所有依赖）：
   - 检查本地是否已存在（按 `path` 字段判断目录是否存在）
   - 若已存在，通过 AskUserQuestion 询问是否覆盖
   - `git checkout gitee-origin/main -- <path>` 拉取技能文件夹
7. 更新本地 `index.json`：
   - 读取本地 index.json
   - 对每个拉取的技能：新增条目或更新已有条目
   - 写回 `_tmp/index.json.tmp`，确认无误后覆盖
8. 刷新 `索引.md`（调用"生成 索引.md"流程）
9. 报告完成：拉取了哪些技能、版本号

### push

完整推送本地变更至 Gitee 远程。

**步骤：**

#### Phase 1: 创建分支
1. 获取当前时间戳：`date +%Y%m%d%H%M%S`
2. 获取 Gitee 用户名：`git config user.name` 或提示用户输入
3. 创建并切换分支：`git checkout -b sync/<user>/<timestamp>`
4. `git add .` 暂存所有变更

#### Phase 2: 冲突检查
5. 获取远程 main 最新状态：`git fetch gitee-origin main`
6. 检测三类冲突，分别收集：

   **a. 文件冲突** — `git merge-tree` 或 `git diff` 检查双方修改了同名文件
   - 收集有冲突的文件列表

   **b. 版本/依赖冲突** — 对比本地和远程 index.json 中相同技能的信息
   - 本地版本 < 远程版本 → 版本回退警告
   - 本地新增依赖在远程不存在 → 依赖缺失警告

   **c. 目录结构不符规范** — 扫描本地新增/修改的目录
   - 文件夹名非 kebab-case
   - 分类目录下有非技能文件夹（非 kebab-case 命名也无 index.json 注册）

#### Phase 3: 用户逐项决策
7. 按顺序向用户展示冲突，对每项使用 AskUserQuestion：
   - 文件冲突：显示文件名和双方变更概要，让用户选择"保留本地"/"保留远程"/"跳过(暂不处理)"
   - 版本冲突：提示版本号和详情，让用户选择"覆盖远程版本"/"保留远程版本"/"跳过"
   - 目录结构问题：提示问题详情，让用户选择"修复(自动)"/"忽略"/"跳过"

#### Phase 4: 执行与推送
8. 合并远程代码：
   - `git merge gitee-origin/main`（或根据冲突选择，先处理选"保留远程"的文件）
   - 若合并失败提示用户手动解决

9. 依次执行：
   a. **更新 index.json**：重新扫描本地目录，遍历各分类文件夹，生成完整的 index.json
      - 保留已有条目的 version、summary（新技能需提示用户填写）
      - 移除本地已删除的技能条目
   c. **刷新 索引.md**：调用"生成 索引.md"流程
   d. `git commit -m "sync: 批量技能更新"`（若有变更）
   e. `git push gitee-origin sync/<user>/<timestamp>`

10. 提示用户在 Gitee 上创建 PR 合入 main 分支，并告知：
    - 远程 CI 会自动校验索引合规
    - PR 合入后才算正式发布

### validate

检查本地目录是否符合技能仓库规范。

**步骤：**

#### Phase 0: Git 环境检查（首次使用检查）

在执行仓库规范检查前，先检测 Git 环境是否就绪。这是 `install`、`push` 等命令的前置条件。

1. 检查当前目录是否为 Git 仓库：
   - 执行 `git rev-parse --is-inside-work-tree 2>nul`
   - 若非仓库 → 使用 AskUserQuestion 询问用户"当前目录不是 Git 仓库，是否自动初始化？"
     - 选择"是"：执行 `git init`，然后继续后续检查
     - 选择"否"：记为 **[警告]**，告知后续 `install`、`push` 等命令不可用

2. 检查是否有 `gitee-origin` 远程：
   - 执行 `git remote get-url gitee-origin 2>nul`
   - 若不存在 → 记为 **[错误]**，提示用户按"远程仓库配置"章节设置

3. 检查是否有首次提交：
   - 执行 `git rev-parse HEAD 2>nul`
   - 若无任何提交 → 记为 **[警告]**，提示先创建初始提交（`git add . && git commit -m "init"`）

4. 检查当前分支名：
   - 执行 `git rev-parse --abbrev-ref HEAD`
   - 若非 `main` → 记为 **[警告]**，提示当前分支非 main，`push` 时会基于此分支创建 sync 分支

5. 检查 `user.name` 和 `user.email`：
   - 执行 `git config user.name` 和 `git config user.email`
   - 任一缺失 → 记为 **[警告]**，提示配置用户信息（`push` 时需用 `user.name` 生成 sync 分支名）

6. 汇总输出格式示例：

   ```
   === Git 环境检查 ===
   [错误] 未设置 gitee-origin 远程，请先: git remote add gitee-origin <仓库地址>
   [警告] 尚无首次提交，请先创建初始 commit
   [警告] 当前分支为 dev，非 main（push 时以当前分支为基础）
   ```

   > 只有错误数为 0 时，`install` 和 `push` 命令才能正常工作。用户可根据提示逐项修复。

#### Phase 1: 目录结构检查

1. 检查根目录：
   - `index.json` 是否存在 → 若不存在提示"尚未初始化，是否创建空 index.json？"（使用 AskUserQuestion）
   - `索引.md` 是否存在

2. 遍历各分类目录：
   - 排除 `_tmp/`、`.git/`、`.claude/` 等系统目录
   - 分类目录名应为有意义的中文或英文名

3. 对每个分类下的技能目录：
   - 目录名是否符合 kebab-case（小写字母、数字、连字符）

#### Phase 2: index.json 验证

4. 验证 `index.json`：
   - 是否为有效 JSON 数组
   - 逐条检查必填字段：`name`、`category`、`summary`、`version`、`path`
   - `version` 是否为有效 semver 格式（`/^\d+\.\d+\.\d+/`）
   - `path` 是否指向实际存在的目录
   - `dependencies` 若存在，每个依赖名是否在 index.json 中可找到
   - `name` 是否有重复

#### Phase 3: 索引.md 验证

5. 验证 `索引.md`：
   - 内容是否与 `index.json` 一致（技能数量、名称、版本）
   - 若不一致，提示是否重新生成

#### Phase 4: 汇总输出

6. 汇总所有 Phase 的结果：

   ```
   === Git 环境检查 ===
   [错误] 0
   [警告] 0

   === 仓库规范检查 ===
   [通过] 12 技能
   [警告] 3 （版本不一致、索引未更新等）
   [错误] 1 （文件夹命名不规范：分类A/skill-x）
   ```

---

## 内部工具流程

### 生成 索引.md

读取 `index.json`，按分类分组生成 markdown：

```markdown
# 技能索引

> 由 index.json 自动生成。最后更新：2026-05-12

## 分类A

- [skill-1](分类A/skill-1/) `v1.0.0` — 描述文本
- [skill-2](分类A/skill-2/) `v1.2.0` — 描述文本

## 分类B

- [skill-3](分类B/skill-3/) `v0.5.0` — 描述文本
```

步骤：
1. 读取 `index.json`
2. 按 `category` 字段分组
3. 每个技能一行，格式：`- [name](path/) \`v version\` — summary`
4. 排序：分类名按字母序，分类内技能按 name 字母序
5. 写入 `索引.md`（覆盖写，UTF-8 编码）

### 生成 index.json（重新扫描）

从本地目录重新构建完整的 index.json：

1. 读取现有 `index.json` 作为基线（保留已有的 version、summary）
2. 列出所有分类目录（排除 `_tmp/`、`.git/`、`.claude/`）
3. 对每个分类，列出其下所有子目录（每个子目录应为一个技能）
4. 检查每个技能目录命名是否符合 kebab-case
5. 与基线对比：
   - 已有条目：保留 version、summary、dependencies
   - 新条目：version 默认 `0.1.0`，summary 提示用户填写，dependencies 默认为空数组
   - 已删除条目：从 index.json 移除
6. 输出为格式化的 JSON 数组，写入 `_tmp/index.json.tmp` 确认后覆盖

### 安全规范（本地工具检查）

1. 目录结构合规：分类名有意义、技能目录名符合 kebab-case
2. 索引合规：index.json 中每个条目的 name、version 与对应目录匹配
3. 语义化版本号：遵循 semver 规范
