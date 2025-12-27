#!/bin/bash

echo "=== 安装 Hysteria2 ==="
curl https://get.hy2.sh/ | bash

mkdir -p /etc/hysteria/certs

echo "=== 生成自签证书 ==="
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout /etc/hysteria/certs/key.pem \
  -out /etc/hysteria/certs/cert.pem \
  -days 3650 -subj "/CN=Hysteria"

echo "=== 写入配置文件 ==="
cat > /etc/hysteria/config.yaml << EOF
listen: :443
protocol: udp

auth:
  type: password
  password: "yourpassword"

tls:
  cert: /etc/hysteria/certs/cert.pem
  key: /etc/hysteria/certs/key.pem

quic:
  init_stream_window: 268435456
  max_stream_window: 268435456
  init_conn_window: 268435456
  max_conn_window: 268435456

bandwidth:
  up: 200 mbps
  down: 200 mbps

transport:
  udp:
    hop_interval: 30s
EOF

echo "=== 启动服务 ==="
systemctl enable hysteria-server
systemctl restart hysteria-server

echo "=== 完成！Hysteria2 已成功部署 ==="
