---
name: 99A-config-read
description: 解析CW1310-99A储能主机固件配置，提取探测器、报警、联动、启动、喷洒逻辑等关键参数为需求解析文档
---

# 99A-config-read

解析 99A 系列储能火灾抑制主机固件，输出格式统一的需求解析文档。

## 用法

在固件项目根目录执行此 skill，Claude 会自动分析源代码并生成 `ESS0269_版本号_程序解析文档.md`。

## 分析步骤

### 1. 条件编译状态核查

搜索 Applications/*.c 和 *.h 中关键宏的 `#define` 定义情况：

| 宏 | 说明 |
|----|------|
| `PZONE` | 启用第二保护区(PACK区) |
| `GASSW192` | GasSw192 作为CAN开关关联灭火器 |
| `GASSWALONE` | GasSw192 作为独立DI开关 |
| `ONLINE_TEST` | 在线测试模式(离线检测6s而非60s) |
| `PERFLUOR_LOG` | 全氟己酮日志输出 |

然后确认：
- `GasExtgFuc.c` 中 `stpFucExtgCtrl` 指向 `stFucPerfluor` 还是 `stFucHFC`
- `app_conf.h` 中 `_DC_FIRE_` 和 `_CC_FIRE_` 的值

### 2. 提取探测器

**复合探测器** → `FdCtrl.c`
- `_FdCtrl_Init()`: 循环中 `stFd[i].emFdIsAble = FD_EN` 的次数 = 数量
- 地址从 for 循环 `id = 1` 开始，递增
- CAN协议 ID: 查看 `_FdCtrl_GetFdMess` 中的 case 分支

**干式探测器** → `MaCtrl.c`
- `_MaCtrl_Init()`: 每个 `stMa[i].emMaIsAble = MA_EN` 块
- 记录 emMaType(MA_SMOKE/MA_TEMP/MA_12A) 和 RevData 对应的通道(DI0/DI1/GasSw191/GasSw192)

**气体开关** → `GasSWCtrl.c`
- `_GasSwCtrl_Init()`: 每个 `emGasSwIsAble = GASSW_EN` 块
- 记录 emGasSwType(DEV_GASSW/DEV_FIRESW/DEV_MBUSSW) 和起始ID

### 3. 提取报警装置

**DI输入配置** → `dictrl.c`
- `DiCtrlInit()`: 查看 `ucDiType` 配置值（DI_FIRE_ALARM_ACTIVE / DI_FIRE_ALARM_STOP）

**联动输出** → `LinkCtrl.c`
- `_LikCtrl_Init()`: 每个 `stLik[i]` 的 `ucTerm[]` 条件数组
- 对照 stLikConf 表中索引对应的条件函数

**DO输出通道** → `output.h` + `doctrl.h`
- OUTPUT_INDEX 枚举 = 物理输出通道

### 4. 提取联动映射

**干接点** → `LinkCtrl.c` `_LikCtrl_Init()` 的 stLik[4]~stLik[9]
- 每个 DRY1~6 的 ucTerm[] 条件
- 条件函数含义：参考 _LikCtrl_LowAlarm / _LikCtrl_HighAlarm / _LikCtrl_Fault

**DO条件** → `doctrl.c` `DoCtrlInit()`
- 每个 DO 通道的 `eDoCtrlConds[]` 条件

### 5. 提取启动(灭火条件)

**PzCtrl.c** `_PzCtrl_PadPzAlarm()`:
- 列出所有到达 `ALARM_LEVEL2` 的 if 分支条件

### 6. 提取喷洒逻辑

**GasExtg.c** `_Extg_Init()`:
- `usDelayTime[]` = 各次延时(秒)
- `usActiveTime[]` = 各次喷射时长(秒)
- `usSparyTime` = 喷洒保持时间
- `ucSparyNum` = 喷射次数
- `ucGasSwNum` + `ucGasSwList[]` = 关联的GasSw

**PerfluorCtrl.c** `_Perfluor_StateMachine()`:
- 状态机转移：UnStart → Delay → Active → Spray → Done
- 电磁阀CAN协议：`0x18CA00F6 + (ucValveId << 8)`

**zonehandle.c** `ZoneHandleMainProcess()`:
- 检查是否有第二套 EXTH_2 喷洒逻辑（条件编译）

## 输出格式

```markdown
## 需求解析

### 条件编译实际状态
...

**探测器：**
...

**报警装置：**
...

**联动：**
...

**启动：**
...

**喷洒逻辑：**
...
```
