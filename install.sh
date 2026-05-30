#!/usr/bin/env bash

# Stop execution if any step fails
set -e

echo "========================================="
echo "   Antigravity CLI Universal Termux      "
echo "========================================="

# 1. Synchronize and perform full upgrade to prevent SSL/Linker mismatches
echo "[*] Updating system packages & dependencies..."
apt update && apt full-upgrade -y

# 2. Install required tooling matrix
echo "[*] Installing underlying framework packages..."
pkg install -y python git curl ca-certificates glibc-repo glibc qemu-user-aarch64

# 3. Create local binaries layout
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/agy
mkdir -p /data/data/com.termux/files/usr/glibc/etc

# 4. Fetch the official unmodified desktop Linux binary
echo "[*] Downloading official Antigravity CLI Linux binary..."
curl -L -o ~/.local/bin/agy https://antigravity.google/cli/releases/latest/linux-arm64/agy
chmod +x ~/.local/bin/agy

# 5. Clone the robust deep-pattern memory patch utility
echo "[*] Cloning deep-pattern memory layout patcher..."
if [ -d "$HOME/.local/share/agy/patcher" ]; then
    rm -rf "$HOME/.local/share/agy/patcher"
fi
git clone --quiet https://gist.github.com/9e97f791db704f078dcf66d0dd9245ee.git ~/.local/share/agy/patcher

# 6. Apply structural modifications to shift 48-bit pointers to 39-bit memory maps
echo "[*] Executing memory space layout translation..."
python3 ~/.local/share/agy/patcher/patch_va39 ~/.local/bin/agy

# 7. Establish internal networking links for the Glibc container environment
ln -sfn /data/data/com.termux/files/usr/etc/resolv.conf /data/data/com.termux/files/usr/glibc/etc/resolv.conf

# 8. Generate the structural execution wrapper (QEMU Emulation + Glibc loader)
echo "[*] Crafting execution environment wrapper..."
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

# 9. Register global alias mapping to shell startup profile
if ! grep -q "alias agy=" ~/.bashrc; then
    echo "[*] Appending global environment system alias..."
    echo "alias agy='~/.local/bin/agy-wrapper'" >> ~/.bashrc
fi

echo "========================================="
echo " [SUCCESS] Antigravity CLI Installation Complete!"
echo " Run 'source ~/.bashrc' or restart Termux."
echo " Then verify via: agy --version"
echo "========================================="
