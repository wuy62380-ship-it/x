#!/usr/bin/env bash

# 依赖 common.sh 已由主程序加载

yw_reality_add() {
  clear
  echo "===== 添加 VLESS Reality 节点 ====="
  echo

  read -rp "监听端口 (默认 443): " PORT
  [ -z "$PORT" ] && PORT=443

  read -rp "SNI 列表（逗号分隔，例如 www.cloudflare.com）: " SNI_LIST
  if [ -z "$SNI_LIST" ]; then
    echo "SNI 不能为空。"
    read -rp "按回车返回..."
    return
  fi

  read -rp "目标域名 dest（留空=第一个 SNI）: " DEST_DOMAIN
  read -rp "目标端口 dest_port（默认 443）: " DEST_PORT
  [ -z "$DEST_PORT" ] && DEST_PORT=443

  read -rp "Fingerprint（默认 chrome）: " FP
  [ -z "$FP" ] && FP="chrome"

  local FIRST_SNI
  FIRST_SNI=$(echo "$SNI_LIST" | awk -F',' '{print $1}' | xargs)
  [ -z "$DEST_DOMAIN" ] && DEST_DOMAIN="$FIRST_SNI"

  local KEY_PAIR PRIVATE_KEY PUBLIC_KEY
  KEY_PAIR=$(xray x25519)
  PRIVATE_KEY=$(echo "$KEY_PAIR" | grep "Private key" | awk '{print $3}')
  PUBLIC_KEY=$(echo "$KEY_PAIR" | grep "Public key" | awk '{print $3}')

  if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    echo "Reality 密钥生成失败（xray x25519 异常）"
    read -rp "按回车返回..."
    return
  fi

  local SHORT_ID
  SHORT_ID=$(openssl rand -hex 8)

  local SERVER_NAMES_JSON
  SERVER_NAMES_JSON=$(echo "$SNI_LIST" | awk -F',' '
  {
    n=0;
    for(i=1;i<=NF;i++){
      gsub(/^[ \t]+|[ \t]+$/,"",$i);
      if($i!=""){
        if(n++) printf ", ";
        printf "\"" $i "\"";
      }
    }
  }')

  generate_uuid
  local SERVER_IP
  SERVER_IP=$(curl -s ipv4.ip.sb 2>/dev/null || curl -s ifconfig.me 2>/dev/null)

  local INBOUND_JSON
  INBOUND_JSON=$(cat <<EOF
{
  "tag": "vless-reality-${PORT}",
  "port": ${PORT},
  "protocol": "vless",
  "settings": {
    "clients": [
      {
        "id": "${UUID}",
        "flow": "xtls-rprx-vision"
      }
    ],
    "decryption": "none"
  },
  "streamSettings": {
    "network": "tcp",
    "security": "reality",
    "realitySettings": {
      "show": false,
      "dest": "${DEST_DOMAIN}:${DEST_PORT}",
      "xver": 0,
      "serverNames": [${SERVER_NAMES_JSON}],
      "privateKey": "${PRIVATE_KEY}",
      "shortIds": ["${SHORT_ID}"]
    }
  }
}
EOF
)

  append_inbound "${INBOUND_JSON}"
  restart_xray

  local LINK
  LINK="vless://${UUID}@${SERVER_IP}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${FIRST_SNI}&fp=${FP}&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&headerType=none#${FIRST_SNI}-Reality"

  clear
  echo "===== Reality 节点创建完成 ====="
  echo
  echo "服务器 IP: ${SERVER_IP}"
  echo "端口: ${PORT}"
  echo "UUID: ${UUID}"
  echo "SNI: ${SNI_LIST}"
  echo "Fingerprint: ${FP}"
  echo "公钥 (pbk): ${PUBLIC_KEY}"
  echo "私钥 (privateKey): ${PRIVATE_KEY}"
  echo "短 ID: ${SHORT_ID}"
  echo
  echo "vless 链接："
  echo "${LINK}"
  echo
  read -rp "按回车返回菜单..."
}
