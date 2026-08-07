# Wire real LPA (OpenEUICC / lpac) into EuiccBridgePlugin
#
# Goal: replace mock store with EasyEUICC-grade operations while keeping Flutter UI.
#
# Suggested integration (GPL-3 compliance required if you copy OpenEUICC code):
#
# 1. Add OpenEUICC modules as composite build or AAR:
#    - :app-common
#    - :libs:lpac-jni
# 2. In android/app/build.gradle dependencies:
#      implementation project(":app-common")
#      implementation project(":lpac-jni")
# 3. In EuiccBridgePlugin:
#      - bind EuiccChannelManagerService
#      - map:
#          listChannels     -> euiccChannelManager.enumerated channels
#          listProfiles     -> channel.lpa.profiles
#          switchProfile    -> launchProfileSwitchTask
#          deleteProfile    -> launchProfileDeleteTask
#          renameProfile    -> launchProfileRenameTask
#          downloadProfile  -> launchProfileDownloadTask + EventChannel progress
# 4. Keep package id top.syngnat.lumina.euicc (do not ship as im.angry.easyeuicc)
# 5. Test with ARA-M compatible removable eUICC or USB CCID reader
#
# Until then, Mock mode is intentional for UI/UX development.
