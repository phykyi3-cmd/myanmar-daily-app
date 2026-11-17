import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/baydin/view_models/baydin_view_model.dart';
import '../../features/finance_calc/view_models/finance_calc_view_model.dart';
import '../../features/home/view_models/home_view_model.dart';
import '../../features/maternal_child/view_models/maternal_child_view_model.dart';
import '../../features/reminders_qr/view_models/reminders_qr_view_model.dart';

/// Persistent NBK Dark + Neon Lime navigation shell centered on household daily needs.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(BuildContext context, int index) {
    if (index == 1) {
      context.read<BaydinViewModel>().loadAll();
    } else if (index == 2) {
      context.read<MaternalChildViewModel>().loadAll();
    } else if (index == 3) {
      context.read<FinanceCalcViewModel>().loadAll();
    } else if (index == 4) {
      context.read<RemindersQrViewModel>().loadAll();
      context.read<HomeViewModel>().loadDashboard();
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF262A33), width: 1.2),
          ),
        ),
        child: NavigationBar(
          height: 62,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => _goBranch(context, index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'အိမ်တွင်းရေး',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded),
              label: 'ဗေဒင်/ယတြာ',
            ),
            NavigationDestination(
              icon: Icon(Icons.child_care_outlined),
              selectedIcon: Icon(Icons.child_care_rounded),
              label: 'မိခင်/ကလေး',
            ),
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate_rounded),
              label: 'စာရင်း/တွက်စက်',
            ),
            NavigationDestination(
              icon: Icon(Icons.apps_outlined),
              selectedIcon: Icon(Icons.apps_rounded),
              label: 'အခြား',
            ),
          ],
        ),
      ),
    );
  }
}
