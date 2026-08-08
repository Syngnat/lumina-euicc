#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <source-archive.zip> <git-commit> <archive-prefix>" >&2
  exit 2
fi

archive="$1"
commit="$2"
prefix="${3%/}/"

if [[ ! -f "${archive}" ]]; then
  echo "Source archive does not exist: ${archive}" >&2
  exit 1
fi

git cat-file -e "${commit}^{commit}"

expected_files="$(mktemp)"
archive_files="$(mktemp)"
trap 'rm -f "${expected_files}" "${archive_files}"' EXIT

git ls-tree -r --name-only "${commit}" | LC_ALL=C sort > "${expected_files}"
unzip -Z1 "${archive}" |
  sed -e '/\/$/d' -e "s#^${prefix}##" |
  LC_ALL=C sort > "${archive_files}"

if ! diff -u "${expected_files}" "${archive_files}"; then
  echo "Source archive does not exactly match tracked files at ${commit}." >&2
  exit 1
fi

required_paths=(
  LICENSE
  LICENSES_SCOPE.md
  NOTICE.md
  THIRD_PARTY_NOTICES.md
  README.md
  pubspec.yaml
  pubspec.lock
  android/gradlew
  android/settings.gradle
  android/build.gradle
  android/app/build.gradle
  android/gradle/wrapper/gradle-wrapper.jar
  android/gradle/wrapper/gradle-wrapper.properties
  .github/scripts/check-runtime-dependencies.sh
  .github/scripts/check-source-archive.sh
  .github/scripts/collect-gradle-sources.init.gradle
  .github/scripts/collect-pub-sources.py
  .github/scripts/create-release-bundle.sh
  .github/scripts/make-zip.py
  android/app/src/main/kotlin/top/syngnat/lumina/euicc/EuiccBridgePlugin.kt
  lib/main.dart
  third_party/OpenEUICC/LICENSE
  third_party/OpenEUICC/app-common/build.gradle.kts
  third_party/OpenEUICC/libs/lpac-jni/LICENSE
  third_party/OpenEUICC/libs/lpac-jni/src/main/jni/lpac-jni/lpac-jni.c
  third_party/OpenEUICC/libs/lpac-jni/src/main/jni/cjson/cjson/LICENSE
  third_party/OpenEUICC/libs/lpac-jni/src/main/jni/lpac/LICENSES/GPL-2.0-only.txt
  third_party/OpenEUICC/libs/lpac-jni/src/main/jni/lpac/LICENSES/LGPL-2.1-only.txt
  third_party/OpenEUICC/libs/lpac-jni/src/main/jni/lpac/LICENSES/MIT.txt
)

for path in "${required_paths[@]}"; do
  if ! grep -Fxq "${path}" "${archive_files}"; then
    echo "Required corresponding-source file is missing: ${path}" >&2
    exit 1
  fi
done

forbidden_name_pattern='(^|/)(key\.properties|[^/]+\.(jks|keystore|p12|pfx|pem)|id_(rsa|dsa|ecdsa|ed25519)|[^/]*private[-_.]?key[^/]*)$'
if grep -Eiq "${forbidden_name_pattern}" "${archive_files}"; then
  echo "Signing material must not be tracked or included in source archives." >&2
  grep -Ei "${forbidden_name_pattern}" "${archive_files}" >&2
  exit 1
fi

if git grep -I -n -E \
  -e '-----BEGIN (RSA |EC |DSA |OPENSSH |ENCRYPTED )?PRIVATE KEY-----' \
  "${commit}" --; then
  echo "Private-key material must not be tracked or included in source archives." >&2
  exit 1
fi

echo "Source archive exactly matches ${commit} and contains the required sources and licenses."
