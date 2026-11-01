#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEYS_DIR="${REPO_ROOT}/keys"
KEY_NAME="crest@crestcode.rsa.pub"
PRIV_KEY="${APK_PRIVATE_KEY_PATH:-${KEYS_DIR}/crest@crestcode.rsa}"
PUB_KEY="${KEYS_DIR}/${KEY_NAME}"

echo "==> Generating Alpine APK Repository Index..."
echo "    Repository Root: ${REPO_ROOT}"

# Ensure public key is trusted locally so apk index can verify packages
if [ -f "${PUB_KEY}" ]; then
    mkdir -p /etc/apk/keys 2>/dev/null || true
    cp -f "${PUB_KEY}" /etc/apk/keys/ 2>/dev/null || true
fi

# Architectures to index
ARCHES=("aarch64" "x86_64")

for arch in "${ARCHES[@]}"; do
    arch_dir="${REPO_ROOT}/${arch}"
    if [ ! -d "${arch_dir}" ]; then
        continue
    fi

    echo "==> Processing architecture: ${arch}..."
    cd "${arch_dir}"

    apk_count=$(find . -maxdepth 1 -name "*.apk" | wc -l)
    if [ "${apk_count}" -eq 0 ]; then
        echo "    No .apk packages found in ${arch_dir}, skipping."
        continue
    fi

    echo "    Found ${apk_count} package(s). Building APKINDEX.tar.gz..."
    rm -f APKINDEX.tar.gz APKINDEX

    # Generate APKINDEX.tar.gz
    apk index -v \
        --description "CrestEditor Alpine Repository" \
        -o APKINDEX.tar.gz \
        *.apk

    # Sign APKINDEX if private key is available
    if [ -f "${PRIV_KEY}" ]; then
        echo "    Signing APKINDEX.tar.gz with ${PRIV_KEY}..."
        abuild-sign -k "${PRIV_KEY}" -p "${KEY_NAME}" APKINDEX.tar.gz
        echo "    Index successfully signed!"
    else
        if [ "${REQUIRE_SIGNING:-0}" = "1" ]; then
            echo "ERROR: Signing required but private key not found at ${PRIV_KEY}!"
            exit 1
        else
            echo "WARNING: Private key not found at ${PRIV_KEY}. APKINDEX.tar.gz remains unsigned."
        fi
    fi

    echo "==> Architecture ${arch} indexing complete."
done

echo "==> Repository generation complete!"
