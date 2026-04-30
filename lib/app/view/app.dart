import 'package:flutter/material.dart';
import 'package:war_armies_app/features/home/presentation/presentation.dart';
import 'package:war_armies_app/l10n/l10n.dart';
import 'package:war_armies_app/theme/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: WarTheme.light,
      darkTheme: WarTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomePage(),
    );
  }
}
