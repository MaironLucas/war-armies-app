import 'package:flutter/material.dart';
import 'package:war_armies_app/l10n/l10n.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appTitle)),
      body: const Center(child: Text('Home')),
    );
  }
}
