package top.syngnat.lumina.euicc

import im.angry.openeuicc.OpenEuiccApplication
import im.angry.openeuicc.di.DefaultAppContainer

/**
 * Application entry that satisfies OpenEUICC's AppContainer / preference wiring.
 * Flutter still owns the Activity; LPA stack is hosted here.
 */
class LuminaApplication : OpenEuiccApplication() {
    override val appContainer by lazy { DefaultAppContainer(this) }
}
