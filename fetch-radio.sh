#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#
# Downloads the firmware images (radio/*.img) the ROM zip ships. They are not in
# git because modem.img is over GitHub's 100 MB file limit. Each file is checked
# against the SHA-1 that Android.mk expects.
#
# Run from anywhere:  bash vendor/xiaomi/pipa/fetch-radio.sh

set -euo pipefail

FIRMWARE="OS2.0.19.0.UMZCNXM"
BASE_URL="https://s3.msantoki.com/public/EvolutionX/pipa/firmware/${FIRMWARE}"
DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "${DIR}/radio"

grep -o 'radio/[a-z0-9_]*\.img,[0-9a-f]*' "${DIR}/Android.mk" | while IFS=, read -r path sha1; do
    file="${DIR}/${path}"
    if [ -f "${file}" ] && echo "${sha1}  ${file}" | sha1sum -c --status; then
        echo "ok ${path}"
        continue
    fi
    echo "downloading ${path}"
    curl -fsSL -o "${file}.part" "${BASE_URL}/$(basename "${path}")"
    if ! echo "${sha1}  ${file}.part" | sha1sum -c --status; then
        rm -f "${file}.part"
        echo "${path}: SHA-1 does not match Android.mk" >&2
        exit 1
    fi
    mv "${file}.part" "${file}"
done
echo "firmware ${FIRMWARE} ready"
