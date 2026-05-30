#!/usr/bin/env bash
set -e

# Check if the user just wants a quick binary update
UPDATE_ONLY=false
if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then
    UPDATE_ONLY=true
fi

echo "========================================="
echo "   Antigravity CLI Universal Termux      "
echo "========================================="

if [ "$UPDATE_ONLY" = false ]; then
    echo "[*] Updating system packages & dependencies (Full Setup)..."
    apt update && apt full-upgrade -y
    pkg install -y python git curl ca-certificates glibc-repo glibc qemu-user-aarch64
else
    echo "[*] Skipping system dependencies. Proceeding with quick binary update..."
fi

# 1. Download latest version (overwrites old binary)
echo "[*] Downloading latest Antigravity CLI Linux binary..."
mkdir -p ~/.local/bin
curl -L -o ~/.local/bin/agy https://antigravity.google/cli/releases/latest/linux-arm64/agy
chmod +x ~/.local/bin/agy

# 2. Refresh patcher tool
echo "[*] Refreshing memory layout patcher..."
mkdir -p ~/.local/share/agy
if [ -d "$HOME/.local/share/agy/patcher" ]; then
    rm -rf "$HOME/.local/share/agy/patcher"
fi
git clone --quiet https://gist.github.com/9e97f791db704f078dcf66d0dd9245ee.git ~/.local/share/agy/patcher

# 3. Apply memory patches
echo "[*] Executing memory space layout translation..."
python3 ~/.local/share/agy/patcher/patch_va39 ~/.local/bin/agy

# 4. Ensure environment links exist
mkdir -p /data/data/com.termux/files/usr/glibc/etc
ln -sfn /data/data/com.termux/files/usr/etc/resolv.conf /data/data/com.termux/files/usr/glibc/etc/resolv.conf

# 5. Rebuild execution wrapper
echo "[*] Updating environment wrapper..."
cat << 'EOF' > ~/.local/bin/agy-wrapper
#!/data/data/com.termux/files/usr/bin/sh
unset LD_PRELOAD
unset LD_LIBRARY_PATH
export GODEBUG=netdns=go
export SSL_CERT_FILE=/data/data/com.termux/files/usr/etc/tls/cert.pem

exec qemu-aarch64 -cpu max \
  -L /data/data/com.termux/files/usr/glibc \
  $HOME/.local/bin/agy.va39 "$@"
EOF
chmod +x ~/.local/bin/agy-wrapper

# 6. Setup local aliases
if ! grep -q "alias agy=" ~/.bashrc; then
    echo "alias agy='~/.local/bin/agy-wrapper'" >> ~/.bashrc
fi
# Add an easy shortcut for updating directly
if ! grep -q "alias agy-update=" ~/.bashrc; then
    echo "alias agy-update='curl -fsSL https://raw.githubusercontent.com/kayceepeece/antigravity-termux/main/install.sh | bash -s -- --update'" >> ~/.bashrc
fi

echo "========================================="
echo " [SUCCESS] Operation Complete!"
echo " Current version: $(~/.local/bin/agy-wrapper --version 2>/dev/null || echo 'Unknown')"
echo "========================================="
