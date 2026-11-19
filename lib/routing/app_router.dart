import 'package:go_router/go_router.dart';

import '../ui/core/widgets/scaffold_with_nav_bar.dart';
import '../ui/features/baydin/view_models/baydin_view_model.dart';
import '../ui/features/baydin/views/baydin_screen.dart';
import '../ui/features/daily_market/view_models/daily_market_view_model.dart';
import '../ui/features/daily_market/views/daily_market_screen.dart';
import '../ui/features/finance_calc/view_models/finance_calc_view_model.dart';
import '../ui/features/finance_calc/views/finance_calc_screen.dart';
import '../ui/features/home/view_models/home_view_model.dart';
import '../ui/features/reminders_qr/view_models/reminders_qr_view_model.dart';
import '../ui/features/reminders_qr/views/reminders_qr_screen.dart';

/// Builds the household-first 4-branch persistent bottom navigation GoRouter configuration.
GoRouter createAppRouter({
  required HomeViewModel homeViewModel,
  required FinanceCalcViewModel financeCalcViewModel,
  required DailyMarketViewModel dailyMarketViewModel,
  required RemindersQrViewModel remindersQrViewModel,
  required BaydinViewModel baydinViewModel,
}) {
  return GoRouter(
    initialLocation: '/daily',
    routes: [
      GoRoute(
        path: '/home',
        redirect: (context, state) => '/daily',
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/daily',
                builder: (context, state) =>
                    DailyMarketScreen(viewModel: dailyMarketViewModel),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/baydin',
                builder: (context, state) =>
                    BaydinScreen(viewModel: baydinViewModel),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/finance',
                builder: (context, state) =>
                    FinanceCalcScreen(viewModel: financeCalcViewModel),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tools',
                builder: (context, state) => RemindersQrScreen(
                  viewModel: remindersQrViewModel,
                  homeViewModel: homeViewModel,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
