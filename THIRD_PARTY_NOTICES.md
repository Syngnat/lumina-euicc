# Third-party notices

Lumina eUICC incorporates or is built with the software listed below. This
human-readable notice complements, and does not replace, the license text and
copyright notices stored with each component.

Release artifacts also contain the dependency inventories resolved during that
specific CI build. Those inventories, `pubspec.lock`, and the Gradle build files
are the source of truth for exact registry dependency versions.

## Vendored source

### OpenEUICC code

- Upstream: <https://gitea.angry.im/PeterCxy/OpenEUICC>
- Copyright: 2022-2026 OpenEUICC contributors
- License: `GPL-3.0-only`
- License text: `third_party/OpenEUICC/LICENSE`

Lumina uses the vendored OpenEUICC `app-common` and `lpac-jni` integration
layers. The tracked `third_party/OpenEUICC` directory in the Lumina commit
identified by `SOURCE_INFO.txt` is the exact source used to build the matching
APK. No separate upstream OpenEUICC revision is recorded in this repository.

### OpenEUICC lpac-jni wrapper

- Upstream location: `libs/lpac-jni` in OpenEUICC
- Copyright: 2022-2026 OpenEUICC contributors
- License: `LGPL-2.1-only`
- License text: `third_party/OpenEUICC/libs/lpac-jni/LICENSE`

### lpac

- Upstream: <https://github.com/estkme-group/lpac>
- Copyright: 2023-2025 ESTKME TECHNOLOGY LIMITED, Hong Kong
- Component licenses: file- and directory-specific; see
  `third_party/OpenEUICC/libs/lpac-jni/src/main/jni/lpac/REUSE.toml`, file
  headers, and the adjacent `LICENSES/` directory

The current Android `lpac-jni.mk` build includes:

- `lpac/euicc/**`: `LGPL-2.1-only` (the open-source option declared by lpac),
  with `sha256.c` and `sha256.h` marked `CC0-1.0`;
- `lpac/cjson-ext/cjson-ext/**`: MIT;
- the OpenEUICC `lpac-jni/**` wrapper described above.

The vendored lpac `src/**` and `driver/**` directories are marked
`AGPL-3.0-only` in `REUSE.toml`, but the current Android NDK makefile does not
compile those directories into Lumina's APK. They remain in the corresponding
source archive with their original license files.

### cJSON

- Upstream: <https://github.com/DaveGamble/cJSON>
- Copyright: 2009-2017 Dave Gamble and cJSON contributors
- License: MIT
- License text:
  `third_party/OpenEUICC/libs/lpac-jni/src/main/jni/cjson/cjson/LICENSE`
- Vendored version recorded by its build metadata: 1.7.19

The current Android native build compiles cJSON into `liblpac-jni.so`.

### dlfcn-win32

- Copyright: 2007 Ramiro Polla, with contributors listed by lpac
- License: MIT
- License text:
  `third_party/OpenEUICC/libs/lpac-jni/src/main/jni/lpac/dlfcn-win32/LICENSE`

This source is present in the vendored tree but is not part of the current
Android NDK build.

### OpenEUICC artwork

- Credit: Aikoyori
- License wording in the vendored OpenEUICC README: `CC NC-SA 4.0`

The artwork remains in the vendored source tree and is not used as Lumina's
application identity.

## Community signing provenance

### NekokoLPA community signing identities

- Official upstream: <https://github.com/iebb/NekokoLPA>
- Reviewed source commit:
  [`517f88f9391099c8744a2f04df30c8d4a9cdd3d9`](https://github.com/iebb/NekokoLPA/commit/517f88f9391099c8744a2f04df30c8d4a9cdd3d9)
- Published comparison release:
  [v1.12.370](https://github.com/iebb/NekokoLPA/releases/tag/v1.12.370)
- Copyright: 2024 Kosmoneko OÜ; 2022 Infineon Technologies AG
- License: MIT
- License and notice:
  <https://github.com/iebb/NekokoLPA/blob/517f88f9391099c8744a2f04df30c8d4a9cdd3d9/LICENSE#L1-L12>

The upstream notice is retained here:

```text
Copyright (c) 2024 Kosmoneko OÜ
Copyright (c) 2022 Infineon Technologies AG

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOURCE CODE AND ITS RELATED DOCUMENTATION IS PROVIDED "AS IS". INFINEON
TECHNOLOGIES MAKES NO OTHER WARRANTY OF ANY KIND,WHETHER EXPRESS,IMPLIED OR,
STATUTORY AND DISCLAIMS ANY AND ALL IMPLIED WARRANTIES OF MERCHANTABILITY,
SATISFACTORY QUALITY, NON INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE.

THE SOURCE CODE AND DOCUMENTATION MAY INCLUDE ERRORS. INFINEON TECHNOLOGIES
RESERVES THE RIGHT TO INCORPORATE MODIFICATIONS TO THE SOURCE CODE IN LATER
REVISIONS OF IT, AND TO MAKE IMPROVEMENTS OR CHANGES IN THE DOCUMENTATION OR
THE PRODUCTS OR TECHNOLOGIES DESCRIBED THEREIN AT ANY TIME.

INFINEON TECHNOLOGIES SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT OR
CONSEQUENTIAL DAMAGE OR LIABILITY ARISING FROM YOUR USE OF THE SOURCE CODE OR
ANY DOCUMENTATION, INCLUDING BUT NOT LIMITED TO, LOST REVENUES, DATA OR
PROFITS, DAMAGES OF ANY SPECIAL, INCIDENTAL OR CONSEQUENTIAL NATURE, PUNITIVE
DAMAGES, LOSS OF PROPERTY OR LOSS OF PROFITS ARISING OUT OF OR IN CONNECTION
WITH THIS AGREEMENT, OR BEING UNUSABLE, EVEN IF ADVISED OF THE POSSIBILITY OR
PROBABILITY OF SUCH DAMAGES AND WHETHER A CLAIM FOR SUCH DAMAGE IS BASED UPON
WARRANTY, CONTRACT, TORT, NEGLIGENCE OR OTHERWISE.
```

Lumina's four-current-signer release set includes the Lumina-owned certificate
plus the Sakura, ShiinaSekiu Community, and 9eSIM community signing identities
that are publicly reproducible from the pinned official NekokoLPA source. The
upstream signing design is recorded in the pinned
[`multisign/signing.sh`](https://github.com/iebb/NekokoLPA/blob/517f88f9391099c8744a2f04df30c8d4a9cdd3d9/variants/multisign/signing.sh#L8-L14).
NekokoLPA's `nekokobeef` and `wenzi` identities are not included because their
unlock credentials exist only as upstream CI secrets. Lumina includes only the
four identities whose release policy and provenance are documented above.

The upstream root MIT license grants use, modification, and distribution rights
subject to preserving its copyright and permission notice. This notice preserves
that attribution. Use of these public community identities does not imply
endorsement by, or affiliation with, NekokoLPA, Sakura, ShiinaSekiu, or 9eSIM.

Only public certificates and signatures are present in an APK. Keystores,
private keys, and passwords are build-time material and are excluded from the
Lumina repository, source archives, CI audit bundle, persistent
source-materials ZIP, GitHub Release assets, logs, and the publishing job. See
`docs/COMMUNITY_SIGNING.md` for fingerprints, ARA-M behavior, and the stable
update-set policy.

## Flutter and Dart packages

The release uses the Flutter SDK and the direct Dart packages declared in
`pubspec.yaml`, including Cupertino Icons, Riverpod, GoRouter, Google Fonts,
intl, and collection. Their transitive packages and exact locked versions are
recorded in `pubspec.lock` and in the Flutter dependency inventory shipped with
the matching CI audit bundle and persistent source-materials ZIP.

These packages retain their upstream licenses. The direct packages in the
current lockfile use MIT or BSD-style licenses; their full license texts are
available in their package sources fetched by `flutter pub get` and through
their package pages on <https://pub.dev/>. Flutter and Dart SDK materials retain
their own BSD-style and component-specific notices.

Google Fonts may download font files at runtime according to application
configuration and network availability. Font files retain the licenses chosen
by their respective font authors; they are not relicensed as Lumina code.

## Android, Kotlin, and Java dependencies

The Android build directly declares AndroidX libraries, Material Components for
Android, ZXing Android Embedded, and Kotlin coroutines. Gradle also resolves
their transitive dependencies. Exact coordinates and versions are recorded by
the Gradle dependency inventory shipped with the matching CI audit bundle and
persistent source-materials ZIP.

Many of these libraries use Apache License 2.0, but not every artifact resolved
from Google's repository is Apache-licensed. Their source, copyright notices,
and license texts are available from the corresponding Google Maven or Maven
Central coordinates recorded in that inventory. Android SDK/NDK, Flutter
engine, Kotlin tooling, Gradle, and build plugins are build/runtime platform
components and retain their own notices.

### ZXing Android Embedded and ZXing Core

- Upstream: <https://github.com/journeyapps/zxing-android-embedded>
- Direct artifact: `com.journeyapps:zxing-android-embedded:4.3.0`
- Decoder artifact: `com.google.zxing:core:3.4.1`
- License: Apache License 2.0

Lumina's native QR scan path uses ZXing. CI rejects Google ML Kit/Barhopper
runtime coordinates so the signed GPL release does not silently regain the
previous proprietary scanner dependency.

## Source and notices for a released APK

Do not mix files from different workflow runs. The matching CI audit bundle
contains:

- the signed APK;
- `lumina-euicc-source-<full-commit-sha>.zip`, containing the tracked Lumina
  source and the vendored source used by that APK;
- `lumina-euicc-dependency-sources-<full-commit-sha>.zip`, containing every
  hosted Pub package tree plus Maven source JARs and cached POMs available from
  the configured repositories;
- `SOURCE_INFO.txt`, identifying repository, full commit, commit URL, package,
  version, build toolchain, and exact Flutter framework/engine source revisions;
- `SHA256SUMS`;
- Flutter and Gradle dependency inventories plus Pub/Maven source manifests;
- the root and nested license/notice materials.

The Maven source manifest explicitly identifies components whose repositories
do not publish a resolvable source JAR and records candidate source/POM URLs.
Flutter framework and engine sources are referenced by exact revision and URL
rather than duplicated in the bundle. The complete build bundle is retained as
one Actions audit artifact for 90 days. The same run also combines every non-APK
file above into one versioned source-materials ZIP on the dedicated
`release-materials` branch. The Release notes identify that persistent ZIP by
an exact materials commit URL and SHA-256; only the four APK variants are
custom-uploaded as GitHub Release assets.

The source archives intentionally exclude signing keys, passwords, local
machine configuration, build caches, and generated build outputs. None of those
secrets are required to build a functionally equivalent APK with a different
signing identity. Official update compatibility and phone-slot ARA-M
authorization do depend on the owner's protected release key.
