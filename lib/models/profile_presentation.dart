import 'package:flutter/foundation.dart';

/// A conservative presentation classification.
///
/// Profile metadata does not expose a service-country field. Explicit provider
/// identities therefore win, travel identities remain global, and an E.118
/// ICCID country code is used only as an issuer-region fallback. The fallback
/// describes where the profile issuer identifier is registered, not coverage.
enum ProfileRegion { unitedKingdom, issuerCountry, global, unknown }

@immutable
class ProfilePresentation {
  const ProfilePresentation({
    required this.region,
    required this.symbol,
    this.countryCode,
    this.inferredFromIccid = false,
  });

  final ProfileRegion region;
  final String symbol;
  final String? countryCode;
  final bool inferredFromIccid;

  static ProfilePresentation infer({
    required String name,
    required String provider,
    String iccid = '',
  }) {
    final identity = '$name $provider'.toLowerCase();

    if (_containsAnyIdentityToken(identity, const [
      'giffgaff',
      'ctexcel',
      'united kingdom',
    ])) {
      return const ProfilePresentation(
        region: ProfileRegion.unitedKingdom,
        symbol: '🇬🇧',
        countryCode: 'GB',
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

    final issuerCountry = _inferIssuerCountryCode(iccid);
    if (issuerCountry == 'GB') {
      return const ProfilePresentation(
        region: ProfileRegion.unitedKingdom,
        symbol: '🇬🇧',
        countryCode: 'GB',
        inferredFromIccid: true,
      );
    }
    if (issuerCountry != null) {
      return ProfilePresentation(
        region: ProfileRegion.issuerCountry,
        symbol: _countryCodeFlag(issuerCountry),
        countryCode: issuerCountry,
        inferredFromIccid: true,
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

  static String? _inferIssuerCountryCode(String rawIccid) {
    final iccid = rawIccid.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^89\d{8,20}$').hasMatch(iccid)) return null;
    final countryAndIssuer = iccid.substring(2);
    for (final length in const [3, 2]) {
      if (countryAndIssuer.length < length) continue;
      final code = countryAndIssuer.substring(0, length);
      final country = _e164CountryCodes[code];
      if (country != null) return country;
    }
    return null;
  }

  static String _countryCodeFlag(String countryCode) => String.fromCharCodes(
        countryCode.codeUnits.map((unit) => unit - 0x41 + 0x1F1E6),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfilePresentation &&
          region == other.region &&
          symbol == other.symbol &&
          countryCode == other.countryCode &&
          inferredFromIccid == other.inferredFromIccid;

  @override
  int get hashCode =>
      Object.hash(region, symbol, countryCode, inferredFromIccid);
}

/// Unambiguous geographic E.164 codes commonly used inside E.118 ICCIDs.
/// Shared/global codes such as 1, 7, 39, 262, 599, and 8xx are intentionally
/// omitted because their digits alone cannot identify one country reliably.
const _e164CountryCodes = <String, String>{
  '20': 'EG',
  '27': 'ZA',
  '30': 'GR',
  '31': 'NL',
  '32': 'BE',
  '33': 'FR',
  '34': 'ES',
  '36': 'HU',
  '40': 'RO',
  '41': 'CH',
  '43': 'AT',
  '44': 'GB',
  '45': 'DK',
  '46': 'SE',
  '47': 'NO',
  '48': 'PL',
  '49': 'DE',
  '51': 'PE',
  '52': 'MX',
  '53': 'CU',
  '54': 'AR',
  '55': 'BR',
  '56': 'CL',
  '57': 'CO',
  '58': 'VE',
  '60': 'MY',
  '61': 'AU',
  '62': 'ID',
  '63': 'PH',
  '64': 'NZ',
  '65': 'SG',
  '66': 'TH',
  '81': 'JP',
  '82': 'KR',
  '84': 'VN',
  '86': 'CN',
  '90': 'TR',
  '91': 'IN',
  '92': 'PK',
  '93': 'AF',
  '94': 'LK',
  '95': 'MM',
  '98': 'IR',
  '211': 'SS',
  '212': 'MA',
  '213': 'DZ',
  '216': 'TN',
  '218': 'LY',
  '220': 'GM',
  '221': 'SN',
  '222': 'MR',
  '223': 'ML',
  '224': 'GN',
  '225': 'CI',
  '226': 'BF',
  '227': 'NE',
  '228': 'TG',
  '229': 'BJ',
  '230': 'MU',
  '231': 'LR',
  '232': 'SL',
  '233': 'GH',
  '234': 'NG',
  '235': 'TD',
  '236': 'CF',
  '237': 'CM',
  '238': 'CV',
  '239': 'ST',
  '240': 'GQ',
  '241': 'GA',
  '242': 'CG',
  '243': 'CD',
  '244': 'AO',
  '245': 'GW',
  '246': 'IO',
  '248': 'SC',
  '249': 'SD',
  '250': 'RW',
  '251': 'ET',
  '252': 'SO',
  '253': 'DJ',
  '254': 'KE',
  '255': 'TZ',
  '256': 'UG',
  '257': 'BI',
  '258': 'MZ',
  '260': 'ZM',
  '261': 'MG',
  '263': 'ZW',
  '264': 'NA',
  '265': 'MW',
  '266': 'LS',
  '267': 'BW',
  '268': 'SZ',
  '269': 'KM',
  '290': 'SH',
  '291': 'ER',
  '297': 'AW',
  '298': 'FO',
  '299': 'GL',
  '350': 'GI',
  '351': 'PT',
  '352': 'LU',
  '353': 'IE',
  '354': 'IS',
  '355': 'AL',
  '356': 'MT',
  '357': 'CY',
  '358': 'FI',
  '359': 'BG',
  '370': 'LT',
  '371': 'LV',
  '372': 'EE',
  '373': 'MD',
  '374': 'AM',
  '375': 'BY',
  '376': 'AD',
  '377': 'MC',
  '378': 'SM',
  '380': 'UA',
  '381': 'RS',
  '382': 'ME',
  '383': 'XK',
  '385': 'HR',
  '386': 'SI',
  '387': 'BA',
  '389': 'MK',
  '420': 'CZ',
  '421': 'SK',
  '423': 'LI',
  '500': 'FK',
  '501': 'BZ',
  '502': 'GT',
  '503': 'SV',
  '504': 'HN',
  '505': 'NI',
  '506': 'CR',
  '507': 'PA',
  '508': 'PM',
  '509': 'HT',
  '590': 'GP',
  '591': 'BO',
  '592': 'GY',
  '593': 'EC',
  '594': 'GF',
  '595': 'PY',
  '596': 'MQ',
  '597': 'SR',
  '598': 'UY',
  '670': 'TL',
  '673': 'BN',
  '674': 'NR',
  '675': 'PG',
  '676': 'TO',
  '677': 'SB',
  '678': 'VU',
  '679': 'FJ',
  '680': 'PW',
  '681': 'WF',
  '682': 'CK',
  '683': 'NU',
  '685': 'WS',
  '686': 'KI',
  '687': 'NC',
  '688': 'TV',
  '689': 'PF',
  '690': 'TK',
  '691': 'FM',
  '692': 'MH',
  '850': 'KP',
  '852': 'HK',
  '853': 'MO',
  '855': 'KH',
  '856': 'LA',
  '880': 'BD',
  '886': 'TW',
  '960': 'MV',
  '961': 'LB',
  '962': 'JO',
  '963': 'SY',
  '964': 'IQ',
  '965': 'KW',
  '966': 'SA',
  '967': 'YE',
  '968': 'OM',
  '970': 'PS',
  '971': 'AE',
  '972': 'IL',
  '973': 'BH',
  '974': 'QA',
  '975': 'BT',
  '976': 'MN',
  '977': 'NP',
  '992': 'TJ',
  '993': 'TM',
  '994': 'AZ',
  '995': 'GE',
  '996': 'KG',
  '998': 'UZ',
};
