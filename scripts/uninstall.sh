#!/usr/bin/env bash

# 卸载脚本 - 删除 clean_trash 的 systemd 服务和执行文件

set -e  # 遇到错误时退出

# 检查是否以 root 权限运行
if [[ $EUID -eq 0 ]]; then
   echo "请不要以 root 权限运行此脚本"
   exit 1
fi

SERVICE_NAME="clean-trash"
EXEC_NAME="clean_trash"

# 定义路径
BIN_PATH="/usr/local/bin"
SERVICE_PATH="/etc/systemd/system"

echo "正在卸载 $EXEC_NAME..."

# 1. 停止并禁用 systemd 定时器（如果存在）
echo "1. 停止并禁用 systemd 定时器"
if systemctl is-active --quiet "$SERVICE_NAME.timer"; then
    sudo systemctl stop "$SERVICE_NAME.timer"
fi

if systemctl is-enabled --quiet "$SERVICE_NAME.timer"; then
    sudo systemctl disable "$SERVICE_NAME.timer"
fi

# 2. 停止并禁用 systemd 服务（如果存在）
echo "2. 停止并禁用 systemd 服务"
if systemctl is-active --quiet "$SERVICE_NAME.service"; then
    sudo systemctl stop "$SERVICE_NAME.service"
fi

if systemctl is-enabled --quiet "$SERVICE_NAME.service"; then
    sudo systemctl disable "$SERVICE_NAME.service"
fi

# 3. 重新加载 systemd 配置
echo "3. 重新加载 systemd 配置"
sudo systemctl daemon-reload 2>/dev/null || true

# 4. 删除 systemd 文件
echo "4. 删除 systemd 文件"
sudo rm -f "$SERVICE_PATH/$SERVICE_NAME.service"
sudo rm -f "$SERVICE_PATH/$SERVICE_NAME.timer"

# 5. 删除执行文件
echo "5. 删除执行文件"
sudo rm -f "$BIN_PATH/$EXEC_NAME"

echo "卸载完成！"
echo ""
echo "所有相关文件和 systemd 服务均已删除。"