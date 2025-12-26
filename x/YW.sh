#!/usr/bin/env bash

APP_DIR="/usr/local/x"
UTILS_DIR="${APP_DIR}/utils"
MODULE_DIR="${APP_DIR}/modules"
XRAY_CONF_FILE="/usr/local/etc/xray/config.json"

# 加载共用函数
[ -f "${UTILS_DIR}/common.sh" ] && . "${UTILS_DIR}/common.sh"

banner() {
  clear
  echo "═══════════════════════════════════════"
  echo "           Y W   P A N E L"
  echo "═══════════════════════════════════════"
  echo " Version: 1.0        Engine: Xray-Core"
  echo " Config: ${XRAY_CONF_FILE}"
  echo "═══════════════════════════════════════"
  echo
}

menu() {
  banner
  echo " 1. 添加 VLESS Reality 节点"
  echo " 2. 查看 Xray 配置"
  echo " 3. 重启 Xray"
  echo " 4. 查看 Xray 状态"
  echo " 0. 退出"
  echo
  read -rp " 请选择: " opt

  case "$opt" in
    1)
      if [ -f "${MODULE_DIR}/reality.sh" ]; then
        . "${MODULE_DIR}/reality.sh"
        yw_reality_add
      else
        echo "Reality 模块不存在：${MODULE_DIR}/reality.sh"
        read -rp "按回车返回菜单..."
      fi
      ;;
    2)
      clear
      echo "===== /usr/local/etc/xray/config.json ====="
      echo
      cat "${XRAY_CONF_FILE}"
      echo
      read -rp "按回车返回菜单..."
      ;;
    3)
      systemctl restart xray
      echo "Xray 已重启。"
      read -rp "按回车返回菜单..."
      ;;
    4)
      systemctl status xray --no-pager
      read -rp "按回车返回菜单..."
      ;;
    0)
      exit 0
      ;;
    *)
      echo "无效选择。"
      sleep 1
      ;;
  esac
}

while true; do
  menu
done
