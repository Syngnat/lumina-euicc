#!/usr/bin/env bash

set -euo pipefail

forbidden_name_pattern='(^|/)(key\.properties|[^/]+\.(jks|keystore|p12|pfx|pem)|id_(rsa|dsa|ecdsa|ed25519)|[^/]*private[-_.]?key[^/]*)$'
private_key_pattern='-----BEGIN (RSA |EC |DSA |OPENSSH |ENCRYPTED )?PRIVATE KEY-----'

find_suspicious_files() {
  local root="$1"
  find "${root}" -path "${root}/.git" -prune -o -type f \
    \( -iname 'key.properties' \
       -o -iname '*.jks' \
       -o -iname '*.keystore' \
       -o -iname '*.p12' \
       -o -iname '*.pfx' \
       -o -iname '*.pem' \
       -o -iname 'id_rsa' \
       -o -iname 'id_dsa' \
       -o -iname 'id_ecdsa' \
       -o -iname 'id_ed25519' \
       -o -iname '*private-key*' \
       -o -iname '*private_key*' \
       -o -iname '*privatekey*' \) -print
}

assert_tree_has_no_signing_material() {
  local root="$1"
  local label="$2"
  local suspicious_files
  local private_keys

  suspicious_files="$(find_suspicious_files "${root}")"
  if [[ -n "${suspicious_files}" ]]; then
    echo "${label} contains signing/private-key filename(s):" >&2
    printf '%s\n' "${suspicious_files}" >&2
    exit 1
  fi

  private_keys="$(
    grep -RIlE --binary-files=without-match -- "${private_key_pattern}" "${root}" 2>/dev/null || true
  )"
  if [[ -n "${private_keys}" ]]; then
    echo "${label} contains private-key material:" >&2
    printf '%s\n' "${private_keys}" >&2
    exit 1
  fi
}

assert_archive_entry_names_are_safe() {
  local archive="$1"
  local label="$2"
  local entries
  local matches

  entries="$(unzip -Z1 "${archive}")"
  matches="$(grep -Ei "${forbidden_name_pattern}" <<<"${entries}" || true)"
  if [[ -n "${matches}" ]]; then
    echo "${label} contains signing/private-key filename(s):" >&2
    printf '%s\n' "${matches}" >&2
    exit 1
  fi
}

if [[ $# -ne 6 ]]; then
  echo "Usage: $0 <universal-apk> <arm64-v8a-apk> <armeabi-v7a-apk> <x86_64-apk> <output-directory> <git-commit>" >&2
  exit 2
fi

for required_command in git unzip tar python3 flutter java; do
  if ! command -v "${required_command}" >/dev/null 2>&1; then
    echo "Required release command is unavailable: ${required_command}" >&2
    exit 1
  fi
done

universal_apk="$1"
arm64_apk="$2"
armeabi_v7a_apk="$3"
x86_64_apk="$4"
output_dir="$5"
commit="$6"

for apk in \
  "${universal_apk}" \
  "${arm64_apk}" \
  "${armeabi_v7a_apk}" \
  "${x86_64_apk}"; do
  if [[ ! -f "${apk}" ]]; then
    echo "Signed APK does not exist: ${apk}" >&2
    exit 1
  fi
done

for legal_file in LICENSE LICENSES_SCOPE.md NOTICE.md THIRD_PARTY_NOTICES.md; do
  if [[ ! -f "${legal_file}" ]]; then
    echo "Required release legal file is missing: ${legal_file}" >&2
    exit 1
  fi
done

release_notes_template=".github/release-notes.md"
if [[ ! -f "${release_notes_template}" ]]; then
  echo "Required release notes template is missing: ${release_notes_template}" >&2
  exit 1
fi

git cat-file -e "${commit}^{commit}"
if [[ "$(git rev-parse "${commit}^{commit}")" != "$(git rev-parse HEAD^{commit})" ]]; then
  echo "Release commit must be the checked-out HEAD." >&2
  exit 1
fi
if ! git -c core.filemode=false diff --quiet "${commit}" --; then
  echo "Tracked build inputs differ from the commit used for the source archive." >&2
  git -c core.filemode=false status --short --untracked-files=no >&2
  exit 1
fi

workspace_suspicious="$(find_suspicious_files .)"
if [[ -n "${workspace_suspicious}" ]]; then
  echo "Refusing to package while signing/private-key files exist in the workspace:" >&2
  printf '%s\n' "${workspace_suspicious}" >&2
  exit 1
fi

version="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -n 1)"
if [[ -z "${version}" ]]; then
  echo "Could not read the application version from pubspec.yaml." >&2
  exit 1
fi

short_commit="${commit:0:12}"
safe_version="${version//+/-}"
version_name="${version%%+*}"
source_prefix="lumina-euicc-${commit}"
universal_apk_name="lumina-euicc-${safe_version}-universal.apk"
arm64_apk_name="lumina-euicc-${safe_version}-arm64-v8a.apk"
armeabi_v7a_apk_name="lumina-euicc-${safe_version}-armeabi-v7a.apk"
x86_64_apk_name="lumina-euicc-${safe_version}-x86_64.apk"
source_name="lumina-euicc-source-${commit}.zip"
dependency_sources_name="lumina-euicc-dependency-sources-${commit}.zip"
license_materials_root="lumina-euicc-license-materials-${commit}"
license_materials_name="${license_materials_root}.zip"
repository_url="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-Syngnat/lumina-euicc}"
run_url="${repository_url}/actions/runs/${GITHUB_RUN_ID:-local}"
flutter_toolchain="$(flutter --version)"
flutter_machine="$(flutter --version --machine)"
java_toolchain="$(java -version 2>&1)"
gradle_toolchain="$(cd android && ./gradlew --version --no-daemon)"
flutter_version="$(printf '%s\n' "${flutter_toolchain}" | head -n 1)"
java_version="$(printf '%s\n' "${java_toolchain}" | head -n 1)"
gradle_version="$(printf '%s\n' "${gradle_toolchain}" | sed -n 's/^Gradle /Gradle /p' | head -n 1)"
framework_revision="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("frameworkRevision", "missing"))' <<<"${flutter_machine}")"
engine_revision="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("engineRevision", "missing"))' <<<"${flutter_machine}")"
flutter_repository="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("repositoryUrl", "https://github.com/flutter/flutter.git"))' <<<"${flutter_machine}")"

if [[ -e "${output_dir}" ]]; then
  echo "Refusing to overwrite an existing release output: ${output_dir}" >&2
  exit 1
fi
mkdir -p "${output_dir}"
output_dir="$(cd "${output_dir}" && pwd -P)"

staging_directory="$(mktemp -d)"
cleanup() {
  rm -rf -- "${staging_directory}"
}
trap cleanup EXIT

cp "${universal_apk}" "${output_dir}/${universal_apk_name}"
cp "${arm64_apk}" "${output_dir}/${arm64_apk_name}"
cp "${armeabi_v7a_apk}" "${output_dir}/${armeabi_v7a_apk_name}"
cp "${x86_64_apk}" "${output_dir}/${x86_64_apk_name}"
sed "s/@VERSION@/${safe_version}/g" \
  "${release_notes_template}" > "${output_dir}/RELEASE_NOTES.md"
if grep -Fq '@VERSION@' "${output_dir}/RELEASE_NOTES.md"; then
  echo "Release notes still contain an unresolved @VERSION@ placeholder." >&2
  exit 1
fi

# Start with git-archive semantics, then restore tracked export-ignore paths from
# the same immutable tree so the corresponding-source ZIP contains every file.
git archive --format=tar --prefix="${source_prefix}/" "${commit}" |
  tar -xf - -C "${staging_directory}"
temporary_index="${staging_directory}/git-index"
GIT_INDEX_FILE="${temporary_index}" git read-tree "${commit}"
GIT_INDEX_FILE="${temporary_index}" git checkout-index \
  --all \
  --force \
  --prefix="${staging_directory}/${source_prefix}/"
rm -f "${temporary_index}"
python3 .github/scripts/make-zip.py \
  "${output_dir}/${source_name}" \
  "${staging_directory}" \
  "${source_prefix}"

bash .github/scripts/check-source-archive.sh \
  "${output_dir}/${source_name}" \
  "${commit}" \
  "${source_prefix}"

cp LICENSE LICENSES_SCOPE.md NOTICE.md THIRD_PARTY_NOTICES.md "${output_dir}/"

license_manifest="${output_dir}/LICENSES_MANIFEST.txt"
while IFS= read -r license_path; do
  destination="${output_dir}/licenses/${license_path}"
  mkdir -p "$(dirname "${destination}")"
  git show "${commit}:${license_path}" > "${destination}"
  printf '%s\n' "${license_path}" >> "${license_manifest}"
done < <(
  git ls-tree -r --name-only "${commit}" |
    awk '{ path = tolower($0) }
      path ~ /(^|\/)(license[^\/]*|notice[^\/]*|copying[^\/]*|reuse\.toml)$/ || path ~ /\/licenses\//'
)

if [[ ! -s "${license_manifest}" ]]; then
  echo "No tracked license or notice files were collected." >&2
  exit 1
fi

license_materials_staging="${staging_directory}/${license_materials_root}"
mkdir -p "${license_materials_staging}"
cp LICENSE LICENSES_SCOPE.md NOTICE.md THIRD_PARTY_NOTICES.md \
  "${license_manifest}" \
  "${license_materials_staging}/"
cp -R "${output_dir}/licenses" "${license_materials_staging}/licenses"
python3 .github/scripts/make-zip.py \
  "${output_dir}/${license_materials_name}" \
  "${staging_directory}" \
  "${license_materials_root}"

printf '%s\n' "${flutter_machine}" > "${output_dir}/FLUTTER_VERSION.json"

cat > "${output_dir}/SOURCE_INFO.txt" <<EOF
Project: Lumina eUICC
Repository: ${repository_url}
Commit: ${commit}
Commit source: ${repository_url}/tree/${commit}
Workflow run: ${run_url}
Source archive: ${source_name}
Dependency sources: ${dependency_sources_name}
License materials: ${license_materials_name}
Package: ${EXPECTED_PACKAGE_ID:-top.syngnat.lumina.euicc}
Version: ${version}
Flutter: ${flutter_version}
Java: ${java_version}
Gradle: ${gradle_version}
Flutter framework revision: ${framework_revision}
Flutter framework source: https://github.com/flutter/flutter/tree/${framework_revision}
Flutter repository: ${flutter_repository}
Flutter engine revision: ${engine_revision}
Flutter engine source: https://github.com/flutter/engine/tree/${engine_revision}

The project source ZIP contains every tracked file from the exact Git commit
used to build the APK, including files that vendored export-ignore attributes
would omit from a plain git archive. It includes Lumina sources, vendored
OpenEUICC/lpac sources, build scripts, lockfiles, licenses, and notices.

The dependency-source ZIP separately contains complete hosted Pub package trees
from the lockfile, Maven source JARs that the configured repositories make
available, and cached resolved POM metadata. GRADLE_SOURCE_ARTIFACTS.tsv records
MISSING entries plus candidate source/POM URLs when a Maven component does not
publish a resolvable sources JAR.
Flutter framework and engine source are not duplicated in the bundle; their
exact revisions and source URLs are recorded above.

Lumina-owned code is GPL-3.0-only. Vendored and registry components retain the
licenses stated in their own files.
EOF

{
  echo "Project: Lumina eUICC"
  echo "Version: ${version}"
  echo "Commit: ${commit}"
  echo "Universal APK: ${universal_apk_name}"
  echo "arm64-v8a APK: ${arm64_apk_name}"
  echo "armeabi-v7a APK: ${armeabi_v7a_apk_name}"
  echo "x86_64 APK: ${x86_64_apk_name}"
  echo "Package: ${EXPECTED_PACKAGE_ID:-top.syngnat.lumina.euicc}"
  echo "Minimum Android API: 28 (Android 9)"
  echo "Target Android API: 35"
  echo "Compile Android API: 36"
  echo "ABIs: armeabi-v7a, arm64-v8a, x86_64"
  echo "Expected signing certificate SHA-256: ${EXPECTED_RELEASE_CERT_SHA256:-not-set}"
  echo
  echo "Flutter toolchain:"
  printf '%s\n' "${flutter_toolchain}"
  echo
  echo "Java toolchain:"
  printf '%s\n' "${java_toolchain}"
  echo
  echo "Gradle wrapper:"
  printf '%s\n' "${gradle_toolchain}"
  echo
  for release_apk_name in \
    "${universal_apk_name}" \
    "${arm64_apk_name}" \
    "${armeabi_v7a_apk_name}" \
    "${x86_64_apk_name}"; do
    echo "APK metadata (${release_apk_name}):"
    "${ANDROID_HOME}/build-tools/35.0.0/aapt" dump badging \
      "${output_dir}/${release_apk_name}" |
      grep -E "^(package:|sdkVersion:|targetSdkVersion:|native-code:)"
    echo
    echo "APK signer certificate (${release_apk_name}):"
    "${ANDROID_HOME}/build-tools/35.0.0/apksigner" verify --print-certs \
      "${output_dir}/${release_apk_name}"
    echo
  done
} > "${output_dir}/BUILD_INFO.txt"

flutter pub deps --style=compact | tee "${output_dir}/FLUTTER_DEPENDENCIES.txt"
(
  cd android
  ./gradlew :app:dependencies --configuration releaseRuntimeClasspath --no-daemon
) | tee "${output_dir}/GRADLE_RELEASE_DEPENDENCIES.txt"
bash .github/scripts/check-runtime-dependencies.sh \
  "${output_dir}/GRADLE_RELEASE_DEPENDENCIES.txt"

dependency_staging="${staging_directory}/dependency-sources"
python3 .github/scripts/collect-pub-sources.py \
  .dart_tool/package_config.json \
  pubspec.lock \
  "${dependency_staging}/pub"
(
  cd android
  ./gradlew \
    --init-script ../.github/scripts/collect-gradle-sources.init.gradle \
    :app:luminaCollectRuntimeDependencySources \
    "-PluminaDependencyOutput=${dependency_staging}/gradle" \
    --no-daemon
)

cp "${dependency_staging}/pub/PUB_SOURCE_MANIFEST.tsv" "${output_dir}/"
cp "${dependency_staging}/gradle/GRADLE_SOURCE_ARTIFACTS.tsv" "${output_dir}/"

assert_tree_has_no_signing_material "${dependency_staging}" "Dependency sources"
archive_scan="${staging_directory}/dependency-archive-scan"
mkdir -p "${archive_scan}"
archive_index=0
while IFS= read -r -d '' dependency_archive; do
  assert_archive_entry_names_are_safe "${dependency_archive}" "Dependency source archive"
  archive_index=$((archive_index + 1))
  extraction="${archive_scan}/${archive_index}"
  mkdir -p "${extraction}"
  unzip -q -o "${dependency_archive}" -d "${extraction}"
done < <(
  find "${dependency_staging}" -type f \
    \( -iname '*.jar' -o -iname '*.zip' -o -iname '*.aar' \) -print0
)
assert_tree_has_no_signing_material "${archive_scan}" "Expanded dependency source archives"

python3 .github/scripts/make-zip.py \
  "${output_dir}/${dependency_sources_name}" \
  "${staging_directory}" \
  dependency-sources

cat > "${output_dir}/DEPENDENCIES.txt" <<EOF
Exact dependency inventories and available sources for this release:

- FLUTTER_DEPENDENCIES.txt: resolved Flutter/Dart graph from pubspec.lock.
- GRADLE_RELEASE_DEPENDENCIES.txt: resolved Android release runtime graph.
- PUB_SOURCE_MANIFEST.tsv: every hosted Pub package source tree bundled, with
  locked version and pub archive SHA-256.
- GRADLE_SOURCE_ARTIFACTS.tsv: every resolved Maven component coordinate,
  whether its sources JAR and POM were bundled, and candidate Google
  Maven/Maven Central source/POM URLs when unavailable.
- ${dependency_sources_name}: hosted Pub package trees and available Maven
  source JARs. Missing Maven sources are explicitly marked in the TSV manifest.
- ${source_name}: Lumina and all tracked vendored sources, including the complete
  tracked third_party tree used by the APK.

The Flutter SDK/framework/engine sources are not embedded; SOURCE_INFO.txt and
FLUTTER_VERSION.json record their exact revisions and upstream source URLs.
EOF

for release_apk_name in \
  "${universal_apk_name}" \
  "${arm64_apk_name}" \
  "${armeabi_v7a_apk_name}" \
  "${x86_64_apk_name}"; do
  assert_archive_entry_names_are_safe \
    "${output_dir}/${release_apk_name}" \
    "APK ${release_apk_name}"
done
assert_archive_entry_names_are_safe "${output_dir}/${source_name}" "Project source archive"
assert_archive_entry_names_are_safe \
  "${output_dir}/${dependency_sources_name}" \
  "Dependency source archive"
assert_archive_entry_names_are_safe \
  "${output_dir}/${license_materials_name}" \
  "License materials archive"
assert_tree_has_no_signing_material "${output_dir}" "Release bundle"

(
  cd "${output_dir}"
  LC_ALL=C find . -maxdepth 1 -type f ! -name SHA256SUMS -printf '%P\0' |
    LC_ALL=C sort -z |
    xargs -0 -r sha256sum > SHA256SUMS
  sha256sum --check SHA256SUMS
)

echo "Release bundle created in ${output_dir}:"
find "${output_dir}" -maxdepth 1 -type f -printf '  %f\n' | LC_ALL=C sort

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  printf 'artifact_name=lumina-euicc-%s-signed-%s\n' \
    "${safe_version}" "${short_commit}" >> "${GITHUB_OUTPUT}"
  printf 'safe_version=%s\n' "${safe_version}" >> "${GITHUB_OUTPUT}"
  printf 'version_name=%s\n' "${version_name}" >> "${GITHUB_OUTPUT}"
fi
