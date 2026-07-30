#!/usr/bin/env bash
set -euo pipefail

# Check if the user just wants a quick binary update
UPDATE_ONLY=false
if [ "${1:-}" = "--update" ] || [ "${1:-}" = "-u" ]; then
    UPDATE_ONLY=true
fi

echo "========================================="
echo "   Antigravity CLI Universal Termux      "
echo "========================================="

if [ "$UPDATE_ONLY" = false ]; then
    echo "[*] Updating system packages & dependencies (Full Setup)..."
    apt update && apt full-upgrade -y
    pkg install -y python git curl ca-certificates glibc-repo glibc qemu-user-aarch64 tar coreutils
else
    echo "[*] Skipping system dependencies. Proceeding with quick binary update..."
fi

# Constants
MANIFEST_BASE_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app"
MANIFEST_URL="$MANIFEST_BASE_URL/manifests/linux_arm64.json"

TARGET_DIR="$HOME/.local/bin"
CACHE_DIR="$HOME/.cache/antigravity"
STAGING_DIR="$CACHE_DIR/staging"
PATCHER_DIR="$HOME/.local/share/agy/patcher"

mkdir -p "$TARGET_DIR" "$CACHE_DIR" "$STAGING_DIR"

# Choose downloader
if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget"
else
    echo "[ERROR] Either curl or wget is required but neither is installed." >&2
    exit 1
fi

fetch() {
    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fsSL "$1"
    else
        wget -q -O - "$1"
    fi
}

download_file() {
    src="$1"
    dst="$2"
    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fL --retry 3 --retry-delay 1 -o "$dst" "$src"
    else
        wget -q --tries=3 -O "$dst" "$src"
    fi
}

parse_json_key() {
    payload="$1"
    key="$2"
    printf '%s\n' "$payload" | sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

cleanup() {
    rm -f "${staging_payload:-}" "${extracted_binary:-}" 2>/dev/null || true
}
trap cleanup EXIT

# 1. Platform check
echo "[*] Detecting system environment..."
case "$(uname -s)" in
    Linux) os="linux" ;;
    *)
        echo "[ERROR] Unsupported operating system: $(uname -s)" >&2
        exit 1
        ;;
esac

case "$(uname -m)" in
    aarch64|arm64) arch="arm64" ;;
    x86_64|amd64)
        echo "[ERROR] This Termux installer is intended for arm64/aarch64." >&2
        exit 1
        ;;
    *)
        echo "[ERROR] Unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

platform="linux_arm64"
echo "[*] Platform detected: $platform"

# 2. Fetch manifest
echo "[*] Querying release manifest..."
manifest_json="$(fetch "$MANIFEST_URL" 2>/dev/null || true)"

if [ -z "$manifest_json" ]; then
    echo "[ERROR] Could not download manifest from $MANIFEST_URL" >&2
    exit 1
fi

version="$(parse_json_key "$manifest_json" version)"
url="$(parse_json_key "$manifest_json" url)"
sha512="$(parse_json_key "$manifest_json" sha512)"

if [ -z "$url" ] || [ -z "$sha512" ]; then
    echo "[ERROR] Failed to parse release manifest." >&2
    exit 1
fi

echo "[*] Latest available version: ${version:-unknown}"

# 3. Download package
is_tar_gz=false
case "$url" in
    *.tar.gz) is_tar_gz=true ;;
esac

if [ "$is_tar_gz" = true ]; then
    staging_payload="$STAGING_DIR/agy.tar.gz"
    extracted_binary="$STAGING_DIR/antigravity"
else
    staging_payload="$STAGING_DIR/agy"
    extracted_binary="$staging_payload"
fi

echo "[*] Downloading release package..."
download_file "$url" "$staging_payload"

# 4. Verify checksum
echo "[*] Verifying checksum..."
if command -v sha512sum >/dev/null 2>&1; then
    actual_hash="$(sha512sum "$staging_payload" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
    actual_hash="$(shasum -a 512 "$staging_payload" | awk '{print $1}')"
else
    echo "[ERROR] No SHA-512 tool found (sha512sum/shasum)." >&2
    exit 1
fi

if [ "$actual_hash" != "$sha512" ]; then
    echo "[ERROR] Checksum mismatch. Aborting." >&2
    exit 1
fi

echo "[*] Checksum verified."

# 5. Extract if needed
if [ "$is_tar_gz" = true ]; then
    echo "[*] Extracting binary..."
    rm -f "$extracted_binary" 2>/dev/null || true
    tar -xzf "$staging_payload" -C "$STAGING_DIR"
    if [ ! -f "$extracted_binary" ]; then
        echo "[ERROR] Expected extracted binary not found: $extracted_binary" >&2
        exit 1
    fi
fi

# 6. Install binary
echo "[*] Installing binary to $TARGET_DIR/agy..."
cp "$extracted_binary" "$TARGET_DIR/agy"
chmod +x "$TARGET_DIR/agy"

# 7. Refresh patcher tool
echo "[*] Refreshing memory layout patcher..."
mkdir -p "$HOME/.local/share/agy"
if [ -d "$PATCHER_DIR" ]; then
    rm -rf "$PATCHER_DIR"
fi

git clone --quiet https://gist.github.com/9e97f791db704f078dcf66d0dd9245ee.git "$PATCHER_DIR"

# 8. Apply memory patches
echo "[*] Executing memory space layout translation..."
python3 "$PATCHER_DIR/patch_va39" "$TARGET_DIR/agy"

# 9. Ensure environment links exist
mkdir -p /data/data/com.termux/files/usr/glibc/etc
ln -sfn /data/data/com.termux/files/usr/etc/resolv.conf /data/data/com.termux/files/usr/glibc/etc/resolv.conf

# 10. Rebuild execution wrapper
echo "[*] Updating environment wrapper..."
cat << 'EOF' > "$TARGET_DIR/agy-wrapper"
#!/data/data/com.termux/files/usr/bin/sh
unset LD_PRELOAD
unset LD_LIBRARY_PATH
export GODEBUG=netdns=go
export SSL_CERT_FILE=/data/data/com.termux/files/usr/etc/tls/cert.pem

exec qemu-aarch64 -cpu max \
  -L /data/data/com.termux/files/usr/glibc \
  "$HOME/.local/bin/agy.va39" "$@"
EOF
chmod +x "$TARGET_DIR/agy-wrapper"

# 11. Install alias helpers
if ! grep -q "alias agy=" "$HOME/.bashrc" 2>/dev/null; then
    echo "alias agy='$HOME/.local/bin/agy-wrapper'" >> "$HOME/.bashrc"
fi

if ! grep -q "alias agy-update=" "$HOME/.bashrc" 2>/dev/null; then
    echo "alias agy-update='curl -fsSL https://raw.githubusercontent.com/kayceepeece/antigravity-termux/main/install.sh | bash -s -- --update'" >> "$HOME/.bashrc"
fi

echo "========================================="
echo " [SUCCESS] Operation Complete!"
echo " Current version: $(~/.local/bin/agy-wrapper --version 2>/dev/null || echo 'Unknown')"
echo "========================================="
