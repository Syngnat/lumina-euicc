# Vendored third-party source

`OpenEUICC/` is a tracked source snapshot rather than a Git submodule so a
normal Windows clone contains every native source file needed by Lumina's
build.

The exact snapshot used by an APK is the `third_party/OpenEUICC` tree in the
full Lumina Git commit recorded by that release's `SOURCE_INFO.txt`. A separate
upstream OpenEUICC commit identifier was not retained when this snapshot was
imported; do not infer or invent one.

OpenEUICC is primarily `GPL-3.0-only`. Its `libs/lpac-jni` wrapper and nested
lpac/cJSON source have component-specific LGPL, AGPL, MIT, and CC0 terms. Keep
all nested `LICENSE`, `LICENSES/`, `REUSE.toml`, copyright headers, and README
notices intact. The root [`LICENSES_SCOPE.md`](../LICENSES_SCOPE.md) and
[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) describe the boundaries
and the subset compiled by the current Android build.
