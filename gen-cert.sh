#!/bin/bash

mkdir -p /etc/hysteria/certs

openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout /etc/hysteria/certs/key.pem \
  -out /etc/hysteria/certs/cert.pem \
  -days 3650 -subj "/CN=Hysteria"

echo "证书已生成：/etc/hysteria/certs/"
