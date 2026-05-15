---
name: 99A-code-change
description: >
  Modify source code in CW1310-99A (ESS0298) energy storage fire controller firmware projects.
  Use this skill whenever the user asks to modify .c/.h files in a 99A project, mentions
  MaCtrl/PzCtrl/GasExtg/FdCtrl/LinkCtrl/app_conf files, discusses fire extinguisher startup
  logic, alarm level判定, partition/zone configuration, IO binding, or dry contact linkage
  in the context of a 99A/ESS0298/CW1310 firmware project. Also use when working with
  Keil MDK projects that contain GBK-encoded Chinese comments — the encoding handling
  rules here apply broadly to Chinese embedded development workflows.
---

# 99A Project Code Change

CW1310-99A (ESS0298) 是储能电站消防主机固件，基于 STM32F10x + Keil MDK 开发。
本技能涵盖该项目的代码架构、修改流程和编码安全规则。

## File Encoding — Critical Rule

源文件（.c/.h）使用 **GBK 编码**（中文 Windows + Keil MDK 默认），换行符为 CRLF。

### Edit tool is FORBIDDEN on GBK files

Edit 工具在读写文件时会将 GBK 中文字节错误解释为非法 UTF-8 序列，全部替换为
U+FFFD（`ef bf bd`），造成中文永久损坏且不可逆。**即使用 ASCII-only 的 old_string
也不行**——Edit 工具在读取文件阶段就会破坏中文。

### Safe modification methods

| 场景 | 方法 |
|------|------|
| 单行替换 | `sed -i 's/old/new/' file.c`（Git Bash 中 sed 对字节透明）|
| 多行替换 | 用 `scripts/binary_patch.py`，以 rb/wb 二进制模式做字节级查找替换 |
| 新增注释 | 只用纯 ASCII 字符，不加中文注释 |

### Verification workflow

每次修改后必须验证：
```bash
# 1. 用 git show 对比原始文件确认中文完好
git show HEAD:./Applications/PzCtrl.c | sed -n '22p' | xxd

# 2. 用 git diff 确认变更范围只涉及目标代码行
git diff

# 3. 用 xxd 抽查修改后的文件中文字节
sed -n '22p' Applications/PzCtrl.c | xxd
```

GBK "电池舱A" 的正确字节为 `b5 e7 b3 d8 b2 d5 41`，若出现 `ef bf bd` 则已损坏。

## Code Architecture

### Key files and their roles

| 文件 | 职责 |
|------|------|
| `MaCtrl.c/h` | 报警设备（MA）管理。IO 输入绑定在 `_MaCtrl_Init()` 中，
通过 `RevAlmData`/`RevFauData` 函数指针关联物理 IO。设备类型枚举：
`MA_COMP`（复合探测器）、`MA_EX_COLLECT`（数据集中器）、`MA_IO`（IO 模块）、
`MA_12A`（灭火器）等 |
| `PzCtrl.c/h` | 防护分区（Pz/Zone）逻辑。`_PadPzAlarm()` 判定分区报警等级，
`_LikExtg()` 联动灭火器启动。标志位 `bCompAlarm`（复合探测器报警）、
`bConcentratorAlarm`（数据集中器报警）。分区设备绑定在 `_Init()` 的
`stPzInfo.ucMaId[]`/`ucMaType[]` 中 |
| `GasExtg.c/h` | 灭火器配置与状态机。`stExtgInfo` 包含延时时间 (`usDelayTime`)、
喷放时间 (`usActiveTime`)、喷放次数 (`ucSparyNum`)、电磁阀列表 (`ucGasSwList`) |
| `FdCtrl.c/h` | 探测器数据采集（CAN 总线），报警/故障判定 |
| `LinkCtrl.c/h` | 干接点/联动输出。`stLik[]` 数组中每个元素代表一个输出通道，
通过 `vAffiliation` 关联分区（NULL=全局），通过 `ucTerm[]` 指定触发条件 |
| `app_conf.c/h` | 应用配置、版本号 `tCwAppVersion`、NVM 分区表 `gstDataIndexTable` |
| `SysConfig.h` | 编译开关：`PZONE`（使能 B 舱/PCS 舱）、`GASSW192`、`GASSWALONE` |

### Alarm level chain

```
探测器报警(Fd) → 分区判定(PzCtrl:_PadPzAlarm)
  → emPzAlarmLevel (0-5)
    → 联动灭火器(PzCtrl:_LikExtg) → 灭火器状态机(GasExtg)
    → 干接点输出(LinkCtrl:_PadSte→_DoLik)
```

报警等级枚举在 `app_types.h`：`ALARM_LEVEL0`(0) 到 `ALARM_LEVEL5`(5)。

### Device-to-Zone binding

每个分区的设备通过 `PzCtrl_Init()` 中 `stPzInfo` 配置，匹配规则在
`_PzCtrl_PzMaPadList()` 中：

```c
if ((((uint16_t)stpMa->emMaType << 8) + stpMa->ucMaId) ==
    ((uint16_t)stpPz->stPzInfo.ucMaType[i] << 8) + stpPz->stPzInfo.ucMaId[i])
```

即 `(Type << 8 | Id)` 组合键匹配。设备 Id 是**同类设备内**的序号，
由 `_MaCtrl_Init()` 中 `MaTypeId[type]++` 自动分配。

### Compartment configuration

| 分区 | PzId | 06E 探测器 | 复合探测器 | 灭火器 |
|------|------|-----------|-----------|--------|
| A 舱 | 1 | Fd 1-4 | MA_COMP Id=1 | GasSw 191 (Extg 1) |
| B 舱 | 2 | Fd 5-8 | MA_IO Id=1 (I4) | GasSw 192 (Extg 2) |
| PCS 舱 | 3 | — | — | — |

## Modification Principles

### Before touching any file

1. 通读所有相关文件，理解现有 IO 绑定和设备映射
2. 用 `git show HEAD:./path/file.c | xxd` 确认原始中文编码完好
3. 分析现有逻辑，定位缺失点（如被注释掉的代码块）

### When modifying

4. **IO 绑定不确定时必须向用户确认**——`RevAlmData`/`RevFauData` 代表物理接线，
   猜错会导致功能异常。绝不自行猜测 IO 映射
5. **优先修改上层逻辑**（PzCtrl.c 的分区判定）而非底层 IO 绑定（MaCtrl.c）
6. 不引入不必要的抽象或重构
7. 新增注释只用 ASCII，标注版本号如 `//  6.13.13.21[1+]`

### After modifying

8. 用 `git diff` 确认变更范围
9. 用 `xxd` 抽查中文行未被破坏
10. 清理 `_tmp/` 目录下的临时脚本

## Common Patterns

### Reading a device's IO binding

```bash
# 查看 stMa[5] 绑定了哪个 IO
sed -n '177,180p' Applications/MaCtrl.c
```

### Tracing a partition's device list

```bash
# 查看 A 舱 stPz[0] 的设备配置
sed -n '40,58p' Applications/PzCtrl.c
```

### Checking compile flags

```bash
grep -E 'PZONE|GASSW192' Applications/SysConfig.h
```

### Binary patching multi-line changes

Use `scripts/binary_patch.py` — read the script for usage. It accepts a JSON
config file describing byte-level replacements, or can be used inline from Python.
Always restore from git (`git checkout -- file.c`) before re-patching to start
from a clean state.
