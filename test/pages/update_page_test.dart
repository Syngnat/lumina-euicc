import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/l10n/l10n.dart';
import 'package:lumina_euicc/pages/settings_page.dart';
import 'package:lumina_euicc/pages/update_page.dart';
import 'package:lumina_euicc/services/app_update_service.dart';
import 'package:lumina_euicc/services/providers.dart';

void main() {
  testWidgets('settings opens the localized software update page',
      (tester) async {
    final service = _FakeUpdateService(_upToDateCheck());
    await _pump(tester, service, const SettingsPage());

    expect(find.text('软件更新'), findsOneWidget);
    await tester.tap(find.text('软件更新'));
    await tester.pumpAndSettle();

    expect(find.byType(UpdatePage), findsOneWidget);
    expect(find.text('已是最新版本'), findsOneWidget);
    expect(find.text('当前版本：0.1.3'), findsOneWidget);
  });

  testWidgets('downloads the matching asset and opens the system installer',
      (tester) async {
    final service = _FakeUpdateService(_availableCheck());
    await _pump(tester, service, const UpdatePage());

    expect(find.text('发现新版本'), findsOneWidget);
    expect(find.text('arm64-v8a · 21.9 MB'), findsOneWidget);
    await tester.tap(find.byKey(const Key('downloadAndInstallUpdate')));
    await tester.pumpAndSettle();

    expect(service.downloadCalls, 1);
    expect(service.installCalls, 1);
    expect(find.textContaining('Android 系统安装器'), findsOneWidget);
  });

  testWidgets('guides unknown-sources permission and retries the same APK',
      (tester) async {
    final service = _FakeUpdateService(_availableCheck())
      ..installStatus = InstallUpdateStatus.permissionRequired;
    await _pump(tester, service, const UpdatePage());

    await tester.tap(find.byKey(const Key('downloadAndInstallUpdate')));
    await tester.pumpAndSettle();
    expect(find.text('允许安装应用'), findsOneWidget);

    await tester.tap(find.byKey(const Key('openInstallSettings')));
    await tester.pump();
    expect(service.openSettingsCalls, 1);

    service.installStatus = InstallUpdateStatus.launched;
    final retry = find.byKey(const Key('retryInstallUpdate'));
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(service.installCalls, 2);
    expect(find.textContaining('Android 系统安装器'), findsOneWidget);
  });

  testWidgets('shows a retryable localized check failure', (tester) async {
    final service = _FakeUpdateService(_upToDateCheck())..failCheck = true;
    await _pump(tester, service, const UpdatePage());

    expect(find.textContaining('无法检查更新'), findsOneWidget);
    service.failCheck = false;
    await tester.tap(find.text('重新检查'));
    await tester.pumpAndSettle();

    expect(service.checkCalls, 2);
    expect(find.text('已是最新版本'), findsOneWidget);
  });
}

class _FakeUpdateService implements AppUpdateService {
  _FakeUpdateService(this.check);

  final AppUpdateCheck check;
  bool failCheck = false;
  int checkCalls = 0;
  int downloadCalls = 0;
  int installCalls = 0;
  int openSettingsCalls = 0;
  InstallUpdateStatus installStatus = InstallUpdateStatus.launched;

  @override
  Future<AppUpdateCheck> checkForUpdate() async {
    checkCalls++;
    if (failCheck) throw const AppUpdateException('test_check_failure');
    return check;
  }

  @override
  Future<String> downloadUpdate(
    AppUpdateCheck check, {
    required UpdateProgressCallback onProgress,
  }) async {
    downloadCalls++;
    onProgress(11500000, 23000000);
    onProgress(23000000, 23000000);
    return '/app/cache/updates/update.apk';
  }

  @override
  Future<InstallUpdateStatus> installDownloadedUpdate(
    AppUpdateCheck check,
    String path,
  ) async {
    installCalls++;
    return installStatus;
  }

  @override
  Future<void> openInstallPermissionSettings() async {
    openSettingsCalls++;
  }
}

AppUpdateCheck _upToDateCheck() => AppUpdateCheck(
      runtime: const AppRuntimeInfo(
        versionName: '0.1.3',
        versionCode: 2004,
        supportedAbis: ['arm64-v8a'],
      ),
      release: _release(),
      asset: null,
    );

AppUpdateCheck _availableCheck() {
  final release = _release();
  return AppUpdateCheck(
    runtime: const AppRuntimeInfo(
      versionName: '0.1.2',
      versionCode: 2003,
      supportedAbis: ['arm64-v8a'],
    ),
    release: release,
    asset: release.assets[1],
  );
}

UpdateRelease _release() => UpdateRelease(
      tag: 'v0.1.3',
      name: 'Lumina eUICC 0.1.3',
      version: const AppVersion(0, 1, 3),
      assets: [
        _asset(UpdateApkVariant.universal),
        _asset(UpdateApkVariant.arm64V8a),
        _asset(UpdateApkVariant.armeabiV7a),
        _asset(UpdateApkVariant.x86_64),
      ],
    );

UpdateAsset _asset(UpdateApkVariant variant) => UpdateAsset(
      name: 'lumina-euicc-0.1.3-4-${variant.assetSuffix}.apk',
      downloadUri: Uri.parse(
        'https://github.com/Syngnat/lumina-euicc/releases/download/v0.1.3/'
        'lumina-euicc-0.1.3-4-${variant.assetSuffix}.apk',
      ),
      sha256: List.filled(64, 'a').join(),
      size: 23000000,
      variant: variant,
    );

Future<void> _pump(
  WidgetTester tester,
  AppUpdateService service,
  Widget page,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appUpdateServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
