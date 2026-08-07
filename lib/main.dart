import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      title: 'Lumina eUICC',
      debugShowCheckedModeBanner: false,
      theme: LuminaTheme.light,
      darkTheme: LuminaTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
