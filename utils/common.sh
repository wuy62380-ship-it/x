#!/usr/bin/env bash

XRAY_CONF_FILE="/usr/local/etc/xray/config.json"

log_yw() {
  echo "[YW] $*"
}

generate_uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    UUID=$(uuidgen)
  else
    UUID=$(cat /proc/sys/kernel/random/uuid)
  fi
}

restart_xray() {
  systemctl restart xray
}

# 这里给一个简单的“追加 inbound”实现
append_inbound() {
  local inbound_json="$1"

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

  # 用 jq 会更干净，这里假设安装了 jq
  if ! command -v jq >/dev/null 2>&1; then
    log_yw "未检测到 jq，正在安装..."
    if command -v apt >/dev/null 2>&1; then
      apt update -y && apt install -y jq
    elif command -v yum >/dev/null 2>&1; then
      yum install -y jq
    fi
  fi

  local new_conf
  new_conf=$(jq --argjson inbound "${inbound_json}" '.inbounds += [$inbound]' "${XRAY_CONF_FILE}")
  echo "${new_conf}" >"${XRAY_CONF_FILE}"
}
