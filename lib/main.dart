import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/repositories/backup_repository.dart';
import 'data/repositories/daily_market_repository.dart';
import 'data/repositories/finance_repository.dart';
import 'data/repositories/reminder_repository.dart';
import 'data/repositories/settings_qr_repository.dart';
import 'data/services/asset_data_service.dart';
import 'data/services/backup_service.dart';
import 'data/services/local_db_service.dart';
import 'data/services/market_price_service.dart';
import 'data/services/preferences_service.dart';
import 'routing/app_router.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/features/baydin/view_models/baydin_view_model.dart';
import 'ui/features/daily_market/view_models/daily_market_view_model.dart';
import 'ui/features/finance_calc/view_models/finance_calc_view_model.dart';
import 'ui/features/home/view_models/home_view_model.dart';
import 'ui/features/reminders_qr/view_models/reminders_qr_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = LocalDbService();
  final preferencesService = PreferencesService();
  final assetDataService = AssetDataService();
  final marketPriceService = MarketPriceService();
  final backupService = BackupService();

  final financeRepository = FinanceRepository(dbService: dbService);
  final dailyMarketRepository = DailyMarketRepository(
    dbService: dbService,
    assetDataService: assetDataService,
    marketPriceService: marketPriceService,
  );
  final reminderRepository = ReminderRepository(dbService: dbService);
  final settingsQrRepository =
      SettingsQrRepository(preferencesService: preferencesService);
  final backupRepository = BackupRepository(
    dbService: dbService,
    backupService: backupService,
    financeRepository: financeRepository,
    dailyMarketRepository: dailyMarketRepository,
    reminderRepository: reminderRepository,
    settingsQrRepository: settingsQrRepository,
  );

  runApp(
    MyanmarDailyApp(
      homeViewModel: HomeViewModel(
        settingsQrRepository: settingsQrRepository,
        reminderRepository: reminderRepository,
        financeRepository: financeRepository,
        dailyMarketRepository: dailyMarketRepository,
        backupRepository: backupRepository,
      ),
      financeCalcViewModel: FinanceCalcViewModel(
        financeRepository: financeRepository,
        marketPriceService: marketPriceService,
      ),
      dailyMarketViewModel:
          DailyMarketViewModel(repository: dailyMarketRepository),
      remindersQrViewModel: RemindersQrViewModel(
        reminderRepository: reminderRepository,
        settingsQrRepository: settingsQrRepository,
      ),
      baydinViewModel: BaydinViewModel(),
    ),
  );
}

/// Root widget for the offline-first modular Myanmar Daily App.
class MyanmarDailyApp extends StatefulWidget {
  const MyanmarDailyApp({
    super.key,
    required this.homeViewModel,
    required this.financeCalcViewModel,
    required this.dailyMarketViewModel,
    required this.remindersQrViewModel,
    this.baydinViewModel,
  });

  final HomeViewModel homeViewModel;
  final FinanceCalcViewModel financeCalcViewModel;
  final DailyMarketViewModel dailyMarketViewModel;
  final RemindersQrViewModel remindersQrViewModel;
  final BaydinViewModel? baydinViewModel;

  @override
  State<MyanmarDailyApp> createState() => _MyanmarDailyAppState();
}

class _MyanmarDailyAppState extends State<MyanmarDailyApp> {
  late final BaydinViewModel _baydinViewModel =
      widget.baydinViewModel ?? BaydinViewModel();

  late final GoRouter _router = createAppRouter(
    homeViewModel: widget.homeViewModel,
    financeCalcViewModel: widget.financeCalcViewModel,
    dailyMarketViewModel: widget.dailyMarketViewModel,
    remindersQrViewModel: widget.remindersQrViewModel,
    baydinViewModel: _baydinViewModel,
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.homeViewModel),
        ChangeNotifierProvider.value(value: widget.financeCalcViewModel),
        ChangeNotifierProvider.value(value: widget.dailyMarketViewModel),
        ChangeNotifierProvider.value(value: widget.remindersQrViewModel),
        ChangeNotifierProvider.value(value: _baydinViewModel),
      ],
      child: MaterialApp.router(
        title: 'မြန်မာနေ့စဉ်',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
