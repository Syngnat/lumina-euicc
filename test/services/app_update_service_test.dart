import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/services/app_update_service.dart';

void main() {
  group('AppVersion', () {
    test('compares semantic release versions numerically', () {
      expect(
          AppVersion.parse('v0.1.10'), greaterThan(AppVersion.parse('0.1.9')));
      expect(
          AppVersion.parse('0.2.0'), greaterThan(AppVersion.parse('0.1.99')));
      expect(AppVersion.parse('0.1.2'), AppVersion.parse('v0.1.2'));
    });

    test('rejects tags outside the stable vMAJOR.MINOR.PATCH contract', () {
      expect(() => AppVersion.parse('latest'), throwsFormatException);
      expect(() => AppVersion.parse('v1.2.3-beta'), throwsFormatException);
    });
  });

  group('GitHub release parsing', () {
    test('selects the installed split ABI and preserves update family', () {
      final release = UpdateRelease.fromGitHubJson(_releaseFixture());
      const runtime = AppRuntimeInfo(
        versionName: '0.1.2',
        versionCode: 2003,
        supportedAbis: ['arm64-v8a', 'armeabi-v7a'],
      );

      final asset = selectUpdateAsset(
        release,
        runtime,
        compiledVariant: 'auto',
      );

      expect(asset.variant, UpdateApkVariant.arm64V8a);
      expect(asset.name, 'lumina-euicc-0.1.3-4-arm64-v8a.apk');
      expect(
        asset.sha256,
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      );
    });

    test('keeps universal installs on the universal update chain', () {
      final release = UpdateRelease.fromGitHubJson(_releaseFixture());
      const runtime = AppRuntimeInfo(
        versionName: '0.1.2',
        versionCode: 3,
        supportedAbis: ['arm64-v8a', 'armeabi-v7a'],
      );

      final asset = selectUpdateAsset(
        release,
        runtime,
        compiledVariant: 'auto',
      );

      expect(asset.variant, UpdateApkVariant.universal);
    });

    test('explicit build metadata wins over legacy version-code inference', () {
      final release = UpdateRelease.fromGitHubJson(_releaseFixture());
      const runtime = AppRuntimeInfo(
        versionName: '0.1.2',
        versionCode: 3,
        supportedAbis: ['arm64-v8a', 'armeabi-v7a'],
      );

      final asset = selectUpdateAsset(
        release,
        runtime,
        compiledVariant: 'split',
      );

      expect(asset.variant, UpdateApkVariant.arm64V8a);
    });

    test('rejects mutable releases and untrusted asset URLs', () {
      final mutable = _releaseFixture()..['immutable'] = false;
      expect(
        () => UpdateRelease.fromGitHubJson(mutable),
        throwsA(isA<AppUpdateException>()),
      );

      final untrusted = _releaseFixture();
      final assets = untrusted['assets']! as List<Map<String, Object>>;
      assets.first['browser_download_url'] =
          'https://example.com/lumina-euicc-0.1.3-4-universal.apk';
      expect(
        () => UpdateRelease.fromGitHubJson(untrusted),
        throwsA(isA<AppUpdateException>()),
      );
    });

    test('requires every APK asset name to match the release tag version', () {
      final mismatched = _releaseFixture();
      final assets = mismatched['assets']! as List<Map<String, Object>>;
      assets.first
        ..['name'] = 'lumina-euicc-9.9.9-4-universal.apk'
        ..['browser_download_url'] =
            'https://github.com/Syngnat/lumina-euicc/releases/download/'
                'v0.1.3/lumina-euicc-9.9.9-4-universal.apk';

      expect(
        () => UpdateRelease.fromGitHubJson(mismatched),
        throwsA(isA<AppUpdateException>()),
      );
    });

    test('requires the immutable GitHub SHA-256 digest', () {
      final fixture = _releaseFixture();
      final assets = fixture['assets']! as List<Map<String, Object>>;
      assets.first.remove('digest');

      expect(
        () => UpdateRelease.fromGitHubJson(fixture),
        throwsA(isA<AppUpdateException>()),
      );
    });
  });
}

Map<String, Object> _releaseFixture() => {
      'tag_name': 'v0.1.3',
      'name': 'Lumina eUICC 0.1.3',
      'draft': false,
      'prerelease': false,
      'immutable': true,
      'assets': [
        _asset('universal', 'b'),
        _asset('arm64-v8a', 'a'),
        _asset('armeabi-v7a', 'c'),
        _asset('x86_64', 'd'),
      ],
    };

Map<String, Object> _asset(String variant, String digestCharacter) => {
      'name': 'lumina-euicc-0.1.3-4-$variant.apk',
      'browser_download_url':
          'https://github.com/Syngnat/lumina-euicc/releases/download/'
              'v0.1.3/lumina-euicc-0.1.3-4-$variant.apk',
      'digest': 'sha256:${List.filled(64, digestCharacter).join()}',
      'size': 23000000,
    };
