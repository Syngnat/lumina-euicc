import 'dart:convert';
import 'dart:io';

import 'euicc_bridge.dart';

const _latestReleaseUri =
    'https://api.github.com/repos/Syngnat/lumina-euicc/releases/latest';
const _maximumReleaseResponseBytes = 2 * 1024 * 1024;
const _maximumApkBytes = 200 * 1024 * 1024;
const _compiledApkVariant = String.fromEnvironment(
  'LUMINA_APK_VARIANT',
  defaultValue: 'auto',
);

typedef UpdateProgressCallback = void Function(int received, int total);
typedef ReleaseFetcher = Future<Map<String, dynamic>> Function(Uri uri);
typedef UpdateDownloader = Future<void> Function(
  Uri uri,
  File destination,
  int expectedSize,
  UpdateProgressCallback onProgress,
);

class AppUpdateException implements Exception {
  const AppUpdateException(this.code);

  final String code;

  @override
  String toString() => 'AppUpdateException($code)';
}

class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch);

  factory AppVersion.parse(String value) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$').firstMatch(value.trim());
    if (match == null) throw const FormatException('Invalid stable version');
    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  final int major;
  final int minor;
  final int patch;

  @override
  int compareTo(AppVersion other) {
    final majorResult = major.compareTo(other.major);
    if (majorResult != 0) return majorResult;
    final minorResult = minor.compareTo(other.minor);
    if (minorResult != 0) return minorResult;
    return patch.compareTo(other.patch);
  }

  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator <(AppVersion other) => compareTo(other) < 0;
  bool operator >=(AppVersion other) => compareTo(other) >= 0;
  bool operator <=(AppVersion other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}

class AppRuntimeInfo {
  const AppRuntimeInfo({
    required this.versionName,
    required this.versionCode,
    required this.supportedAbis,
  });

  factory AppRuntimeInfo.fromMap(Map<dynamic, dynamic> map) {
    final versionName = map['versionName']?.toString();
    final versionCode = map['versionCode'];
    final supportedAbis = map['supportedAbis'];
    if (versionName == null ||
        versionName.isEmpty ||
        versionCode is! num ||
        versionCode != versionCode.toInt() ||
        supportedAbis is! List) {
      throw const AppUpdateException('invalid_runtime_info');
    }
    final abis = supportedAbis.map((value) => value.toString()).toList();
    return AppRuntimeInfo(
      versionName: versionName,
      versionCode: versionCode.toInt(),
      supportedAbis: List.unmodifiable(abis),
    );
  }

  final String versionName;
  final int versionCode;
  final List<String> supportedAbis;

  AppVersion get version {
    try {
      return AppVersion.parse(versionName);
    } on FormatException {
      throw const AppUpdateException('invalid_runtime_version');
    }
  }
}

enum UpdateApkVariant {
  universal('universal'),
  arm64V8a('arm64-v8a'),
  armeabiV7a('armeabi-v7a'),
  x86_64('x86_64');

  const UpdateApkVariant(this.assetSuffix);

  final String assetSuffix;
}

class UpdateAsset {
  const UpdateAsset({
    required this.name,
    required this.downloadUri,
    required this.sha256,
    required this.size,
    required this.variant,
  });

  final String name;
  final Uri downloadUri;
  final String sha256;
  final int size;
  final UpdateApkVariant variant;
}

class UpdateRelease {
  const UpdateRelease({
    required this.tag,
    required this.name,
    required this.version,
    required this.assets,
  });

  factory UpdateRelease.fromGitHubJson(Map<String, dynamic> json) {
    if (json['draft'] != false ||
        json['prerelease'] != false ||
        json['immutable'] != true) {
      throw const AppUpdateException('release_not_immutable');
    }
    final tag = json['tag_name']?.toString();
    final name = json['name']?.toString();
    if (tag == null || tag.isEmpty || name == null || name.isEmpty) {
      throw const AppUpdateException('invalid_release_metadata');
    }
    late final AppVersion version;
    try {
      version = AppVersion.parse(tag);
    } on FormatException {
      throw const AppUpdateException('invalid_release_version');
    }
    final rawAssets = json['assets'];
    if (rawAssets is! List) {
      throw const AppUpdateException('invalid_release_assets');
    }
    final assets = rawAssets.map((raw) {
      if (raw is! Map) {
        throw const AppUpdateException('invalid_release_assets');
      }
      return _parseAsset(Map<String, dynamic>.from(raw), tag);
    }).toList();
    final variants = assets.map((asset) => asset.variant).toSet();
    if (assets.length != UpdateApkVariant.values.length ||
        variants.length != UpdateApkVariant.values.length) {
      throw const AppUpdateException('incomplete_release_assets');
    }
    return UpdateRelease(
      tag: tag,
      name: name,
      version: version,
      assets: List.unmodifiable(assets),
    );
  }

  final String tag;
  final String name;
  final AppVersion version;
  final List<UpdateAsset> assets;
}

class AppUpdateCheck {
  const AppUpdateCheck({
    required this.runtime,
    required this.release,
    required this.asset,
  });

  final AppRuntimeInfo runtime;
  final UpdateRelease release;
  final UpdateAsset? asset;

  bool get updateAvailable => asset != null;
}

enum InstallUpdateStatus { launched, permissionRequired }

abstract interface class AppUpdateService {
  Future<AppUpdateCheck> checkForUpdate();

  Future<String> downloadUpdate(
    AppUpdateCheck check, {
    required UpdateProgressCallback onProgress,
  });

  Future<InstallUpdateStatus> installDownloadedUpdate(
    AppUpdateCheck check,
    String path,
  );

  Future<void> openInstallPermissionSettings();
}

class GitHubAppUpdateService implements AppUpdateService {
  GitHubAppUpdateService({
    required EuiccBridge bridge,
    ReleaseFetcher? fetchRelease,
    UpdateDownloader? downloadAsset,
    String compiledVariant = _compiledApkVariant,
  })  : _bridge = bridge,
        _fetchRelease = fetchRelease ?? _defaultFetchRelease,
        _downloadAsset = downloadAsset ?? _defaultDownloadAsset,
        _compiledVariant = compiledVariant;

  final EuiccBridge _bridge;
  final ReleaseFetcher _fetchRelease;
  final UpdateDownloader _downloadAsset;
  final String _compiledVariant;

  @override
  Future<AppUpdateCheck> checkForUpdate() async {
    final runtime = AppRuntimeInfo.fromMap(await _bridge.getAppRuntimeInfo());
    final json = await _fetchRelease(Uri.parse(_latestReleaseUri));
    final release = UpdateRelease.fromGitHubJson(json);
    if (release.version <= runtime.version) {
      return AppUpdateCheck(runtime: runtime, release: release, asset: null);
    }
    return AppUpdateCheck(
      runtime: runtime,
      release: release,
      asset: selectUpdateAsset(
        release,
        runtime,
        compiledVariant: _compiledVariant,
      ),
    );
  }

  @override
  Future<String> downloadUpdate(
    AppUpdateCheck check, {
    required UpdateProgressCallback onProgress,
  }) async {
    final asset = check.asset;
    if (asset == null) throw const AppUpdateException('no_update_available');
    final path = await _bridge.prepareUpdateFile(asset.name);
    await _downloadAsset(
      asset.downloadUri,
      File(path),
      asset.size,
      onProgress,
    );
    return path;
  }

  @override
  Future<InstallUpdateStatus> installDownloadedUpdate(
    AppUpdateCheck check,
    String path,
  ) async {
    final asset = check.asset;
    if (asset == null) throw const AppUpdateException('no_update_available');
    final status = await _bridge.verifyAndInstallUpdate(
      path: path,
      expectedSha256: asset.sha256,
      expectedSize: asset.size,
      expectedVersionName: check.release.version.toString(),
    );
    return switch (status) {
      'launched' => InstallUpdateStatus.launched,
      'permissionRequired' => InstallUpdateStatus.permissionRequired,
      _ => throw const AppUpdateException('invalid_install_status'),
    };
  }

  @override
  Future<void> openInstallPermissionSettings() =>
      _bridge.openInstallPermissionSettings();
}

UpdateAsset selectUpdateAsset(
  UpdateRelease release,
  AppRuntimeInfo runtime, {
  String compiledVariant = _compiledApkVariant,
}) {
  final variant = _installedVariant(runtime, compiledVariant);
  final matches = release.assets.where((asset) => asset.variant == variant);
  if (matches.length != 1) {
    throw const AppUpdateException('unsupported_update_asset');
  }
  return matches.single;
}

UpdateApkVariant _installedVariant(
  AppRuntimeInfo runtime,
  String compiledVariant,
) {
  if (compiledVariant == 'universal') return UpdateApkVariant.universal;
  if (compiledVariant == 'split') return _variantForSupportedAbis(runtime);
  if (compiledVariant != 'auto') {
    throw const AppUpdateException('invalid_compiled_variant');
  }

  if (runtime.versionCode >= 1000) {
    final inferred = switch (runtime.versionCode ~/ 1000) {
      1 => UpdateApkVariant.armeabiV7a,
      2 => UpdateApkVariant.arm64V8a,
      3 => UpdateApkVariant.x86_64,
      _ => null,
    };
    if (inferred != null) return inferred;
    return _variantForSupportedAbis(runtime);
  }
  return UpdateApkVariant.universal;
}

UpdateApkVariant _variantForSupportedAbis(AppRuntimeInfo runtime) {
  for (final abi in runtime.supportedAbis) {
    switch (abi) {
      case 'arm64-v8a':
        return UpdateApkVariant.arm64V8a;
      case 'armeabi-v7a':
        return UpdateApkVariant.armeabiV7a;
      case 'x86_64':
        return UpdateApkVariant.x86_64;
    }
  }
  throw const AppUpdateException('unsupported_device_abi');
}

UpdateAsset _parseAsset(Map<String, dynamic> json, String tag) {
  final name = json['name']?.toString();
  final url = json['browser_download_url']?.toString();
  final digest = json['digest']?.toString().toLowerCase();
  final rawSize = json['size'];
  if (name == null || url == null || digest == null || rawSize is! num) {
    throw const AppUpdateException('invalid_release_asset');
  }
  final nameMatch = RegExp(
    r'^lumina-euicc-(\d+\.\d+\.\d+)-\d+-(universal|arm64-v8a|armeabi-v7a|x86_64)\.apk$',
  ).firstMatch(name);
  final digestMatch = RegExp(r'^sha256:([0-9a-f]{64})$').firstMatch(digest);
  final size = rawSize.toInt();
  if (nameMatch == null ||
      digestMatch == null ||
      rawSize != size ||
      size <= 0 ||
      size > _maximumApkBytes ||
      AppVersion.parse(nameMatch.group(1)!) != AppVersion.parse(tag)) {
    throw const AppUpdateException('invalid_release_asset');
  }
  final uri = Uri.tryParse(url);
  final expectedSegments = [
    'Syngnat',
    'lumina-euicc',
    'releases',
    'download',
    tag,
    name,
  ];
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != 'github.com' ||
      uri.pathSegments.length != expectedSegments.length ||
      !_listEquals(uri.pathSegments, expectedSegments) ||
      uri.hasQuery) {
    throw const AppUpdateException('untrusted_release_asset_url');
  }
  final variantName = nameMatch.group(2)!;
  final variant = UpdateApkVariant.values.singleWhere(
    (candidate) => candidate.assetSuffix == variantName,
  );
  return UpdateAsset(
    name: name,
    downloadUri: uri,
    sha256: digestMatch.group(1)!,
    size: size,
    variant: variant,
  );
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

Future<Map<String, dynamic>> _defaultFetchRelease(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.getUrl(uri);
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'Lumina-eUICC-update-checker');
    final response = await request.close().timeout(const Duration(seconds: 30));
    if (response.statusCode != HttpStatus.ok) {
      throw const AppUpdateException('release_check_http_error');
    }
    if (response.contentLength > _maximumReleaseResponseBytes) {
      throw const AppUpdateException('release_response_too_large');
    }
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 30))) {
      bytes.addAll(chunk);
      if (bytes.length > _maximumReleaseResponseBytes) {
        throw const AppUpdateException('release_response_too_large');
      }
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const AppUpdateException('invalid_release_response');
    }
    return Map<String, dynamic>.from(decoded);
  } on AppUpdateException {
    rethrow;
  } catch (_) {
    throw const AppUpdateException('release_check_network_error');
  } finally {
    client.close(force: true);
  }
}

Future<void> _defaultDownloadAsset(
  Uri uri,
  File destination,
  int expectedSize,
  UpdateProgressCallback onProgress,
) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  final partial = File('${destination.path}.part');
  IOSink? sink;
  try {
    await destination.parent.create(recursive: true);
    if (await partial.exists()) await partial.delete();
    final request = await client.getUrl(uri);
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'Lumina-eUICC-update-downloader',
    );
    final response = await request.close().timeout(const Duration(seconds: 30));
    if (response.statusCode != HttpStatus.ok) {
      throw const AppUpdateException('update_download_http_error');
    }
    if (response.contentLength > 0 && response.contentLength != expectedSize) {
      throw const AppUpdateException('update_download_size_mismatch');
    }
    sink = partial.openWrite();
    var received = 0;
    await for (final chunk in response.timeout(const Duration(seconds: 30))) {
      received += chunk.length;
      if (received > expectedSize || received > _maximumApkBytes) {
        throw const AppUpdateException('update_download_size_mismatch');
      }
      sink.add(chunk);
      onProgress(received, expectedSize);
    }
    await sink.flush();
    await sink.close();
    sink = null;
    if (received != expectedSize) {
      throw const AppUpdateException('update_download_size_mismatch');
    }
    if (await destination.exists()) await destination.delete();
    await partial.rename(destination.path);
  } on AppUpdateException {
    rethrow;
  } catch (_) {
    throw const AppUpdateException('update_download_network_error');
  } finally {
    await sink?.close();
    client.close(force: true);
    if (await partial.exists()) await partial.delete();
  }
}
