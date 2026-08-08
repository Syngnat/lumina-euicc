# NOTICE

This repository vendors and links against code from:

## OpenEUICC / EasyEUICC
- Upstream: https://gitea.angry.im/PeterCxy/OpenEUICC
- License: GNU GPL v3 only
- Authors: Peter Cai and contributors

## lpac
- Upstream: https://github.com/estkme-group/lpac
- Used via OpenEUICC's lpac-jni wrapper
- The vendored `lpac-jni/LICENSE` is LGPL-2.1; nested lpac source directories also carry AGPL-3.0 and LGPL-2.1 license files. Preserve and review those files component by component.

## cJSON
- Upstream: https://github.com/DaveGamble/cJSON
- Used by lpac-jni native build
- License: MIT (see the vendored cJSON `LICENSE`)

## dlfcn-win32
- Included in the vendored lpac source tree
- License: MIT (see its vendored `LICENSE`)

Any binary distribution must satisfy every applicable license, including OpenEUICC's
GPL-3.0-only corresponding-source obligations and the separate LGPL, AGPL, and MIT
terms recorded in the vendored license files. This notice is attribution, not a
complete software bill of materials or a license grant for Lumina-owned code.
