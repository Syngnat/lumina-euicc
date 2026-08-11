import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/services/profile_size_estimator.dart';

void main() {
  const source = '''
  {
    "offset": {"89086030": 12168},
    "sizes": {
      "23410|giffgaff": [13088, 13302, 14393],
      "45400|Carrier": [15616, 16374]
    }
  }
  ''';

  test('estimates a known provider and applies the card-family offset', () {
    final estimator = ProfileSizeEstimator.fromJson(source);

    expect(
      estimator.estimateBytes(
        provider: ' GiffGaff ',
        profileName: 'UK line',
        eid: '89086030202200000000000000000000',
      ),
      25762,
    );
  });

  test('does not invent a size for generic or unknown provider metadata', () {
    final estimator = ProfileSizeEstimator.fromJson(source);

    expect(
      estimator.estimateBytes(
        provider: 'Carrier',
        profileName: 'Travel profile',
        eid: '89086030202200000000000000000000',
      ),
      isNull,
    );
    expect(
      estimator.estimateBytes(
        provider: 'Unknown brand',
        profileName: 'Unknown profile',
        eid: '89086030202200000000000000000000',
      ),
      isNull,
    );
  });
}
