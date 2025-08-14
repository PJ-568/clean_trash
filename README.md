# 垃圾清理脚本

[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)

> 简体中文 | [English](README.en.md)

实现清理在回收站里保存超过指定天数的文件。

```bash
回收站清理工具
用法：./clean_trash.sh [-h] [-v] <保留天数>
选项：
  -h  显示帮助信息
  -v  详细输出模式
示例：
  ./clean_trash.sh 30    # 清理 30 天前的回收站文件
  ./clean_trash.sh -v 7  # 详细模式清理 7 天前文件
```

## 贡献

[贡献指北](CONTRIBUTING.md)

## Linux 回收站机制概述

Linux 桌面环境“删除”一个文件时会将它移动到一个特殊的“回收站”目录中，这个目录通常是 `~/.local/share/Trash/`。
回收站目录内部通常有三个子目录：

- `files/`: 存放被删除的**文件**本身。如：`提问.png`。
- `info/`: 存放与被删除文件相关的**元数据**（如原始路径、删除时间戳等）。如：

  ```plaintext ~/.local/share/Trash/info/提问.png.trashinfo
  [Trash Info]
  Path=/home/user/%E6%8F%90%E9%97%AE.png
  DeletionDate=2025-08-13T19:47:35
  ```

- `expunged/`: 临时存放要**被永久删除**的文件。

### `expunged` 文件夹的作用

- **“永久删除”操作：** 当你决定清空回收站（在文件管理器中选择“清空回收站”菜单项）时，桌面环境并不会简单地删除 `files/` 和 `info/` 目录里的所有内容。
- **标记过程：** 它首先会将 `files/` 目录中对应的文件**移动**到 `~/.local/share/Trash/expunged/` 目录中（因为移动文件很快）。
- **物理删除：** 然后，它会**物理删除** `info/` 目录中对应的元数据文件；慢慢**物理删除** `expunged/` 目录中对应的文件（删除大量文件需要时间，过快地进行可能会减慢整个计算机的速度）。
