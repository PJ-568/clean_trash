#!/usr/bin/env bash

# 安装脚本 - 将 clean_trash.sh 安装到系统并创建 systemd 服务

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

# 定义安装路径
BIN_PATH="/usr/local/bin"
SERVICE_PATH="/etc/systemd/system"

# 检查是否是远程安装模式（通过管道执行）
if [ -t 0 ]; then
    # 本地执行模式
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ROOT_DIR="$(dirname "$SCRIPT_DIR")"
    CLEAN_TRASH_SOURCE="$ROOT_DIR/clean_trash.sh"
    
    recho "本地安装模式" "Local installation mode"
else
    # 远程执行模式（通过管道）
    recho "远程安装模式" "Remote installation mode"
    CLEAN_TRASH_SOURCE="https://raw.githubusercontent.com/PJ-568/clean_trash/master/clean_trash.sh"
fi

recho "正在安装 $EXEC_NAME..." "Installing $EXEC_NAME..."

# 1. 复制/下载执行文件到系统路径
recho "1. 安装执行文件到 $BIN_PATH/$EXEC_NAME" "1. Installing executable to $BIN_PATH/$EXEC_NAME"
if [ -t 0 ]; then
    # 本地复制
    sudo cp "$CLEAN_TRASH_SOURCE" "$BIN_PATH/$EXEC_NAME"
else
    # 远程下载
    sudo curl -sSL "$CLEAN_TRASH_SOURCE" -o "$BIN_PATH/$EXEC_NAME"
fi
sudo chmod +x "$BIN_PATH/$EXEC_NAME"

# 2. 创建 systemd 服务文件
recho "2. 创建 systemd 服务文件" "2. Creating systemd service file"
sudo tee "$SERVICE_PATH/$SERVICE_NAME.service" > /dev/null <<EOF
[Unit]
Description=Clean Trash Service
After=multi-user.target

[Service]
Type=oneshot
User=$USER
ExecStart=$BIN_PATH/$EXEC_NAME 30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 3. 创建 systemd 定时器文件
recho "3. 创建 systemd 定时器文件" "3. Creating systemd timer file"
sudo tee "$SERVICE_PATH/$SERVICE_NAME.timer" > /dev/null <<EOF
[Unit]
Description=Clean trash daily
Requires=$SERVICE_NAME.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 重新加载 systemd 配置
recho "4. 重新加载 systemd 配置" "4. Reloading systemd configuration"
sudo systemctl daemon-reload

recho "安装完成！" "Installation completed!"
echo ""
recho "要启用每天自动清理，请运行：" "To enable daily automatic cleanup, run:"
echo "  sudo systemctl enable --now $SERVICE_NAME.timer"
echo ""
recho "要手动运行清理：" "To run cleanup manually:"
echo "  $EXEC_NAME 30"
echo ""
recho "要查看服务状态：" "To check service status:"
echo "  systemctl status $SERVICE_NAME.timer"