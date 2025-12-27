#!/usr/bin/env bash
set -e

# ============================================
#  Detect architecture
# ============================================
detect_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        *)
            echo "[ERROR] Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
}

# ============================================
#  Install or update Hysteria2
# ============================================
install_or_update_hysteria2() {
    echo "[HY2] Fetching latest Hysteria2 version..."

    RAW_VERSION=$(curl -fsSL https://api.github.com/repos/apernet/hysteria/releases/latest \
        | grep tag_name | cut -d '"' -f 4)

    if [[ -z "$RAW_VERSION" ]]; then
        echo "[ERROR] Failed to fetch latest Hysteria2 version"
        exit 1
    fi

    # Remove "app/" prefix if present
    LATEST_VERSION=${RAW_VERSION#app/}

    echo "[HY2] Latest version: $LATEST_VERSION"

    ARCH=$(detect_arch)

    DOWNLOAD_URL="https://github.com/apernet/hysteria/releases/download/${LATEST_VERSION}/hysteria-linux-${ARCH}.zip"

    echo "[HY2] Downloading: $DOWNLOAD_URL"
    curl -fsSL "$DOWNLOAD_URL" -o hysteria.zip

    echo "[HY2] Extracting..."
    unzip -o hysteria.zip >/dev/null 2>&1

    # Find extracted binary
    BIN_FILE=$(find . -maxdepth 1 -type f -name "hysteria*" ! -name "*.zip" | head -n 1)

    if [[ -z "$BIN_FILE" ]]; then
        echo "[ERROR] Extracted package does not contain hysteria binary"
        exit 1
    fi

    mv "$BIN_FILE" /usr/local/bin/hysteria
    chmod +x /usr/local/bin/hysteria
    rm -f hysteria.zip

    echo "[HY2] Installed to /usr/local/bin/hysteria"
}

# ============================================
#  Install systemd service
# ============================================
install_systemd_service() {
    echo "[SYSTEMD] Installing hysteria-server.service..."

    cat >/etc/systemd/system/hysteria-server.service <<EOF
[Unit]
Description=Hysteria2 Server
After=network.target

[Service]
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable hysteria-server
}

# ============================================
#  Deploy config
# ============================================
deploy_config() {
    echo "[CONFIG] Deploying config.yaml..."
    mkdir -p /etc/hysteria

    if [[ -f "config.yaml" ]]; then
        cp config.yaml /etc/hysteria/config.yaml
    else
        echo "[WARN] config.yaml not found in repository"
    fi
}

# ============================================
#  Deploy client config
# ============================================
deploy_client() {
    echo "[CLIENT] Deploying client.yaml..."

    if [[ -f "client.yaml" ]]; then
        cp client.yaml /etc/hysteria/client.yaml
    else
        echo "[WARN] client.yaml not found in repository"
    fi
}

# ============================================
#  Restart service
# ============================================
restart_service() {
    echo "[SYSTEMD] Restarting hysteria-server..."
    systemctl restart hysteria-server
}

# ============================================
#  Main
# ============================================
main() {
    echo "======================================="
    echo "   Hysteria2 Auto Installer (ship-it)   "
    echo "======================================="

    install_or_update_hysteria2
    install_systemd_service
    deploy_config
    deploy_client
    restart_service

    echo "======================================="
    echo " Hysteria2 installation completed"
    echo " Version: $LATEST_VERSION"
    echo " Config:  /etc/hysteria/config.yaml"
    echo "======================================="
}

main
