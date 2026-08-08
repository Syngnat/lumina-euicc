#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <apksigner> <apk> [<apk> ...]" >&2
  exit 2
fi

apksigner="$1"
shift

for required_variable in \
  LUMINA_KEYSTORE_PATH \
  ANDROID_KEYSTORE_PASSWORD \
  ANDROID_KEY_ALIAS \
  ANDROID_KEY_PASSWORD \
  COMMUNITY_SAKURA_KEYSTORE_PATH \
  COMMUNITY_SAKURA_KEYSTORE_PASSWORD \
  COMMUNITY_NEKOKO_KEYSTORE_PATH \
  COMMUNITY_NEKOKO_KEYSTORE_PASSWORD \
  COMMUNITY_9ESIM_KEYSTORE_PATH \
  COMMUNITY_9ESIM_KEYSTORE_PASSWORD; do
  if [[ -z "${!required_variable:-}" ]]; then
    echo "Missing multi-signer input: ${required_variable}" >&2
    exit 1
  fi
done

if [[ ! -f "${apksigner}" ]] && ! command -v "${apksigner}" >/dev/null 2>&1; then
  echo "apksigner is unavailable: ${apksigner}" >&2
  exit 1
fi

for keystore in \
  "${LUMINA_KEYSTORE_PATH}" \
  "${COMMUNITY_SAKURA_KEYSTORE_PATH}" \
  "${COMMUNITY_NEKOKO_KEYSTORE_PATH}" \
  "${COMMUNITY_9ESIM_KEYSTORE_PATH}"; do
  if [[ ! -f "${keystore}" ]]; then
    echo "Required signer keystore does not exist: ${keystore}" >&2
    exit 1
  fi
done

for apk in "$@"; do
  if [[ ! -f "${apk}" ]]; then
    echo "APK to sign does not exist: ${apk}" >&2
    exit 1
  fi

  signed_apk="${apk}.multisigned"
  if [[ -e "${signed_apk}" ]]; then
    echo "Refusing to overwrite temporary signed APK: ${signed_apk}" >&2
    exit 1
  fi

  "${apksigner}" sign \
    --out "${signed_apk}" \
    --v1-signing-enabled false \
    --v2-signing-enabled true \
    --v3-signing-enabled false \
    --v4-signing-enabled false \
    --ks "${LUMINA_KEYSTORE_PATH}" \
    --ks-key-alias "${ANDROID_KEY_ALIAS}" \
    --ks-pass env:ANDROID_KEYSTORE_PASSWORD \
    --key-pass env:ANDROID_KEY_PASSWORD \
    --next-signer \
    --ks "${COMMUNITY_SAKURA_KEYSTORE_PATH}" \
    --ks-pass env:COMMUNITY_SAKURA_KEYSTORE_PASSWORD \
    --key-pass env:COMMUNITY_SAKURA_KEYSTORE_PASSWORD \
    --next-signer \
    --ks "${COMMUNITY_NEKOKO_KEYSTORE_PATH}" \
    --ks-pass env:COMMUNITY_NEKOKO_KEYSTORE_PASSWORD \
    --key-pass env:COMMUNITY_NEKOKO_KEYSTORE_PASSWORD \
    --next-signer \
    --ks "${COMMUNITY_9ESIM_KEYSTORE_PATH}" \
    --ks-pass env:COMMUNITY_9ESIM_KEYSTORE_PASSWORD \
    --key-pass env:COMMUNITY_9ESIM_KEYSTORE_PASSWORD \
    "${apk}"

  mv -- "${signed_apk}" "${apk}"
done
