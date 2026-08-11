# Lumina eUICC license scope

Copyright (C) 2026 Syngnat

## Lumina-owned work

Unless a file says otherwise, code, documentation, build configuration, and
other material created specifically for Lumina eUICC and owned by Syngnat are
licensed under the **GNU General Public License, version 3 only**
(`GPL-3.0-only`). The complete license text is in [`LICENSE`](LICENSE).

This grant uses version 3 only, without the "or any later version" option.
Lumina eUICC is provided without warranty, to the extent permitted by law.

## Third-party work

Third-party files are not relicensed by the preceding grant. They remain under
the notices and licenses supplied by their respective copyright holders. In
particular:

- `third_party/OpenEUICC/`, except for components called out below, retains
  OpenEUICC's `GPL-3.0-only` terms and copyright notices.
- `third_party/OpenEUICC/libs/lpac-jni/` retains its upstream
  `LGPL-2.1-only` terms.
- The embedded lpac tree uses file- and directory-specific terms recorded in
  its `REUSE.toml`, file headers, and `LICENSES/` directory. The Android build
  currently compiles the `euicc` component under its `LGPL-2.1-only` option,
  MIT-licensed `cjson-ext` files, and CC0-1.0 SHA-256 files. Other lpac source
  remains in the source archive under its own terms even when it is not part of
  the APK.
- cJSON and dlfcn-win32 retain their MIT licenses.
- `assets/data/profile_size_estimates.json` is a normalized derivative of the
  pinned NekokoLPA profile-size sample data and retains the upstream MIT notice
  recorded in `THIRD_PARTY_NOTICES.md`.
- Registry dependencies from Flutter/Dart and Android/Gradle retain their own
  licenses. Their exact resolved versions are determined by `pubspec.lock`,
  the Gradle build files, and the dependency inventories produced by the same
  CI run as a release.

See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) and every nested license
file for paths, upstream locations, and copyright information.

## Changes to vendored files

Changes made by Lumina contributors inside a third-party component are offered
under the license that governs that component or file. They are not converted
to the root project's license when the upstream license requires or permits a
different treatment.

## Combined distribution

The Lumina application combines Lumina-owned GPL-3.0-only code with OpenEUICC
GPL-3.0-only code and compatible separately licensed components. Distribution
of the combined APK is made under GPL-3.0-only for the combined work while all
applicable notices, source-access rights, and additional permissions of the
individual components are preserved.

Each published APK is tied to an immutable version tag. GitHub's automatic
source archive for that tag contains the exact tracked Lumina sources, build
scripts, lockfiles, legal notices, and the complete `third_party/OpenEUICC`
snapshot used by the build. The Release notes link that tag and these legal
materials directly.

The same trusted CI run also creates and verifies a full audit bundle containing
the exact project source, hosted Pub sources, available Maven sources and POMs,
dependency manifests, `SOURCE_INFO.txt`, dependency inventories, license
materials, and `SHA256SUMS`. The complete bundle is retained as a GitHub Actions
audit artifact for 90 days. Its non-APK files are also combined into one
versioned source-materials ZIP on the dedicated `release-materials` branch, and
the Release notes link it by exact materials commit and state its SHA-256. This
keeps the corresponding-source and notice set persistently public without
expanding it into many end-user Release assets. This repository does not record
a separate upstream OpenEUICC commit identifier, so none should be inferred
from dates or version strings.
