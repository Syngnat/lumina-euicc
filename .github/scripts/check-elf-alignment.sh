#!/usr/bin/env bash
set -euo pipefail

apk_path="${1:?usage: check-elf-alignment.sh <apk>}"
ndk_root="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"

if [[ -z "${ndk_root}" && -n "${ANDROID_SDK_ROOT:-}" ]]; then
  ndk_root="${ANDROID_SDK_ROOT}/ndk/28.2.13676358"
fi

if [[ -z "${ndk_root}" ]]; then
  echo "ANDROID_NDK_HOME, ANDROID_NDK_ROOT, or ANDROID_SDK_ROOT is required" >&2
  exit 2
fi

case "$(uname -s)" in
  Linux*) host_tag="linux-x86_64"; tool_suffix="" ;;
  Darwin*) host_tag="darwin-x86_64"; tool_suffix="" ;;
  MINGW*|MSYS*|CYGWIN*) host_tag="windows-x86_64"; tool_suffix=".exe" ;;
  *)
    echo "Unsupported host for ELF alignment check: $(uname -s)" >&2
    exit 2
    ;;
esac

objdump="${ndk_root}/toolchains/llvm/prebuilt/${host_tag}/bin/llvm-objdump${tool_suffix}"
if [[ ! -x "${objdump}" ]]; then
  echo "llvm-objdump not found: ${objdump}" >&2
  exit 2
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

unzip -qq "${apk_path}" 'lib/arm64-v8a/*.so' 'lib/x86_64/*.so' -d "${work_dir}"
mapfile -d '' libraries < <(
  find "${work_dir}/lib" -type f -name '*.so' -print0 | sort -z
)

if (( ${#libraries[@]} == 0 )); then
  echo "No 64-bit native libraries found in ${apk_path}" >&2
  exit 1
fi

failed=0
for library in "${libraries[@]}"; do
  relative_path="${library#${work_dir}/}"
  if "${objdump}" -p "${library}" | awk '
    $1 == "LOAD" {
      saw_load = 1
      saw_alignment = 0
      for (i = 1; i < NF; i++) {
        if ($i == "align") {
          saw_alignment = 1
          split($(i + 1), parts, "\\*\\*")
          if (length(parts) != 2 || parts[2] + 0 < 14) {
            bad = 1
          }
        }
      }
      if (!saw_alignment) {
        bad = 1
      }
    }
    END { exit !(saw_load && !bad) }
  '; then
    echo "ALIGNED   ${relative_path}"
  else
    echo "UNALIGNED ${relative_path}" >&2
    failed=1
  fi
done

exit "${failed}"
