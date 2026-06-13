import 'package:flutter/material.dart';
import 'package:war_armies_app/common/routing/app_router.dart';
import 'package:war_armies_app/features/shared/shared.dart';
import 'package:war_armies_app/l10n/l10n.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WarAppBar(title: context.l10n.appTitle, showBackButton: false),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WarCard(
              onTap: () => Navigator.pushNamed(context, AppRouter.hostRoom),
              child: Row(
                children: [
                  const Icon(Icons.wifi_tethering),
                  const SizedBox(width: 16),
                  Text(context.l10n.hostGame),
                ],
              ),
            ),
            WarCard(
              onTap: () => Navigator.pushNamed(context, AppRouter.joinRoom),
              child: Row(
                children: [
                  const Icon(Icons.wifi_find),
                  const SizedBox(width: 16),
                  Text(context.l10n.joinGame),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
