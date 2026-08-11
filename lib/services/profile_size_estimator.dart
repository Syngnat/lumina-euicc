import 'dart:convert';

import 'package:flutter/services.dart';

/// Estimates installed profile storage from public, observed profile samples.
///
/// SGP.22 GetProfilesInfo does not expose per-profile storage usage. Values
/// returned here are estimates, never measurements from the installed card.
class ProfileSizeEstimator {
  ProfileSizeEstimator._({
    required Map<String, int> eidOffsets,
    required Map<String, int> providerAverages,
  })  : _eidOffsets = eidOffsets,
        _providerAverages = providerAverages;

  factory ProfileSizeEstimator.fromJson(String source) {
    final root = jsonDecode(source);
    if (root is! Map<String, dynamic>) {
      throw const FormatException('Invalid profile-size estimate data');
    }

    final offsets = <String, int>{};
    final rawOffsets = root['offset'];
    if (rawOffsets is Map<String, dynamic>) {
      for (final entry in rawOffsets.entries) {
        final value = entry.value;
        if (RegExp(r'^\d{8}$').hasMatch(entry.key) && value is num) {
          offsets[entry.key] = value.round();
        }
      }
    }

    final providerSamples = <String, List<num>>{};
    final rawProviders = root['providers'];
    if (rawProviders is Map<String, dynamic>) {
      for (final entry in rawProviders.entries) {
        final value = entry.value;
        if (value is num) {
          providerSamples.putIfAbsent(entry.key, () => []).add(value);
        }
      }
    }
    final rawSizes = root['sizes'];
    if (rawSizes is Map<String, dynamic>) {
      for (final entry in rawSizes.entries) {
        final separator = entry.key.indexOf('|');
        if (separator < 0 || separator == entry.key.length - 1) continue;
        final provider = entry.key.substring(separator + 1);
        final values = entry.value;
        if (values is List) {
          providerSamples
              .putIfAbsent(provider, () => [])
              .addAll(values.whereType<num>());
        }
      }
    }

    final averages = <String, int>{};
    for (final entry in providerSamples.entries) {
      final key = _normalize(entry.key);
      if (key.isEmpty || entry.value.isEmpty) continue;
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      averages[key] = average.round();
    }
    return ProfileSizeEstimator._(
      eidOffsets: Map.unmodifiable(offsets),
      providerAverages: Map.unmodifiable(averages),
    );
  }

  static Future<ProfileSizeEstimator> load() async =>
      ProfileSizeEstimator.fromJson(
        await rootBundle.loadString(
          'assets/data/profile_size_estimates.json',
        ),
      );

  final Map<String, int> _eidOffsets;
  final Map<String, int> _providerAverages;

  int? estimateBytes({
    required String provider,
    required String profileName,
    required String eid,
  }) {
    final providerKey = _normalize(provider);
    final nameKey = _normalize(profileName);
    final key = _usableKey(providerKey) ?? _usableKey(nameKey);
    if (key == null) return null;

    final sample = _providerAverages[key];
    if (sample == null) return null;
    final offset =
        eid.length >= 8 ? (_eidOffsets[eid.substring(0, 8)] ?? 0) : 0;
    final estimate = sample + offset;
    return estimate >= 5 * 1024 && estimate <= 200 * 1024 ? estimate : null;
  }

  String? _usableKey(String value) {
    if (_genericProviders.contains(value)) return null;
    if (_providerAverages.containsKey(value)) return value;
    return null;
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static const _genericProviders = {
    '',
    'carrier',
    'connect',
    'data esim',
    'esim',
    'esim internet',
    'mobile',
  };
}
