#!/bin/bash
#
# Copyright (C) 2020 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

CARBON_ROOT="${MY_DIR}"/../../..

HELPER="${CARBON_ROOT}/vendor/carbon/build/tools/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

SECTION=
KANG=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

# Initialize the helper for common device
setup_vendor "${DEVICE_COMMON}" "${VENDOR}" "${CARBON_ROOT}" true "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
        "${KANG}" --section "${SECTION}"

# Reinitialize the helper for device
source "${MY_DIR}/../${DEVICE}/extract-files.sh"
setup_vendor "${DEVICE}" "${VENDOR}" "${CARBON_ROOT}" false "${CLEAN_VENDOR}"
for BLOB_LIST in "${MY_DIR}"/../"${DEVICE}"/proprietary-files*.txt; do
    extract "${BLOB_LIST}" "${SRC}" \
            "${KANG}" --section "${SECTION}"
done

COMMON_BLOB_ROOT="${CARBON_ROOT}/vendor/${VENDOR}/${DEVICE_COMMON}/proprietary"

sed -i 's/<library name="android.hidl.manager-V1.0-java"/<library name="android.hidl.manager@1.0-java"/g' \
        "${COMMON_BLOB_ROOT}/etc/permissions/qti_libpermissions.xml"

"${MY_DIR}/setup-makefiles.sh"
