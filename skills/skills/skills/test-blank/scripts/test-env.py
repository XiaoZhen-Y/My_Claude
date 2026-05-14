#!/usr/bin/env python3
"""test-blank 技能测试脚本 — 跨平台，原生 Unicode 支持。"""

import os
import sys
import platform
from pathlib import Path


def main():
    skill_dir = Path(__file__).resolve().parent.parent

    print("=" * 48)
    print("  test-blank 技能测试脚本 (Python)")
    print(f"  运行时间: {_now()}")
    print("=" * 48)
    print()

    # [1/4] 目录结构
    print("[1/4] 技能目录结构:")
    for f in sorted(skill_dir.rglob("*")):
        if f.is_file():
            rel = f.relative_to(skill_dir)
            print(f"  {rel}")
    print()

    # [2/4] 工作目录
    print(f"[2/4] 当前工作目录: {Path.cwd()}")
    print()

    # [3/4] 系统信息
    print("[3/4] 系统信息:")
    print(f"  OS:      {platform.system()} {platform.release()}")
    print(f"  版本:    {platform.version()}")
    print(f"  架构:    {platform.machine()}")
    print(f"  Python:  {sys.version}")
    print()

    # [4/4] CLAUDE 环境变量
    print("[4/4] 环境变量 (CLAUDE 相关):")
    found = False
    for key, val in sorted(os.environ.items()):
        if "claude" in key.lower():
            print(f"  {key}={val}")
            found = True
    if not found:
        print("  (无 CLAUDE 相关环境变量)")
    print()

    print("=" * 48)
    print("  测试完成")
    print("=" * 48)


def _now() -> str:
    import datetime
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


if __name__ == "__main__":
    main()
