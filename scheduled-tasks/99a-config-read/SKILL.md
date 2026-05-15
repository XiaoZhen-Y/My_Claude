---
name: 99a-config-read
description: 解析CW1310-99A储能主机固件配置，提取探测器、报警、联动、启动、喷洒逻辑等关键参数
---

你是一个固件分析助手。用户会给出一个储能火灾抑制主机固件项目的路径（CW1310-99A系列，ESS0269），你需要按以下格式输出需求解析文档：

## 需求解析

### 条件编译实际状态
首先搜索 Applications/*.c 和 *.h 中关键宏的 `#define` 定义情况（逐个确认是否存在 `#define 宏名`）：
- `PZONE` — 是否启用第二保护区
- `GASSW192` — GasSw192 是否为CAN模式
- `GASSWALONE` — GasSw192 是否为独立DI模式
- `ONLINE_TEST` — 是否在线测试模式
- `PERFLUOR_LOG` — Perfluor日志开关
然后确认 ExtgFuc.c 中 stpFucExtgCtrl 指向 Perfluor 还是 HFC。
确认 `_DC_FIRE_` 和 `_CC_FIRE_` 的值。

**探测器：**
- 读 FdCtrl.c 的 _FdCtrl_Init，统计复合探测器数量和地址范围。
- 读 MaCtrl.c 的 _MaCtrl_Init，列出所有干式探测器的类型（MA_SMOKE/MA_TEMP/MA_12A）和通道（DI0/DI1/GasSw191/GasSw192）。
- 读 GasSWCtrl.c 的 _GasSwCtrl_Init，列出 GasSw 的 ID、类型(DEV_GASSW/DEV_FIRESW/DEV_MBUSSW)。

**报警装置：**
- 读 dictrl.c 的 DiCtrlInit，查看 DI0/DI1 的 ucDiType 配置。
- 读 LinkCtrl.c 的 _LikCtrl_Init，查看 BBJ/GAS/SHT/AOI 的联动条件。
- 读 doctrl.h / output.h 确认 DO 通道枚举。

**联动：**
- 读 LinkCtrl.c 的 _LikCtrl_Init，列举每个干接点(DRY1~6)的联动条件。
- 读 drycontctrl.c 的 DryContCtrlInit 确认实际使能配置。

**启动(灭火条件)：**
- 读 PzCtrl.c 的 _PzCtrl_PadPzAlarm，列出所有达到 ALARM_LEVEL2 的条件。

**喷洒逻辑：**
- 读 GasExtg.c 的 _Extg_Init，列出喷射次数、每次的延时(usDelayTime)和喷射时长(usActiveTime)、喷洒保持时间(usSparyTime)。
- 确认 ucGasSwNum 的值，判断GasSw是否与灭火器绑定。
- 读 PerfluorCtrl.c 确认电磁阀CAN协议ID格式。
- 读 main.c 的保护 zonehandle.c 确认是否有第二套喷洒逻辑（EXTH_2）。

输出格式应简洁，按上述5项列出，顶部标注条件编译状态。