# NOTICE

Lumina eUICC

Copyright (C) 2026 Syngnat

Lumina-owned portions are free software licensed under GNU GPL version 3 only.
See `LICENSE` for the complete license text and `LICENSES_SCOPE.md` for the
boundary between Lumina-owned and third-party material.

This project incorporates OpenEUICC code, the OpenEUICC lpac-jni wrapper, lpac,
cJSON, and other Flutter/Android dependencies. Copyright remains with their
respective authors. Their upstream locations, component-specific terms, build
inclusion status, and license-file paths are documented in
`THIRD_PARTY_NOTICES.md` and in the nested files shipped with the source.

In particular:

- OpenEUICC is Copyright 2022-2026 OpenEUICC contributors and is licensed
  `GPL-3.0-only`.
- The OpenEUICC lpac-jni wrapper is licensed `LGPL-2.1-only`.
- The Android build uses lpac's LGPL-2.1 `euicc` component, MIT `cjson-ext`
  files, CC0 SHA-256 files, and MIT-licensed cJSON.
- Other lpac and OpenEUICC material in the source tree retains the license
  recorded in its own headers, `REUSE.toml`, `LICENSES/`, or README.

For a distributed APK, obtain the project/dependency source archives and
manifests, `SOURCE_INFO.txt`, dependency inventories, license materials, and
`SHA256SUMS` from the same CI artifact. Do not separate the APK from its
corresponding-source and notice materials when redistributing it.
