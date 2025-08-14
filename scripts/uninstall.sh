#!/usr/bin/env bash

# 卸载脚本 - 删除 clean_trash 的 systemd 服务和执行文件

set -e  # 遇到错误时退出

# 当前语言 | Current language
CURRENT_LANG=0 # 0: en-US, 1: zh-Hans-CN

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

# 语言检测 | Language detection
if [ $(echo ${LANG/_/-} | grep -Ei "\\b(zh|cn)\\b") ]; then CURRENT_LANG=1; fi

# 检查是否以 root 权限运行
if [[ $EUID -eq 0 ]]; then
   recho "请不要以 root 权限运行此脚本" "Please do not run this script with root privileges"
   exit 1
fi

SERVICE_NAME="clean-trash"
EXEC_NAME="clean_trash"

# 定义路径
BIN_PATH="/usr/local/bin"
SERVICE_PATH="/etc/systemd/system"

recho "正在卸载 $EXEC_NAME..." "Uninstalling $EXEC_NAME..."

# 1. 停止并禁用 systemd 定时器（如果存在）
recho "1. 停止并禁用 systemd 定时器" "1. Stopping and disabling systemd timer"
if systemctl is-active --quiet "$SERVICE_NAME.timer"; then
    sudo systemctl stop "$SERVICE_NAME.timer"
fi

if systemctl is-enabled --quiet "$SERVICE_NAME.timer"; then
    sudo systemctl disable "$SERVICE_NAME.timer"
fi

# 2. 停止并禁用 systemd 服务（如果存在）
recho "2. 停止并禁用 systemd 服务" "2. Stopping and disabling systemd service"
if systemctl is-active --quiet "$SERVICE_NAME.service"; then
    sudo systemctl stop "$SERVICE_NAME.service"
fi

if systemctl is-enabled --quiet "$SERVICE_NAME.service"; then
    sudo systemctl disable "$SERVICE_NAME.service"
fi

# 3. 重新加载 systemd 配置
recho "3. 重新加载 systemd 配置" "3. Reloading systemd configuration"
sudo systemctl daemon-reload 2>/dev/null || true

# 4. 删除 systemd 文件
recho "4. 删除 systemd 文件" "4. Removing systemd files"
sudo rm -f "$SERVICE_PATH/$SERVICE_NAME.service"
sudo rm -f "$SERVICE_PATH/$SERVICE_NAME.timer"

# 5. 删除执行文件
recho "5. 删除执行文件" "5. Removing executable file"
sudo rm -f "$BIN_PATH/$EXEC_NAME"

recho "卸载完成！" "Uninstallation completed!"
echo ""
recho "所有相关文件和 systemd 服务均已删除。" "All related files and systemd services have been removed."