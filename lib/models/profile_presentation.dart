import 'package:flutter/foundation.dart';

/// A deliberately small, conservative presentation classification.
///
/// eUICC profile metadata does not carry a trustworthy country field. We only
/// assign a country when the displayed identity has an explicit, known match;
/// explicit travel identities stay global and everything else stays unknown.
/// ICCID and EID digits are never inspected.
enum ProfileRegion { unitedKingdom, global, unknown }

@immutable
class ProfilePresentation {
  const ProfilePresentation({
    required this.region,
    required this.symbol,
  });

  final ProfileRegion region;
  final String symbol;

  static ProfilePresentation infer({
    required String name,
    required String provider,
  }) {
    final identity = '$name $provider'.toLowerCase();

    if (_containsIdentityToken(identity, 'giffgaff')) {
      return const ProfilePresentation(
        region: ProfileRegion.unitedKingdom,
        symbol: '🇬🇧',
      );
    }

    // Saily and explicit travel/global labels intentionally stay global.
    if (_containsAnyIdentityToken(identity, const [
      'saily',
      'travel',
      'global',
    ])) {
      return const ProfilePresentation(
        region: ProfileRegion.global,
        symbol: '🌐',
      );
    }

    return const ProfilePresentation(
      region: ProfileRegion.unknown,
      symbol: '🌐',
    );
  }

  static bool _containsAnyIdentityToken(
    String identity,
    List<String> tokens,
  ) =>
      tokens.any((token) => _containsIdentityToken(identity, token));

  static bool _containsIdentityToken(String identity, String token) {
    final escaped = RegExp.escape(token);
    return RegExp('(^|[^a-z0-9])$escaped([^a-z0-9]|\$)').hasMatch(identity);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfilePresentation &&
          region == other.region &&
          symbol == other.symbol;

  @override
  int get hashCode => Object.hash(region, symbol);
}
