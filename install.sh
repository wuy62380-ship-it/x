#!/usr/bin/env bash

set -e

GITHUB_USER="WUY62380-ship-it"
PROJECT="x"
REPO_BASE="https://raw.githubusercontent.com/${GITHUB_USER}/${PROJECT}/main"

XRAY_VERSION="v25.12.8"
GH="https://ghproxy.net/"
XRAY_X86_URL="${GH}https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-64.zip"

APP_DIR="/usr/local/x"
BIN_CMD="YW"
XRAY_BIN="/usr/local/bin/xray"
XRAY_CONF_DIR="/usr/local/etc/xray"
XRAY_CONF_FILE="${XRAY_CONF_DIR}/config.json"

log() { echo "[$1] $2"; }

banner() {
  clear
  echo "═══════════════════════════════════════"
  echo "           Y W   P A N E L"
  echo "═══════════════════════════════════════"
}

install_deps() {
  log INFO "安装必要依赖..."
  if command -v apt >/dev/null 2>&1; then
    apt update -y
    apt install -y curl wget unzip ca-certificates ntpdate
  elif command -v yum >/dev/null 2>&1; then
    yum install -y curl wget unzip ca-certificates ntpdate
  else
    log ERROR "不支持的系统，请使用 Debian/Ubuntu/CentOS"
    exit 1
  fi
}

fix_dns_time() {
  log INFO "修复 DNS..."
  cat >/etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF
  log INFO "同步系统时间..."
  ntpdate time.google.com >/dev/null 2>&1 || true
}

test_xray_x25519() {
  local out
  out="$(${XRAY_BIN} x25519 2>/dev/null || true)"
  if echo "$out" | grep -q "Private key" && echo "$out" | grep -q "Public key"; then
    return 0
  fi
  return 1
}

install_xray() {
  log INFO "安装 / 修复 Xray（固定版本 ${XRAY_VERSION}）..."
  mkdir -p /usr/local/bin
  cd /usr/local/bin

  rm -f xray xray.zip
  wget -q "${XRAY_X86_URL}" -O xray.zip
  if [ ! -s xray.zip ]; then
    log ERROR "下载 Xray 失败（zip 文件为空），请检查 VPS 到 GitHub/GHProxy 的网络"
    exit 1
  fi

  unzip -o xray.zip >/dev/null 2>&1
  chmod +x xray

  if ! test_xray_x25519; then
    log ERROR "Xray 安装后仍无法运行 x25519，当前环境无法用于 Reality"
    exit 1
  fi

  log INFO "Xray 安装成功，x25519 测试通过。"
}

setup_xray_service() {
  log INFO "配置 Xray systemd 服务..."
  mkdir -p "${XRAY_CONF_DIR}"

  if [ ! -f "${XRAY_CONF_FILE}" ]; then
    cat >"${XRAY_CONF_FILE}" <<EOF
{
  "inbounds": [],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
  fi

  cat >/etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=${XRAY_BIN} run -config ${XRAY_CONF_FILE}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable xray >/dev/null 2>&1 || true
  systemctl restart xray || true
}

install_yw_framework() {
  log INFO "安装 YW 面板框架到 ${APP_DIR}..."
  rm -rf "${APP_DIR}"
  mkdir -p "${APP_DIR}"/{modules,utils}

  # 主程序
  wget -q "${REPO_BASE}/YW.sh" -O "${APP_DIR}/YW.sh"

  # 工具
  wget -q "${REPO_BASE}/utils/common.sh" -O "${APP_DIR}/utils/common.sh"

  # 模块（先至少 Reality，一个示例）
  wget -q "${REPO_BASE}/modules/reality.sh" -O "${APP_DIR}/modules/reality.sh"

  chmod +x "${APP_DIR}/YW.sh"
  chmod +x "${APP_DIR}"/utils/*.sh
  chmod +x "${APP_DIR}"/modules/*.sh

  ln -sf "${APP_DIR}/YW.sh" "/usr/local/bin/${BIN_CMD}"
}

main() {
  banner
  install_deps
  fix_dns_time

  if ! command -v xray >/dev/null 2>&1 || ! test_xray_x25519; then
    install_xray
  else
    log INFO "检测到 Xray 且 x25519 正常，跳过安装。"
  fi

  setup_xray_service
  install_yw_framework

  echo
  echo "═══════════════════════════════════════"
  echo "           安装完成！"
  echo "═══════════════════════════════════════"
  echo
  echo " 命令：YW"
  echo " 作用：打开旗舰版 YW 面板"
  echo
}

main "$@"
