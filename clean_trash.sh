#!/usr/bin/env bash

# 设置定量 | Quantities
## 初始化变量 | Initialize variables
VERBOSE=0
## 当前语言 | Current language
CURRENT_LANG=0 # 0: en-US, 1: zh-Hans-CN
## 定义回收站目录 | Define trash directory
TRASH_DIR="${TRASH_DIR:-$HOME/.local/share/Trash}"
FILES_DIR="${FILES_DIR:-$TRASH_DIR/files}"
INFO_DIR="${INFO_DIR:-$TRASH_DIR/info}"
EXPUNGED_DIR="${EXPUNGED_DIR:-$TRASH_DIR/expunged}"

# 本地化 | Localization
recho() {
  if [ $CURRENT_LANG == 1 ]; then
    ## zh-Hans-CN
    echo "$1";
  else
    ## en-US
    echo "$2";
  fi
}

# 显示帮助信息 | Show help message
show_help() {
  recho "回收站清理工具" "Trash cleaner tool"
  recho "用法：$0 [-h] [-v] <保留天数>" "Usage: $0 [-h] [-v] <days>"
  recho "选项：" "Options:"
  recho "  -h  显示帮助信息" "  -h  Show help"
  recho "  -v  详细输出模式" "  -v  Verbose mode"
  recho "示例：" "Examples:"
  recho "  $0 30    # 清理 30 天前的回收站文件" "  $0 30    # Clean trash files older than 30 days"
  recho "  $0 -v 7  # 详细模式清理 7 天前文件" "  $0 -v 7  # Verbose mode to clean files older than 7 days"
}

# 语言检测 | Language detection
if [ $(echo ${LANG/_/-} | grep -Ei "\\b(zh|cn)\\b") ]; then CURRENT_LANG=1; fi

# 解析选项 | Parse options
while getopts ":hv" opt; do
  case $opt in
    h) show_help ; exit 0 ;;
    v) VERBOSE=1 ;;
    \?) recho "错误：无效选项 -$OPTARG" "Error: Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done
shift $((OPTIND-1))

# 检查是否提供了天数参数 | Check if days parameter was provided
if [ $# -ne 1 ]; then
  recho "错误：需要提供保留天数参数" "Error: Need to provide days parameter" >&2
  show_help
  exit 1
fi

# 获取天数参数 | Get days parameter
DAYS=$1

# 检查天数是否为正整数 | Check if days is a positive integer
if ! [[ "$DAYS" =~ ^[0-9]+$ ]] || [ "$DAYS" -le 0 ]; then
  recho "错误：天数必须是正整数" "Error: Days must be a positive integer" >&2
  exit 1
fi

# 检查回收站目录结构 | Check trash directory structure
if [ ! -d "$FILES_DIR" ] || [ ! -d "$INFO_DIR" ]; then
  recho "错误：回收站目录结构不正确" "Error: Trash directory structure is incorrect" >&2
  recho "请确认目录存在：$FILES_DIR 和 $INFO_DIR" "Please confirm directories exist: $FILES_DIR and $INFO_DIR" >&2
  exit 1
fi

# 获取当前时间戳 | Get current timestamp
CURRENT_TIME=$(date +%s)

# 计算截止时间戳 | Calculate cutoff timestamp
CUTOFF_TIME=$((CURRENT_TIME - DAYS * 24 * 60 * 60))

# 初始化计数器 | Initialize counters
DELETED_COUNT=0
ERROR_COUNT=0

# 确保 expunged 目录存在 | Ensure expunged directory exists
mkdir -p "$EXPUNGED_DIR"

# 遍历 info 目录中的所有 .trashinfo 文件 | Iterate through all .trashinfo files in info directory
for INFO_FILE in "$INFO_DIR"/*.trashinfo; do
  # 检查文件是否存在 | Check if file exists
  if [ ! -f "$INFO_FILE" ]; then
    continue
  fi
  
  # 获取对应的文件名 | Get corresponding filename
  BASENAME=$(basename "$INFO_FILE" .trashinfo)
  TRASH_FILE="$FILES_DIR/$BASENAME"
  
  # 检查对应的文件是否存在 | Check if corresponding file exists
  if [ ! -e "$TRASH_FILE" ]; then
    if [ $VERBOSE -eq 1 ]; then
      recho "警告：找不到对应文件 $TRASH_FILE" "Warning: Cannot find corresponding file $TRASH_FILE" >&2
    fi
    continue
  fi
  
  # 从 .trashinfo 文件中提取 DeletionDate | Extract DeletionDate from .trashinfo file
  DELETION_DATE=$(grep -E "^DeletionDate=" "$INFO_FILE" | cut -d'=' -f2)
  
  # 检查是否成功提取日期 | Check if date was extracted successfully
  if [ -z "$DELETION_DATE" ]; then
    if [ $VERBOSE -eq 1 ]; then
      recho "警告：无法从 $INFO_FILE 提取删除日期" "Warning: Cannot extract deletion date from $INFO_FILE" >&2
    fi
    continue
  fi
  
  # 将删除日期转换为时间戳 | Convert deletion date to timestamp
  # 注意：日期格式为 2025-08-13T19:47:35
  DELETION_TIMESTAMP=$(date -d "$DELETION_DATE" +%s 2>/dev/null)
  
  # 检查日期转换是否成功 | Check if date conversion was successful
  if [ $? -ne 0 ] || [ -z "$DELETION_TIMESTAMP" ]; then
    if [ $VERBOSE -eq 1 ]; then
      recho "警告：无法解析删除日期 $DELETION_DATE" "Warning: Cannot parse deletion date $DELETION_DATE" >&2
    fi
    continue
  fi
  
  # 检查文件是否超过保留天数 | Check if file exceeds retention days
  if [ "$DELETION_TIMESTAMP" -lt "$CUTOFF_TIME" ]; then
    # 创建唯一的 expunged 文件名 | Create unique expunged filename
    EXPUNGED_FILE="$EXPUNGED_DIR/$BASENAME"
    
    # 如果文件已存在，则添加时间戳以确保唯一性 | If file exists, add timestamp to ensure uniqueness
    if [ -e "$EXPUNGED_FILE" ]; then
      EXPUNGED_FILE="$EXPUNGED_DIR/${BASENAME}_$(date +%s)"
    fi
    
    # 将文件移动到 expunged 目录 | Move file to expunged directory
    if [ $VERBOSE -eq 1 ]; then
      recho "移动文件到 expunged: $TRASH_FILE (删除于 $DELETION_DATE)" "Moving file to expunged: $TRASH_FILE (deleted at $DELETION_DATE)"
    fi
    
    if mv "$TRASH_FILE" "$EXPUNGED_FILE"; then
      # 删除元数据文件 | Delete metadata file
      rm -f "$INFO_FILE"
      DELETED_COUNT=$((DELETED_COUNT + 1))
    else
      ERROR_COUNT=$((ERROR_COUNT + 1))
      recho "错误：无法移动文件到 expunged 目录" "Error: Cannot move file to expunged directory" >&2
    fi
  fi
done

# 物理删除 expunged 目录中的所有文件 | Physically delete all files in expunged directory
if [ -d "$EXPUNGED_DIR" ]; then
  if [ $VERBOSE -eq 1 ]; then
    EXPUNGED_COUNT=$(find "$EXPUNGED_DIR" -mindepth 1 2>/dev/null | wc -l)
    if [ "$EXPUNGED_COUNT" -gt 0 ]; then
      recho "物理删除 expunged 目录中的 $EXPUNGED_COUNT 个文件" "Physically deleting $EXPUNGED_COUNT files in expunged directory"
    fi
  fi
  # 物理删除 expunged 目录中的所有内容 | Physically delete all contents in expunged directory
  rm -rf "$EXPUNGED_DIR"/* 2>/dev/null
fi

# 输出结果 | Output results
recho "清理完成：删除了 $DELETED_COUNT 个文件，$ERROR_COUNT 个错误" "Cleanup completed: $DELETED_COUNT files deleted, $ERROR_COUNT errors"
