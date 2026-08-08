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
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final localized = context.l10n.localizeCompatibilityItem(item);
              return Card(
                child: ListTile(
                  leading: Icon(
                    item.ok ? Icons.check_circle : Icons.error_outline,
                    color: item.ok
                        ? Colors.teal
                        : Theme.of(context).colorScheme.error,
                  ),
                  title: Text(localized.title),
                  subtitle: Text(localized.detail),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
