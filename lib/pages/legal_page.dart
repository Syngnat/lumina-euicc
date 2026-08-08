import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';

const _sourceRepositoryUrl = 'https://github.com/Syngnat/lumina-euicc';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.legalAndOpenSource)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _LegalCard(
            icon: Icons.balance_outlined,
            title: l10n.projectLicense,
            children: [
              Text(l10n.projectLicenseDescription),
              const SizedBox(height: 12),
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: Chip(
                  avatar: Icon(Icons.code, size: 18),
                  label: Text('GPL-3.0-only'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LegalCard(
            icon: Icons.gpp_maybe_outlined,
            title: l10n.noWarrantyTitle,
            iconColor: scheme.error,
            children: [Text(l10n.noWarrantyDescription)],
          ),
          const SizedBox(height: 12),
          _LegalCard(
            icon: Icons.source_outlined,
            title: l10n.sourceCode,
            children: [
              Text(l10n.sourceCodeDescription),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SelectableText(
                      _sourceRepositoryUrl,
                      key: const Key('sourceRepositoryUrl'),
                      style: TextStyle(color: scheme.primary),
                    ),
                  ),
                  IconButton(
                    key: const Key('copySourceRepositoryUrl'),
                    tooltip: l10n.copySourceCodeUrl,
                    onPressed: () async {
                      await Clipboard.setData(
                        const ClipboardData(text: _sourceRepositoryUrl),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.sourceCodeUrlCopied)),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LegalCard(
            icon: Icons.hub_outlined,
            title: l10n.thirdPartySoftware,
            children: [
              _Attribution(
                name: 'OpenEUICC',
                description: l10n.openEuiccAttribution,
              ),
              const Divider(height: 24),
              _Attribution(
                name: 'lpac / lpac-jni',
                description: l10n.lpacAttribution,
              ),
              const Divider(height: 24),
              _Attribution(
                name: 'cJSON',
                description: l10n.cjsonAttribution,
              ),
              const Divider(height: 24),
              _Attribution(
                name: 'ZXing Android Embedded / ZXing Core',
                description: l10n.zxingAttribution,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LegalCard(
            icon: Icons.description_outlined,
            title: l10n.legalDocuments,
            children: [Text(l10n.legalDocumentsDescription)],
          ),
          const SizedBox(height: 12),
          _LegalCard(
            icon: Icons.inventory_2_outlined,
            title: l10n.runtimeLicenses,
            children: [
              Text(l10n.runtimeLicensesDescription),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonalIcon(
                  key: const Key('openRuntimeLicenses'),
                  onPressed: () {
                    showLicensePage(
                      context: context,
                      applicationName: l10n.appTitle,
                      applicationLegalese: l10n.licensePageLegalese,
                    );
                  },
                  icon: const Icon(Icons.article_outlined),
                  label: Text(l10n.openRuntimeLicenses),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  const _LegalCard({
    required this.icon,
    required this.title,
    required this.children,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: iconColor ?? theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.name, required this.description});

  final String name;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(description),
      ],
    );
  }
}
