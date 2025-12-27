#!/bin/bash

# 自动读取密码
PASS=$(grep -E "password:" /etc/hysteria/config.yaml | awk '{print $2}' | tr -d '"')

# 自动获取公网 IP
IP=$(curl -s ifconfig.me)

# 输出最终导入链接
echo ""
echo "=== Hysteria2 导入链接（自动生成） ==="
echo "hysteria2://$PASS@$IP:443/?insecure=1&upmbps=50&downmbps=100#HY2-Node"
echo ""
