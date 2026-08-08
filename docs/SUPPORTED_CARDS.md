# Removable eUICC card compatibility

Lumina has one **limited, read-only field validation on an exact card/device
combination**, but no physical-card model or production batch has completed
model-wide sign-off. The table below combines that field evidence with the
card-side ARA-M certificate hashes published in the pinned
[NekokoLPA/Vendors database](https://github.com/NekokoLPA/Vendors/tree/9b73f52b5cf52d41399d6293f7b4fce6b74ce4e2/cards)
and Lumina's current four-signer APK. It is not a certification, guarantee, or
substitute for testing the exact card batch on the target phone.

## Compatibility matrix

| Card / family | Published ARA-M evidence | Lumina status |
|---|---|---|
| 9eSIM v3, V2S, v0 | The pinned [9eSIM entry](https://github.com/NekokoLPA/Vendors/blob/9b73f52b5cf52d41399d6293f7b4fce6b74ce4e2/cards/9esim.yaml) lists Lumina's included 9eSIM signer (`D1:C0:…:D3:1F`) | **Mixed field evidence**: one exact seller-described 9eSIM card/device combination listed profiles, while another card from the same retailer was denied by ARA-M. Exact models were not established, so v3, V2S, and v0 remain signer-fingerprint-match candidates rather than certified families |
| eSIM.gg Card | The pinned [eSIM.gg entry](https://github.com/NekokoLPA/Vendors/blob/9b73f52b5cf52d41399d6293f7b4fce6b74ce4e2/cards/esimgg.yaml) lists the same included 9eSIM signer | **Signer-fingerprint-match candidate**; not yet tested by Lumina |
| 蚊子玩卡 S3 | The pinned [S3 entry](https://github.com/NekokoLPA/Vendors/blob/9b73f52b5cf52d41399d6293f7b4fce6b74ce4e2/cards/%E8%9A%8A%E5%AD%90%E7%8E%A9%E5%8D%A1.yaml) lists the same included 9eSIM signer | **Signer-fingerprint-match candidate**; not yet tested by Lumina |
| ESTKme Light, Plus, Max | The pinned [ESTKme entry](https://github.com/NekokoLPA/Vendors/blob/9b73f52b5cf52d41399d6293f7b4fce6b74ce4e2/cards/estkme.yaml) does not list any current Lumina signer by default, but marks the ARA-M signer list as changeable | **Not compatible by default**; candidate only after the card owner/vendor adds a current Lumina signer and any package binding permits `top.syngnat.lumina.euicc` |
| Generic, unbranded, or seller-described "white card" | Model name, EID prefix, chip manufacturer, STK menu, and "GSMA certified" wording do not disclose the effective ARA-M rule | **Unknown** until the exact card's ARA-M policy is confirmed or tested |

## Recorded field evidence (2026-08-08)

Both observations below used the Lumina `0.1.1` four-signer Release APK. No EID,
ICCID, or profile credentials are recorded here.

| Observation | Result | What it establishes |
|---|---|---|
| Seller-described 9eSIM card; exact model, phone model, and Android version not recorded | Compatibility diagnostics showed the current app identity opening ISD-R on OMAPI slot 1, eUICC port 1/0 discovered, and a valid LPA channel. The home screen then listed multiple real profiles | The exact card/device combination supports read-only channel discovery and profile listing with Lumina `0.1.1` |
| Another card bought from the same retailer; Lumina `0.1.2`, OPPO PME110 / OP61C1L1, Android 16 / API 36 | OMAPI enumerated SIM 0 and SIM 1. The SIM 0 probe reached the ISD-R access check, then access control rejected the current Lumina identity. SIM 1 separately returned a sanitized `IOException`; no LPA port opened | The phone-side OMAPI/ISD-R path was present, so this is not evidence of a locked phone channel. A shared retailer still does not establish identical card personalization or effective ARA-M rules |

The second result is consistent with per-card or per-batch personalization
differences. A same-phone card swap and the effective ARA-M data would be needed
to isolate the exact cause from device/slot behavior. Neither observation
validates profile download, enable/disable, rename, delete, memory reset, or any
other write operation.

"Signer-fingerprint-match candidate" means the published metadata contains at least
one SHA-1 certificate fingerprint from Lumina's signer set. The database does
not prove that every production batch has the same personalization or that no
package-name binding is present. If a rule binds an Android package, it must
bind `top.syngnat.lumina.euicc`; matching the certificate alone is then not
enough.

An EID prefix identifies a manufacturer or product family, not the complete
card access policy. Two cards with the same EID prefix or GSMA production
certificate can carry different ARA-M rules. A working STK profile list also
does not prove that an Android application is authorized to open the ISD-R
channel.

## USB CCID alternative

A standard USB CCID reader uses Android USB host access and does **not** depend
on the phone-slot ARA-M rule. The card must still be a removable eUICC, the
phone must support USB OTG/host mode, and the reader must expose a compatible
CCID interface.

The current Lumina implementation contains the CCID transport and channel scan,
but it has no completed reader sign-off. Its Flutter activity also does not yet
provide the full in-app USB permission and attach/detach refresh flow, so a
reader may remain unavailable unless Android has already granted access and the
device is detected by the current attachment path. USB support must therefore
be treated as **implemented but unvalidated**, not as guaranteed compatibility.

## Before buying or testing a card

Ask for all of the following for the exact production batch:

1. the card's effective ARA-M SHA-1 allowlist;
2. whether the rule has an Android package-name binding;
3. confirmation that the rule contains one of Lumina's
   [four current signer fingerprints](COMMUNITY_SIGNING.md);
4. the return/upgrade path if the shipped personalization differs from the
   advertised rule.

Read-only compatibility is verified only for an exact named card/phone
combination after a real Lumina Release APK completes channel discovery and
profile listing. The successful observation above lacks exact model/device
identification, so it is field evidence rather than a reusable certification.
Profile mutations require a separate, explicitly recorded test.
