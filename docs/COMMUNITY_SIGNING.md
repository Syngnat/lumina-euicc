# Community multi-signing policy

Starting with `0.1.1`, Lumina release APKs use one stable set of **four current
signers**. This is a build-time signing arrangement: no keystore, private key,
or password is stored in this repository or included in release/source
artifacts.

## Included signer set

| Signer | ARA-M SHA-1 fingerprint | Provenance |
|---|---|---|
| Lumina dedicated release key | `10:0C:A7:FD:2C:E4:B7:12:BA:3C:88:4C:AE:20:FD:33:25:ED:85:E0` | Owned and backed up by Syngnat |
| Sakura community key | `65:D0:57:18:54:AF:EC:51:9A:90:F9:2D:7C:5D:8C:F8:14:8D:A3:73` | Publicly reproducible from the pinned official NekokoLPA source |
| ShiinaSekiu Community Key | `C4:73:50:C7:BA:68:2B:34:A3:E5:84:A0:D5:84:63:EA:42:B1:AD:73` | Publicly reproducible from the pinned official NekokoLPA source |
| 9eSIM community key | `D1:C0:F4:8B:37:0E:74:D4:EA:47:70:ED:4C:3C:D7:0A:31:98:D3:1F` | Publicly reproducible from the pinned official NekokoLPA source |

The APK uses APK Signature Scheme **v2**. Schemes v1 and v3 are deliberately
disabled: Lumina's minimum Android version supports v2, and this is a
multiple-current-signer APK rather than a single-signer key-rotation lineage.

## Migration and update compatibility

Android treats the current signer set as part of the installed package
identity. Any installed Lumina `0.1.0` build carrying only the original Lumina
signer cannot be updated in place to the four-signer build. Uninstall that
single-signer app once, then install the new Release APK. Uninstalling the app
does not delete profiles stored on the removable eUICC, but it does clear local
app settings.

All later releases must retain exactly the same four-current-signer set.
Adding or removing a signer creates another incompatible Android update chain.
Do not replace this with sequential signing commands: all four signers must be
applied in one `apksigner` invocation.

The three community keys are public, but they are not sufficient to impersonate
an update to this release chain. Android requires the complete current-signer
set for an in-place package update, and the fourth Lumina signer remains private
and controlled by Syngnat.

## ARA-M meaning

For an ARA-M access rule that identifies only a signing certificate and has no
package-name binding, a match against any one of the four current signer
certificates can authorize the APK. If the rule also binds a package name, that
package must be `top.syngnat.lumina.euicc`; a rule bound to another package can
still deny access even when its certificate fingerprint matches.

Lumina includes only the private project identity and community identities that
can be reproduced from pinned public source. A certificate fingerprint by
itself is not usable for APK signing; identities whose key material or unlock
process is not publicly reproducible are intentionally excluded.

This describes Android and card access-control identity; it does not guarantee
success on a physical card. The limited field evidence below confirms one exact
combination only. OMAPI behavior and the actual ARA-M rules on every other
removable eUICC still require device validation.

## Card compatibility implications

One seller-described 9eSIM card/device combination has completed read-only
channel and profile-list validation with the `0.1.1` four-signer APK. Its exact
card model, phone model, and Android version were not recorded. Another card
bought from the same retailer was rejected by ARA-M with the same Lumina
version. This mixed result confirms that a retailer or family label is not a
substitute for the exact card's effective rules. Based on this evidence and the
certificate hashes in the pinned
[NekokoLPA/Vendors database](https://github.com/NekokoLPA/Vendors/tree/9b73f52b5cf52d41399d6293f7b4fce6b74ce4e2/cards):

- [9eSIM v3, V2S, and v0](https://github.com/NekokoLPA/Vendors/blob/9b73f52b5cf52d41399d6293f7b4fce6b74ce4e2/cards/9esim.yaml),
  [eSIM.gg Card](https://github.com/NekokoLPA/Vendors/blob/9b73f52b5cf52d41399d6293f7b4fce6b74ce4e2/cards/esimgg.yaml),
  and [蚊子玩卡 S3](https://github.com/NekokoLPA/Vendors/blob/9b73f52b5cf52d41399d6293f7b4fce6b74ce4e2/cards/%E8%9A%8A%E5%AD%90%E7%8E%A9%E5%8D%A1.yaml)
  remain signer-fingerprint-match candidates because their entries list the
  included 9eSIM signer; the model-unknown successful observation does not
  certify any one of these families or batches;
- [ESTKme Light, Plus, and Max](https://github.com/NekokoLPA/Vendors/blob/9b73f52b5cf52d41399d6293f7b4fce6b74ce4e2/cards/estkme.yaml)
  do not list a current Lumina signer by default, but their signer list is
  marked changeable; they are candidates only after card-side configuration;
- a generic or unbranded card is unknown. EID prefix, chip manufacturer, STK
  menus, and "GSMA certified" wording do not disclose its effective ARA-M
  certificate and package policy.

These database entries record expected certificate hashes, not proof that
every shipped batch has identical personalization or no package-name binding.
The same-retailer pass/fail observations reinforce that limitation. Download,
enable/disable, rename, delete, and other mutations were not tested on the
successful card. See [the full card matrix](SUPPORTED_CARDS.md) before
describing any model as supported.

USB CCID is a separate Android USB-host transport and does not use the
phone-slot ARA-M rule. That does not make it currently verified: Lumina still
lacks a completed reader sign-off and the Flutter activity does not yet expose
the complete runtime permission and hotplug refresh flow.

## Upstream provenance and license

The community-signing design and the three publicly reproducible community
identities were reviewed at official NekokoLPA commit
[`517f88f9391099c8744a2f04df30c8d4a9cdd3d9`](https://github.com/iebb/NekokoLPA/commit/517f88f9391099c8744a2f04df30c8d4a9cdd3d9):

- [five-signer upstream script](https://github.com/iebb/NekokoLPA/blob/517f88f9391099c8744a2f04df30c8d4a9cdd3d9/variants/multisign/signing.sh#L8-L14);
- [upstream CI secret boundary](https://github.com/iebb/NekokoLPA/blob/517f88f9391099c8744a2f04df30c8d4a9cdd3d9/.github/workflows/android.yml#L35-L43);
- [community-key attribution](https://github.com/iebb/NekokoLPA/blob/517f88f9391099c8744a2f04df30c8d4a9cdd3d9/README.md#L24-L27);
- [MIT license and copyright notice](https://github.com/iebb/NekokoLPA/blob/517f88f9391099c8744a2f04df30c8d4a9cdd3d9/LICENSE#L1-L12).

The published comparison artifact is the official
[NekokoLPA v1.12.370 multisign release](https://github.com/iebb/NekokoLPA/releases/tag/v1.12.370).
The relevant upstream signing script is identical at the reviewed source commit
and the published release tag.

NekokoLPA's root MIT license grants broad use, modification, and distribution
rights subject to preservation of its copyright and permission notice. Lumina
preserves that attribution in `THIRD_PARTY_NOTICES.md`. Inclusion of a public
community signing identity does not imply endorsement by, or affiliation with,
NekokoLPA, Sakura, ShiinaSekiu, or 9eSIM.
