#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <apksigner> <apk> <expected-sha1-csv> <expected-sha256-csv>" >&2
  exit 2
fi

apksigner="$1"
apk="$2"
expected_sha1_csv="${3,,}"
expected_sha256_csv="${4,,}"

if [[ ! -f "${apksigner}" ]] && ! command -v "${apksigner}" >/dev/null 2>&1; then
  echo "apksigner is unavailable: ${apksigner}" >&2
  exit 1
fi
if [[ ! -f "${apk}" ]]; then
  echo "APK to verify does not exist: ${apk}" >&2
  exit 1
fi

IFS=',' read -r -a expected_sha1 <<<"${expected_sha1_csv}"
IFS=',' read -r -a expected_sha256 <<<"${expected_sha256_csv}"
if [[ ${#expected_sha1[@]} -eq 0 || ${#expected_sha1[@]} -ne ${#expected_sha256[@]} ]]; then
  echo "Expected signer SHA-1 and SHA-256 lists must have the same non-zero length." >&2
  exit 1
fi

verify_output="$("${apksigner}" verify --verbose --print-certs "${apk}")"
printf '%s\n' "${verify_output}"

grep -Fq "Verified using v2 scheme (APK Signature Scheme v2): true" \
  <<<"${verify_output}"
grep -Fq "Verified using v1 scheme (JAR signing): false" \
  <<<"${verify_output}"
grep -Fq "Verified using v3 scheme (APK Signature Scheme v3): false" \
  <<<"${verify_output}"
grep -Fq "Verified using v4 scheme (APK Signature Scheme v4): false" \
  <<<"${verify_output}"
grep -Fq "Number of signers: ${#expected_sha1[@]}" <<<"${verify_output}"

actual_sha1_csv="$({
  printf '%s\n' "${verify_output}" |
    sed -n 's/^Signer #[0-9][0-9]* certificate SHA-1 digest: //p' |
    tr '[:upper:]' '[:lower:]' |
    paste -sd, -
})"
actual_sha256_csv="$({
  printf '%s\n' "${verify_output}" |
    sed -n 's/^Signer #[0-9][0-9]* certificate SHA-256 digest: //p' |
    tr '[:upper:]' '[:lower:]' |
    paste -sd, -
})"

if [[ "${actual_sha1_csv}" != "${expected_sha1_csv}" ]]; then
  echo "Unexpected APK signer SHA-1 sequence: ${actual_sha1_csv}" >&2
  exit 1
fi
if [[ "${actual_sha256_csv}" != "${expected_sha256_csv}" ]]; then
  echo "Unexpected APK signer SHA-256 sequence: ${actual_sha256_csv}" >&2
  exit 1
fi
