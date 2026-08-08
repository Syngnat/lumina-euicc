import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/l10n.dart';
import 'pages/home_page.dart';
import 'theme/lumina_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: LuminaEuiccApp()));
}

class LuminaEuiccApp extends StatelessWidget {
  const LuminaEuiccApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: LuminaTheme.light,
      darkTheme: LuminaTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
