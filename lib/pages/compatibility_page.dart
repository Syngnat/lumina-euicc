import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../models/euicc_models.dart';
import '../services/providers.dart';

class CompatibilityPage extends ConsumerStatefulWidget {
  const CompatibilityPage({super.key});

  @override
  ConsumerState<CompatibilityPage> createState() => _CompatibilityPageState();
}

class _CompatibilityPageState extends ConsumerState<CompatibilityPage> {
  late Future<List<CompatibilityItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(euiccBridgeProvider).runCompatibilityCheck();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.compatibility),
        actions: [
          IconButton(
            tooltip: context.l10n.refresh,
            onPressed: () {
              setState(() {
                _future = ref.read(euiccBridgeProvider).runCompatibilityCheck();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(context.l10n.compatibilityError('${snapshot.error}')),
            );
          }
          final items = snapshot.data ?? const [];
          final summary = _CompatibilitySummary.fromItems(items);
          final detailItems = items
              .where((item) => item.code != 'device_info')
              .toList(growable: false);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (summary != null) ...[
                _CompatibilitySummaryCard(summary: summary),
                const SizedBox(height: 20),
              ],
              if (detailItems.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    context.l10n.compatibilityDetailsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              for (final item in detailItems) ...[
                _CompatibilityDetailCard(item: item),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CompatibilitySummaryCard extends StatelessWidget {
  const _CompatibilitySummaryCard({required this.summary});

  final _CompatibilitySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Card.filled(
      color: colors.primaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fact_check_outlined, color: colors.primary),
                const SizedBox(width: 12),
                Text(
                  l10n.compatibilityOverviewTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (summary.hasDeviceInfo) ...[
              _SummaryRow(
                icon: Icons.smartphone_outlined,
                label: l10n.compatibilityDeviceLabel,
                value: summary.deviceDescription,
              ),
              _SummaryRow(
                icon: Icons.android_outlined,
                label: l10n.compatibilityAndroidLabel,
                value: summary.androidDescription,
              ),
            ],
            _SummaryRow(
              icon: Icons.sim_card_outlined,
              label: l10n.compatibilityOmapiSlotsLabel,
              value: _formatSlots(l10n, summary.enumeratedSlotIds),
            ),
            _SummaryRow(
              icon: Icons.alt_route_outlined,
              label: l10n.compatibilityIsdrReachedSlotsLabel,
              value: _formatSlots(l10n, summary.isdrReachedSlotIds),
            ),
            _SummaryRow(
              icon: Icons.verified_user_outlined,
              label: l10n.compatibilityIsdrAuthorizedSlotsLabel,
              value: _formatSlots(l10n, summary.authorizedSlotIds),
              valueColor: colors.primary,
            ),
            _SummaryRow(
              icon: Icons.block_outlined,
              label: l10n.compatibilityAraMDeniedSlotsLabel,
              value: _formatSlots(l10n, summary.deniedSlotIds),
              valueColor: summary.deniedSlotIds.isEmpty ? null : colors.error,
              bottomPadding: 0,
            ),
          ],
        ),
      ),
    );
  }

  String _formatSlots(AppLocalizations l10n, List<int> slotIds) {
    if (slotIds.isEmpty) return l10n.compatibilityNoSlots;
    return slotIds.map(l10n.compatibilitySlotName).join(l10n.listSeparator);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.bottomPadding = 14,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompatibilityDetailCard extends StatelessWidget {
  const _CompatibilityDetailCard({required this.item});

  final CompatibilityItem item;

  @override
  Widget build(BuildContext context) {
    final localized = context.l10n.localizeCompatibilityItem(item);
    return Card(
      child: ListTile(
        leading: Icon(
          item.ok ? Icons.check_circle : Icons.error_outline,
          color: item.ok ? Colors.teal : Theme.of(context).colorScheme.error,
        ),
        title: Text(localized.title),
        subtitle: Text(localized.detail),
      ),
    );
  }
}

class _CompatibilitySummary {
  const _CompatibilitySummary({
    required this.brand,
    required this.device,
    required this.model,
    required this.androidRelease,
    required this.androidSdkInt,
    required this.enumeratedSlotIds,
    required this.isdrReachedSlotIds,
    required this.authorizedSlotIds,
    required this.deniedSlotIds,
  });

  final String brand;
  final String device;
  final String model;
  final String androidRelease;
  final int? androidSdkInt;
  final List<int> enumeratedSlotIds;
  final List<int> isdrReachedSlotIds;
  final List<int> authorizedSlotIds;
  final List<int> deniedSlotIds;

  bool get hasDeviceInfo =>
      brand.isNotEmpty ||
      device.isNotEmpty ||
      model.isNotEmpty ||
      androidRelease.isNotEmpty ||
      androidSdkInt != null;

  String get deviceDescription {
    final modelParts =
        [brand, model].where((part) => part.isNotEmpty).join(' ');
    if (device.isEmpty) return modelParts;
    if (modelParts.isEmpty) return device;
    return '$modelParts · $device';
  }

  String get androidDescription {
    final version =
        androidRelease.isEmpty ? 'Android' : 'Android $androidRelease';
    return androidSdkInt == null ? version : '$version · API $androidSdkInt';
  }

  static _CompatibilitySummary? fromItems(List<CompatibilityItem> items) {
    CompatibilityItem? deviceInfo;
    final enumerated = <int>{};
    final isdrReached = <int>{};
    final authorized = <int>{};
    final denied = <int>{};

    for (final item in items) {
      if (item.code == 'device_info') deviceInfo = item;
      if (!item.code.startsWith('omapi_slot_')) continue;
      final slotId = _intValue(item.arguments['slotId']);
      if (slotId == null) continue;
      enumerated.add(slotId);
      if (item.code == 'omapi_slot_authorized') {
        isdrReached.add(slotId);
        authorized.add(slotId);
      }
      if (item.code == 'omapi_slot_access_denied') {
        isdrReached.add(slotId);
        denied.add(slotId);
      }
    }

    if (deviceInfo == null && enumerated.isEmpty) return null;
    final arguments = deviceInfo?.arguments ?? const <String, dynamic>{};
    return _CompatibilitySummary(
      brand: arguments['brand']?.toString() ?? '',
      device: arguments['device']?.toString() ?? '',
      model: arguments['model']?.toString() ?? '',
      androidRelease: arguments['androidRelease']?.toString() ?? '',
      androidSdkInt: _intValue(arguments['androidSdkInt']),
      enumeratedSlotIds: _sorted(enumerated),
      isdrReachedSlotIds: _sorted(isdrReached),
      authorizedSlotIds: _sorted(authorized),
      deniedSlotIds: _sorted(denied),
    );
  }

  static List<int> _sorted(Set<int> values) =>
      (values.toList()..sort()).toList(growable: false);

  static int? _intValue(Object? value) {
    if (value is int) return value;
    return value == null ? null : int.tryParse(value.toString());
  }
}
