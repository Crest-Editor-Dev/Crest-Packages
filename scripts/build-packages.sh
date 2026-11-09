#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRCPKGS_DIR="${REPO_ROOT}/srcpkgs"

echo "==> Building custom XBPS packages..."
echo "    Repository Root: ${REPO_ROOT}"
echo "    Source Packages: ${SRCPKGS_DIR}"

if [ ! -d "${SRCPKGS_DIR}" ]; then
    echo "ERROR: srcpkgs directory not found at ${SRCPKGS_DIR}"
    exit 1
fi

for pkg_dir in "${SRCPKGS_DIR}"/*; do
    if [ ! -d "${pkg_dir}" ]; then
        continue
    fi

    pkg="$(basename "${pkg_dir}")"
    template_file="${pkg_dir}/template"

    if [ ! -f "${template_file}" ]; then
        echo "::warning:: No template found for package ${pkg}, skipping."
        continue
    fi

    # Reset package variables
    pkgname=""
    version=""
    revision="1"
    archs="aarch64"
    short_desc=""
    maintainer="CrestEditor Team <contact@crestcode.dev>"
    license="MIT"
    homepage=""
    depends=""

    # Source template to parse variables
    # shellcheck disable=SC1090
    source "${template_file}"

    if [ -z "${pkgname}" ] || [ -z "${version}" ]; then
        echo "::error:: Invalid template in ${pkg_dir} (missing pkgname or version)."
        exit 1
    fi

    pkgver="${pkgname}-${version}_${revision}"

    for arch in ${archs}; do
        arch_dir="${REPO_ROOT}/${arch}"
        mkdir -p "${arch_dir}"

        target_pkg="${arch_dir}/${pkgver}.${arch}.xbps"
        if [ -f "${target_pkg}" ]; then
            echo "    [SKIPPED] ${pkgver}.${arch}.xbps already built."
            continue
        fi

        echo "==> Building package: ${pkgver} (${arch})..."

        # Create staging destdir
        staging_dir=$(mktemp -d "/tmp/destdir-${pkgname}-XXXXXX")
        mkdir -p "${staging_dir}/usr/bin"

        # Check for files directory
        files_dir="${pkg_dir}/files"
        if [ -d "${files_dir}" ]; then
            if [ -f "${files_dir}/${pkgname}" ]; then
                cp -p "${files_dir}/${pkgname}" "${staging_dir}/usr/bin/${pkgname}"
                chmod 755 "${staging_dir}/usr/bin/${pkgname}"
            else
                # Copy entire files hierarchy if structured
                cp -a "${files_dir}/." "${staging_dir}/"
            fi
        fi

        # Prepare dependencies flags
        dep_flags=()
        if [ -n "${depends:-}" ]; then
            dep_flags+=("-D" "${depends}")
        fi

        # Run xbps-create
        (
            cd "${arch_dir}"
            xbps-create \
                -A "${arch}" \
                -n "${pkgver}" \
                -s "${short_desc:-${pkgname}}" \
                -m "${maintainer}" \
                -l "${license}" \
                -H "${homepage}" \
                "${dep_flags[@]}" \
                "${staging_dir}"
        )

        rm -rf "${staging_dir}"
        echo "    [SUCCESS] Created ${target_pkg}"
    done
done

echo "==> All packages built successfully!"
