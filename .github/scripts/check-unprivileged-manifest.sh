#!/usr/bin/env bash
set -euo pipefail

apk_path="${1:?usage: check-unprivileged-manifest.sh <apk>}"
android_home="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"

if [[ -z "${android_home}" ]]; then
  echo "ANDROID_HOME or ANDROID_SDK_ROOT is required" >&2
  exit 2
fi

aapt="${android_home}/build-tools/35.0.0/aapt"
if [[ ! -x "${aapt}" ]]; then
  echo "aapt not found: ${aapt}" >&2
  exit 2
fi

manifest_permissions="$("${aapt}" dump permissions "${apk_path}")"
for permission in \
  android.permission.READ_PRIVILEGED_PHONE_STATE \
  android.permission.MODIFY_PHONE_STATE \
  android.permission.WRITE_EMBEDDED_SUBSCRIPTIONS \
  android.permission.MANAGE_EMBEDDED_SUBSCRIPTIONS \
  android.permission.BIND_EUICC_SERVICE \
  android.permission.WRITE_SECURE_SETTINGS; do
  if grep -Fq "uses-permission: name='${permission}'" <<<"${manifest_permissions}"; then
    echo "Privileged permission is forbidden in the rootless app: ${permission}" >&2
    exit 1
  fi
done

echo "Unprivileged manifest policy: OK"
