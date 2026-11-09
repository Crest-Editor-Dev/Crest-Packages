#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEYS_DIR="${REPO_ROOT}/keys"
PRIV_KEY="${XBPS_PRIVATE_KEY_PATH:-${KEYS_DIR}/crest@crestcode.rsa}"
SIGN_IDENTITY="${XBPS_SIGN_IDENTITY:-CrestEditor}"

echo "==> Generating Void Linux XBPS Repository Index..."
echo "    Repository Root: ${REPO_ROOT}"

# Architectures to index
ARCHES=("aarch64" "x86_64")

for arch in "${ARCHES[@]}"; do
    arch_dir="${REPO_ROOT}/${arch}"
    if [ ! -d "${arch_dir}" ]; then
        continue
    fi

    echo "==> Processing architecture: ${arch}..."
    cd "${arch_dir}"

    xbps_count=$(find . -maxdepth 1 -name "*.xbps" | wc -l)
    if [ "${xbps_count}" -eq 0 ]; then
        echo "    No .xbps packages found in ${arch_dir}, skipping."
        continue
    fi

    echo "    Found ${xbps_count} package(s). Building repodata..."

    # Add/update all packages into repodata
    xbps-rindex -a *.xbps

    # Sign packages and repository index if private key is present
    if [ -f "${PRIV_KEY}" ]; then
        echo "    Signing packages with ${PRIV_KEY}..."
        xbps-rindex --privkey "${PRIV_KEY}" --sign-pkg *.xbps

        echo "    Signing repository index for ${arch}..."
        xbps-rindex --privkey "${PRIV_KEY}" --sign --signedby "${SIGN_IDENTITY}" .
        echo "    Repository index successfully signed!"
    else
        if [ "${REQUIRE_SIGNING:-0}" = "1" ]; then
            echo "ERROR: Signing required but private key not found at ${PRIV_KEY}!"
            exit 1
        else
            echo "WARNING: Private key not found at ${PRIV_KEY}. Repository index remains unsigned."
        fi
    fi

    echo "==> Architecture ${arch} indexing complete."
done

echo "==> XBPS Repository generation complete!"
