import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:myanmar_daily_app/domain/models/commodity_price.dart';
import 'package:myanmar_daily_app/domain/models/daily_purchase_record.dart';
import 'package:myanmar_daily_app/domain/models/recipe.dart';
import 'package:myanmar_daily_app/domain/models/regional_market.dart';
import 'package:myanmar_daily_app/domain/models/shopping_item.dart';
import 'package:myanmar_daily_app/ui/core/theme/app_theme.dart';
import 'package:myanmar_daily_app/ui/core/utils/formatters.dart';
import 'package:myanmar_daily_app/ui/core/widgets/empty_state_card.dart';
import 'package:myanmar_daily_app/ui/features/reminders_qr/view_models/reminders_qr_view_model.dart';
import '../view_models/daily_market_view_model.dart';

class _RecipeCardPalette {
  const _RecipeCardPalette({
    required this.icon,
    required this.background,
    required this.border,
    required this.accent,
    required this.badgeBg,
    required this.spotlightGlow,
  });

  final IconData icon;
  final Color background;
  final Color border;
  final Color accent;
  final Color badgeBg;
  final Color spotlightGlow;
}

_RecipeCardPalette _paletteForRecipe(Recipe recipe) {
  if (recipe.isEthnicDish) {
    switch (recipe.ethnicGroup) {
      case 'ထားဝယ်ဟင်းလျာ':
        return const _RecipeCardPalette(
          icon: Icons.waves_rounded,
          background: Color(0xFF141812),
          border: Color(0xFF3E5918),
          accent: AppTheme.neonLime600,
          badgeBg: Color(0xFF213010),
          spotlightGlow: Color(0xFF3A6614),
        );
      case 'ရှမ်းဟင်းလျာ':
        return const _RecipeCardPalette(
          icon: Icons.rice_bowl_rounded,
          background: Color(0xFF151813),
          border: Color(0xFF425C18),
          accent: AppTheme.neonLime500,
          badgeBg: Color(0xFF233111),
          spotlightGlow: Color(0xFF365E13),
        );
      case 'ချင်းဟင်းလျာ':
        return const _RecipeCardPalette(
          icon: Icons.terrain_rounded,
          background: Color(0xFF141812),
          border: Color(0xFF425C18),
          accent: AppTheme.neonLime600,
          badgeBg: Color(0xFF232F10),
          spotlightGlow: Color(0xFF325712),
        );
      case 'ကချင်ဟင်းလျာ':
        return const _RecipeCardPalette(
          icon: Icons.park_rounded,
          background: Color(0xFF141914),
          border: Color(0xFF2E5B38),
          accent: Color(0xFF6EE7B7),
          badgeBg: Color(0xFF193524),
          spotlightGlow: Color(0xFF235736),
        );
      case 'ရခိုင်ဟင်းလျာ':
        return const _RecipeCardPalette(
          icon: Icons.local_fire_department_rounded,
          background: Color(0xFF171612),
          border: Color(0xFF574717),
          accent: Color(0xFFFACC15),
          badgeBg: Color(0xFF2E2610),
          spotlightGlow: Color(0xFF524011),
        );
      default:
        return const _RecipeCardPalette(
          icon: Icons.diversity_3_rounded,
          background: Color(0xFF151812),
          border: Color(0xFF405918),
          accent: AppTheme.neonLime600,
          badgeBg: Color(0xFF223010),
          spotlightGlow: Color(0xFF365E13),
        );
    }
  }

  switch (recipe.category) {
    case 'အသားဟင်း':
      return const _RecipeCardPalette(
        icon: Icons.dinner_dining_rounded,
        background: Color(0xFF151812),
        border: Color(0xFF435B18),
        accent: AppTheme.neonLime600,
        badgeBg: Color(0xFF243110),
        spotlightGlow: Color(0xFF3B6314),
      );
    case 'ငါး/ပုစွန်':
      return const _RecipeCardPalette(
        icon: Icons.set_meal_rounded,
        background: Color(0xFF13181B),
        border: Color(0xFF254D5E),
        accent: Color(0xFF38BDF8),
        badgeBg: Color(0xFF172C38),
        spotlightGlow: Color(0xFF1E4E63),
      );
    case 'အရွက်/ဟင်းရံ':
      return const _RecipeCardPalette(
        icon: Icons.eco_rounded,
        background: Color(0xFF141912),
        border: Color(0xFF4B6419),
        accent: AppTheme.neonLime600,
        badgeBg: Color(0xFF253111),
        spotlightGlow: Color(0xFF396314),
      );
    case 'အရည်သောက်':
      return const _RecipeCardPalette(
        icon: Icons.soup_kitchen_rounded,
        background: Color(0xFF151913),
        border: Color(0xFF3E5218),
        accent: AppTheme.neonLime500,
        badgeBg: Color(0xFF232E12),
        spotlightGlow: Color(0xFF325412),
      );
    default:
      return const _RecipeCardPalette(
        icon: Icons.ramen_dining_rounded,
        background: Color(0xFF151812),
        border: Color(0xFF435B18),
        accent: AppTheme.neonLime600,
        badgeBg: Color(0xFF233010),
        spotlightGlow: Color(0xFF386114),
      );
  }
}

/// Combined screen for Shopping Checklist/Budget and 82 NBK-Style Dish Photo Cards & Detailed Recipes.
class DailyMarketScreen extends StatefulWidget {
  const DailyMarketScreen({super.key, required this.viewModel});

  final DailyMarketViewModel viewModel;

  @override
  State<DailyMarketScreen> createState() => _DailyMarketScreenState();
}

class _DailyMarketScreenState extends State<DailyMarketScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.viewModel.loadAll();
    });
  }

  Future<void> _showAddShoppingItemDialog() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final dishCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ဈေးဝယ်စာရင်း ထည့်ရန်'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ဝယ်ရန်ပစ္စည်း'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'အရေအတွက် (ဥပမာ - ၅၀ ကျပ်သား / ၁ စည်း)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: costCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText:
                      'ခန့်မှန်းတန်ဖိုး (${widget.viewModel.activeCountry.currencyLabelMm})',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dishCtrl,
                decoration: const InputDecoration(
                  labelText: 'ချက်မည့်ဟင်းလျာအမည် (ရွေးချယ်နိုင်သည်)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('မလုပ်တော့'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final parsedLocal =
                  double.tryParse(normalizeAsciiDigits(costCtrl.text)) ?? 0.0;
              await widget.viewModel.addItem(
                ShoppingItem(
                  name: name,
                  quantity: qtyCtrl.text.trim(),
                  estimatedCostMmk:
                      widget.viewModel.convertLocalToMmk(parsedLocal),
                  recipeName: dishCtrl.text.trim(),
                  createdAt: DateTime.now(),
                ),
              );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('ထည့်မည်'),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    qtyCtrl.dispose();
    costCtrl.dispose();
    dishCtrl.dispose();
  }

  Future<void> _confirmAndClearChecked() async {
    final vm = widget.viewModel;
    final confirmed = await _confirmDelete(
      context,
      title: 'ဝယ်ပြီးသားစာရင်း ရှင်းမည်လား?',
      message:
          'အမှန်ခြစ်ပေးထားသော ပစ္စည်း (${vm.checkedItemCount} မျိုး) ကို လက်ရှိစာရင်းမှ ရှင်းလင်းပါမည်။ နေ့စွဲအလိုက် သိမ်းပြီးသား မှတ်တမ်းများမှာ ပျောက်သွားမည် မဟုတ်ပါ။',
      confirmLabel: 'ရှင်းမည်',
    );
    if (confirmed) {
      await vm.clearChecked();
    }
  }

  Future<void> _showCommodityPriceSheet() async {
    final vm = widget.viewModel;
    final usdCtrl = TextEditingController(
      text: vm.marketSnapshot.usdMarketMmk.toString(),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        maxChildSize: 0.92,
        builder: (context, scrollController) => ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            final commodities = vm.commodities.values.toList();
            final country = vm.activeCountry;
            final unitPrices = vm.regionalUnitPrices;
            final mmkPerUnit = RegionalMarketCatalog.mmkPerCurrencyUnit(
              country,
              vm.marketSnapshot,
            );
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(
                  '${country.flag} ${country.nameMm} ကုန်ဈေးနှုန်းနှင့် ငွေကြေးစံနှုန်း (${country.currencyCode})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  country == SupportedMarketCountry.mm
                      ? 'ဒေါ်လာ/ဘတ် ငွေလဲနှုန်း အတက်အကျ သို့မဟုတ် ၁ ပိဿာချင်းစီရဲ့ ပေါက်ဈေးကို ပြင်လိုက်တာနဲ့ ဟင်းလျာ (${vm.recipes.length}) မျိုးလုံးရဲ့ ကျသင့်ငွေတွေ အလိုအလျောက် ပြောင်းလဲတွက်ချက်ပေးပါတယ်။'
                      : '${country.unitBasisNoteMm} • 1 ${country.currencyCode} ≈ ${formatMmk(mmkPerUnit.round())} ဖြင့် ဟင်းလျာ (${vm.recipes.length}) မျိုးလုံးကို ${country.currencyLabelMm} ဖြင့် တွက်ချက်ပြသထားပါသည်။',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (country == SupportedMarketCountry.mm) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: usdCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'လက်ရှိ 1 USD ပြင်ပပေါက်ဈေး (ကျပ်)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () async {
                          final val = int.tryParse(
                            normalizeAsciiDigits(usdCtrl.text),
                          );
                          if (val != null && val > 500) {
                            await vm.updateUsdMarketRate(val);
                          }
                        },
                        icon: const Icon(Icons.sync, size: 18),
                        label: const Text('နှုန်းချိန်မည်'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                ...commodities.map(
                  (c) {
                    final localPrice =
                        unitPrices[c.id] ?? c.currentPriceMmk.toDouble();
                    final unitLabel = country == SupportedMarketCountry.mm
                        ? '${c.unitLabelMm} ပေါက်ဈေး'
                        : '${c.unitLabelMm} (သို့မဟုတ်) ဒေသစံနှုန်း';
                    return Card(
                      child: ListTile(
                        title: Text(
                          c.nameMm,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(unitLabel),
                        trailing: TextButton.icon(
                          onPressed: () => _editSingleCommodityDialog(c),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: Text(
                            vm.formatLocalAmount(localPrice),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
    usdCtrl.dispose();
  }

  Future<void> _editSingleCommodityDialog(CommodityPrice commodity) async {
    final vm = widget.viewModel;
    final country = vm.activeCountry;
    final currentLocal =
        vm.regionalUnitPrices[commodity.id] ?? commodity.currentPriceMmk.toDouble();
    final ctrl = TextEditingController(
      text: country.decimalPlaces > 0
          ? currentLocal.toStringAsFixed(country.decimalPlaces)
          : currentLocal.round().toString(),
    );
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${country.flag} ${commodity.nameMm} (${commodity.unitLabelMm})'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.numberWithOptions(
            decimal: country.decimalPlaces > 0,
          ),
          decoration: InputDecoration(
            labelText: '${country.nameMm} ပေါက်ဈေး (${country.currencyLabelMm})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('မလုပ်တော့'),
          ),
          FilledButton(
            onPressed: () async {
              final next = double.tryParse(normalizeAsciiDigits(ctrl.text));
              if (next != null && next > 0) {
                await vm.updateActiveRegionalCommodityPrice(commodity.id, next);
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('သိမ်းမည်'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'အိမ်တွင်းရေး',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (vm.activeSection == DailySection.recipes)
                IconButton(
                  tooltip: 'ပေါက်ဈေးဇယား ပြင်ရန်',
                  onPressed: _showCommodityPriceSheet,
                  icon: const Icon(Icons.price_change_outlined),
                ),
              if (vm.activeSection == DailySection.shopping &&
                  vm.items.any((i) => i.isChecked))
                IconButton(
                  tooltip: 'ဝယ်ပြီးသားစာရင်း ရှင်းရန်',
                  onPressed: _confirmAndClearChecked,
                  icon: const Icon(Icons.cleaning_services_outlined),
                ),
            ],
          ),
          floatingActionButton: vm.activeSection == DailySection.shopping
              ? FloatingActionButton.extended(
                  onPressed: _showAddShoppingItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('ပစ္စည်းထည့်'),
                )
              : null,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<DailySection>(
                    segments: [
                      ButtonSegment(
                        value: DailySection.recipes,
                        label: Text('ဟင်းချက်အစီအစဉ် (${vm.recipes.length})'),
                      ),
                      ButtonSegment(
                        value: DailySection.shopping,
                        label: Text('ဈေးဝယ်စာရင်း (${vm.items.length})'),
                      ),
                    ],
                    selected: {vm.activeSection},
                    onSelectionChanged: (set) =>
                        vm.setActiveSection(set.first),
                  ),
                ),
              ),
              Expanded(
                child: vm.activeSection == DailySection.shopping
                    ? _ShoppingSection(
                        viewModel: vm,
                        onClearChecked: _confirmAndClearChecked,
                      )
                    : _RecipesSection(
                        viewModel: vm,
                        onOpenPriceSheet: _showCommodityPriceSheet,
                        onEditCommodity: _editSingleCommodityDialog,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'ဖျက်မည်',
  String cancelLabel = 'မဖျက်တော့ပါ (Cancel)',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF141812),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF394624), width: 1.2),
      ),
      icon: const Icon(
        Icons.delete_forever_rounded,
        color: Color(0xFFF87171),
        size: 32,
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(
        message,
        style: const TextStyle(height: 1.45, color: AppTheme.gray200),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _ShoppingSection extends StatelessWidget {
  const _ShoppingSection({
    required this.viewModel,
    required this.onClearChecked,
  });

  final DailyMarketViewModel viewModel;
  final VoidCallback onClearChecked;

  Future<void> _confirmAndDeleteShoppingItem(
    BuildContext context,
    ShoppingItem item,
  ) async {
    final id = item.id;
    if (id == null) return;
    final confirmed = await _confirmDelete(
      context,
      title: 'စာရင်းမှ ဖျက်မည်လား?',
      message:
          '“${item.name}” ကို လက်ရှိဈေးဝယ်စာရင်းမှ ဖျက်ပစ်မည်လား? နေ့စွဲအလိုက် သိမ်းပြီးသား မှတ်တမ်းများကို မထိခိုက်ပါ။',
    );
    if (confirmed) {
      await viewModel.deleteItem(id);
    }
  }

  Future<void> _confirmAndDeleteRecord(
    BuildContext context,
    DailyPurchaseRecord record,
  ) async {
    final dateLabel = formatBurmeseFullDate(record.recordDate);
    final confirmed = await _confirmDelete(
      context,
      title: 'ဈေးဝယ်မှတ်တမ်း ဖျက်မည်လား?',
      message:
          '“$dateLabel” နေ့စွဲ မှတ်တမ်း (ပစ္စည်း ${record.itemCount} မျိုး • စုစုပေါင်း ${viewModel.formatCostFromMmk(record.totalCostMmk)}) ကို အပြီးဖျက်မည်လား?\n\nဖျက်ပြီးပါက ပြန်ယူ၍ မရနိုင်ပါ။',
    );
    if (confirmed) {
      await viewModel.deletePurchaseRecord(record);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('“$dateLabel” မှတ်တမ်းကို ဖျက်ပြီးပါပြီ')),
        );
      }
    }
  }

  Future<void> _showPurchaseRecordDetailSheet(
    BuildContext context,
    String dateKey,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF10130E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (context, scrollController) => ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final idx =
                viewModel.purchaseRecords.indexWhere((r) => r.dateKey == dateKey);
            if (idx == -1) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('ဤနေ့စွဲ မှတ်တမ်းကို ဖျက်ပြီးဖြစ်ပါသည်'),
                ),
              );
            }
            final record = viewModel.purchaseRecords[idx];
            final dateLabel = formatBurmeseFullDate(record.recordDate);
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.olive900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.neonLime600),
                      ),
                      child: const Icon(
                        Icons.event_note_rounded,
                        color: AppTheme.neonLime600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15.5,
                              color: AppTheme.white100,
                            ),
                          ),
                          Text(
                            'ဝယ်ယူခဲ့သော ပစ္စည်း ${record.itemCount} မျိုး မှတ်တမ်း',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.gray200,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'ဤနေ့မှတ်တမ်း ဖျက်ရန်',
                      onPressed: () async {
                        final ok = await _confirmDelete(
                          context,
                          title: 'ဈေးဝယ်မှတ်တမ်း ဖျက်မည်လား?',
                          message:
                              '“$dateLabel” နေ့စွဲ မှတ်တမ်း (ပစ္စည်း ${record.itemCount} မျိုး • စုစုပေါင်း ${viewModel.formatCostFromMmk(record.totalCostMmk)}) ကို ဖျက်မည်လား?',
                        );
                        if (ok) {
                          await viewModel.deletePurchaseRecord(record);
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFF87171),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171E10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.neonLime600, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ထိုနေ့ စုစုပေါင်းသုံးငွေ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.gray200,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ဝယ်ပြီးသားစာရင်းအားလုံး စုစုပေါင်း',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.gray400,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        viewModel.formatCostFromMmk(record.totalCostMmk),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.neonLime600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (record.dishNames.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'ချက်ပြုတ် / စီစဉ်ထားသော ဟင်းလျာများ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: AppTheme.neonLime500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: record.dishNames
                        .map(
                          (dish) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.olive900,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppTheme.neonLime600),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.restaurant_menu_rounded,
                                  size: 14,
                                  color: AppTheme.neonLime600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  dish,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.white100,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'ဝယ်ယူခဲ့သော ပစ္စည်းအသေးစိတ် (${record.itemCount} မျိုး)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppTheme.white100,
                  ),
                ),
                const SizedBox(height: 8),
                ...record.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final line = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151913),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF283319)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.olive900,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.neonLime600),
                          ),
                          child: Text(
                            '$idx',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.neonLime600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppTheme.white100,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (line.quantity.isNotEmpty) line.quantity,
                                  if (line.recipeName.isNotEmpty)
                                    'ဟင်း: ${line.recipeName}',
                                  'ဝယ်ချိန် ${formatTimeShort(line.purchasedAt)}',
                                ].join(' • '),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.gray200,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (line.costMmk > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.olive900,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              viewModel.formatCostFromMmk(line.costMmk),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppTheme.neonLime600,
                              ),
                            ),
                          ),
                        IconButton(
                          tooltip: 'ဤပစ္စည်း ဖျက်ရန်',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 19,
                            color: AppTheme.gray200,
                          ),
                          onPressed: () async {
                            final ok = await _confirmDelete(
                              context,
                              title: 'မှတ်တမ်းပစ္စည်း ဖျက်မည်လား?',
                              message:
                                  '“${line.name}” ကို $dateLabel မှတ်တမ်းမှ ဖျက်မည်လား?',
                            );
                            if (ok) {
                              await viewModel.deletePurchaseLineItem(
                                record,
                                line.entryKey,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkedCount = viewModel.checkedItemCount;
    final records = viewModel.purchaseRecords;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF171E10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.neonLime600, width: 1.3),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ဝယ်ရန်ကျန် ခန့်မှန်းဘတ်ဂျက်'),
                      Text(
                        viewModel.formatCostFromMmk(
                          viewModel.remainingEstimatedBudgetMmk,
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.neonLime600,
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('စုစုပေါင်း ခန့်မှန်း'),
                      Text(
                        viewModel.formatCostFromMmk(
                          viewModel.totalEstimatedBudgetMmk,
                        ),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              if (checkedCount > 0) ...[
                const Divider(height: 18, color: Color(0xFF2D3A1B)),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.neonLime600,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ဝယ်ပြီးသား ($checkedCount မျိုး) ကို ယနေ့မှတ်တမ်းထဲ ထည့်သွင်းပြီးပါပြီ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.neonLime500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onClearChecked,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        foregroundColor: AppTheme.neonLime600,
                      ),
                      child: const Text(
                        'ပြီးသားရှင်း',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (viewModel.items.isEmpty)
          const EmptyStateCard(
            icon: Icons.shopping_cart_outlined,
            title: 'ဈေးဝယ်စာရင်း မရှိသေးပါ',
            subtitle:
                'ကိုယ်တိုင်ထည့်နိုင်သလို ဟင်းချက်အစီအစဉ် Tab မှ ဟင်းပုံကတ်များကို နှိပ်၍ ဝယ်ရမည့်ပစ္စည်းများကို တိုက်ရိုက်ထည့်နိုင်ပါသည်။',
          )
        else
          ...viewModel.items.map(
            (item) => Card(
              child: ListTile(
                leading: Checkbox(
                  value: item.isChecked,
                  onChanged: (_) => viewModel.toggleItem(item),
                ),
                title: Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    decoration:
                        item.isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: (item.quantity.isEmpty && item.recipeName.isEmpty)
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (item.quantity.isNotEmpty) Text(item.quantity),
                            if (item.recipeName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F2B11),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFF3E551C),
                                  ),
                                ),
                                child: Text(
                                  item.recipeName,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.neonLime500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.estimatedCostMmk > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.olive900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '≈ ${viewModel.formatCostFromMmk(item.estimatedCostMmk)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.neonLime600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: 'စာရင်းမှ ဖျက်ရန်',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: item.id == null
                          ? null
                          : () => _confirmAndDeleteShoppingItem(context, item),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 22),

        // Date-Grouped Purchase History Section directly beneath Shopping Checklist
        Row(
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              color: AppTheme.neonLime600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'နေ့စွဲအလိုက် ဈေးဝယ်မှတ်တမ်းများ (${records.length} ရက်)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.white100,
                    ),
              ),
            ),
            if (records.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.olive900,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.neonLime600),
                ),
                child: Text(
                  viewModel.formatCostFromMmk(viewModel.totalRecordedSpendMmk),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.neonLime600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'ဈေးဝယ်စာရင်းထဲမှ ပစ္စည်းများကို ဝယ်ပြီးကြောင်း အမှန်ခြစ်ပေးလိုက်သည်နှင့် နေ့စွဲအလိုက် မှတ်တမ်းအဖြစ် အလိုအလျောက် စုစည်းသိမ်းဆည်းပေးပါသည်။ နှိပ်ကြည့်ပါက ထိုနေ့ဝယ်ခဲ့သည့် ဟင်းလျာနှင့် ပစ္စည်းအသေးစိတ်ကို ပြသပါမည်။',
          style: TextStyle(fontSize: 12, color: AppTheme.gray200, height: 1.4),
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF141812),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF283319)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.history_toggle_off_rounded,
                  color: AppTheme.gray400,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ဝယ်ယူပြီးသား မှတ်တမ်း မရှိသေးပါ — အပေါ်ရှိ ဈေးဝယ်စာရင်းမှ ဝယ်ပြီးသည့် ပစ္စည်းများကို အမှန်ခြစ်ပေးလိုက်ပါ။',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.gray200,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...records.map(
            (record) => _PurchaseRecordCard(
              record: record,
              formattedTotal: viewModel.formatCostFromMmk(record.totalCostMmk),
              onTap: () =>
                  _showPurchaseRecordDetailSheet(context, record.dateKey),
              onDeleteTap: () => _confirmAndDeleteRecord(context, record),
            ),
          ),
      ],
    );
  }
}

class _PurchaseRecordCard extends StatelessWidget {
  const _PurchaseRecordCard({
    required this.record,
    required this.formattedTotal,
    required this.onTap,
    required this.onDeleteTap,
  });

  final DailyPurchaseRecord record;
  final String formattedTotal;
  final VoidCallback onTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final dateTitle = formatBurmeseFullDate(record.recordDate);
    final previewItems = record.items.take(4).map((e) => e.name).toList();
    final extraCount = record.items.length - previewItems.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF141812),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF33431D), width: 1.1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.olive900,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.neonLime600),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: AppTheme.neonLime600,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppTheme.white100,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ဝယ်ယူပြီး ပစ္စည်း ${record.itemCount} မျိုး',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.gray200,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'မှတ်တမ်းဖျက်ရန်',
                    onPressed: onDeleteTap,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFF87171),
                    ),
                  ),
                ],
              ),
              if (record.dishNames.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: record.dishNames
                      .map(
                        (dish) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2A11),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF476321)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.restaurant_menu_rounded,
                                size: 12,
                                color: AppTheme.neonLime600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dish,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.neonLime500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (previewItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  extraCount > 0
                      ? '${previewItems.join(' • ')} • +$extraCount မျိုး'
                      : previewItems.join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.gray200,
                    height: 1.35,
                  ),
                ),
              ],
              const Divider(height: 18, color: Color(0xFF262E1D)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'စုစုပေါင်းသုံးငွေ: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.gray200,
                        ),
                      ),
                      Text(
                        formattedTotal,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.neonLime600,
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'အသေးစိတ်ကြည့်ရန်',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.neonLime500,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppTheme.neonLime500,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipesSection extends StatelessWidget {
  const _RecipesSection({
    required this.viewModel,
    required this.onOpenPriceSheet,
    required this.onEditCommodity,
  });

  final DailyMarketViewModel viewModel;
  final VoidCallback onOpenPriceSheet;
  final void Function(CommodityPrice) onEditCommodity;

  Future<void> _handleAddRecipeToMarket(
    BuildContext context,
    Recipe dish,
  ) async {
    final totalLocal = viewModel.recipeCostLocal(dish);
    await viewModel.addRecipeIngredientsToChecklist(dish);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${dish.name} ဝယ်ရမည့်ပစ္စည်းများ (≈ ${viewModel.formatLocalAmount(totalLocal)}) ကို ဈေးဝယ်စာရင်းထဲ ထည့်ပြီးပါပြီ',
          ),
          action: SnackBarAction(
            label: 'စာရင်းကြည့်မည်',
            onPressed: () => viewModel.setActiveSection(DailySection.shopping),
          ),
        ),
      );
    }
  }

  Future<void> _showRecipeDetailSheet(
    BuildContext context,
    Recipe recipe,
  ) async {
    final palette = _paletteForRecipe(recipe);
    final commodities = viewModel.commodities;
    final totalLocal = viewModel.recipeCostLocal(recipe);
    final tierLabel = recipe.budgetTierLabelMm(commodities);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF10130E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Drag handle + Close header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.olive900,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.neonLime600),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(palette.icon, size: 14, color: AppTheme.neonLime600),
                      const SizedBox(width: 6),
                      Text(
                        recipe.ethnicGroup.isNotEmpty
                            ? recipe.ethnicGroup
                            : recipe.category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.neonLime600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'ပိတ်မည်',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Large NBK Spotlight Dish Photo Header Card
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.95,
                  colors: [
                    palette.spotlightGlow,
                    const Color(0xFF151C0E),
                    const Color(0xFF0D100A),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.neonLime600, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 210,
                          width: double.infinity,
                          child: _DishPhotoWidget(
                            recipe: recipe,
                            palette: palette,
                            iconSize: 56,
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.neonLime600,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              'OVR ${recipe.ratingScore}',
                              style: const TextStyle(
                                color: AppTheme.obsidian1000,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppTheme.neonLime600),
                            ),
                            child: Text(
                              '⏱ ချက်ချိန် ${recipe.prepMinutes} မိနစ် • $tierLabel',
                              style: const TextStyle(
                                color: AppTheme.white100,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                recipe.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.white100,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF233210),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.neonLime600,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                '${recipe.ratingScore}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.neonLime600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              palette.icon,
                              size: 14,
                              color: AppTheme.neonLime600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${recipe.prepMinutes} မိနစ် • ပစ္စည်း ${recipe.ingredients.length} မျိုး',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.gray200,
                              ),
                            ),
                          ],
                        ),
                        if (recipe.flavorProfileMm.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'အရသာပုံစံ - ${recipe.flavorProfileMm}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.neonLime500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // NBK Stat Bars (shown cleanly upon tapping card)
                        _NbkStatBar(label: 'အရသာ', value: recipe.tasteStat),
                        const SizedBox(height: 6),
                        _NbkStatBar(
                          label: 'လွယ်ကူမှု',
                          value: recipe.speedStat,
                        ),
                        const SizedBox(height: 6),
                        _NbkStatBar(
                          label: 'ချွေတာမှု',
                          value: recipe.valueStat(commodities),
                        ),
                        const SizedBox(height: 12),
                        _NbkMetaRow(
                          label: 'ဒေသ/အုပ်စု',
                          value: recipe.ethnicGroup.isNotEmpty
                              ? recipe.ethnicGroup
                              : recipe.category,
                        ),
                        _NbkMetaRow(
                          label: 'ချက်နည်း',
                          value: 'အဆင့် (${recipe.steps.length}) ဆင့်',
                        ),
                        const Divider(height: 18, color: Color(0xFF2B381B)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Est. price (ခန့်မှန်းကုန်ကျငွေ)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppTheme.gray200,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.monetization_on_rounded,
                                  color: AppTheme.neonLime600,
                                  size: 18,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '≈ ${viewModel.formatLocalAmount(totalLocal)}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.neonLime600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await _handleAddRecipeToMarket(context, recipe);
                            },
                            icon: const Icon(Icons.add_shopping_cart_rounded),
                            label: const Text('ချက်နည်း / ဈေးဝယ်စာရင်းထဲ ထည့်မည်'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // SECTION 1: ဝယ်ရမည့် ပါဝင်ပစ္စည်းများနှင့် ပေါက်ဈေးစာရင်း
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161914),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2D381E), width: 1.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.olive900,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.shopping_basket_rounded,
                          color: AppTheme.neonLime600,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ဝယ်ရမည့် ပါဝင်ပစ္စည်းများ (${recipe.ingredients.length} မျိုး)',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.white100,
                                  ),
                            ),
                            Text(
                              '${viewModel.activeCountry.flag} ${viewModel.activeCountry.nameMm} (${viewModel.activeCountry.currencyCode}) လက်ရှိဈေးနှုန်းဖြင့် တွက်ချက်ထားပါသည်',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.gray200,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...recipe.ingredients.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final ing = entry.value;
                    final itemCost = viewModel.ingredientCostLocal(ing);
                    final unitRate = viewModel.ingredientUnitSummaryLocal(ing);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10130E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF283319)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.olive900,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.neonLime600),
                            ),
                            child: Text(
                              '$idx',
                              style: const TextStyle(
                                color: AppTheme.neonLime600,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${ing.name} (${ing.amount})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppTheme.white100,
                                  ),
                                ),
                                if (unitRate.isNotEmpty)
                                  Text(
                                    unitRate,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.gray200,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.olive900,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '≈ ${viewModel.formatLocalAmount(itemCost)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: AppTheme.neonLime600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        await _handleAddRecipeToMarket(context, recipe);
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: Text(
                        'ဝယ်ရမည့်ပစ္စည်းအားလုံး ဈေးဝယ်စာရင်းထဲ ထည့်မည် (≈ ${viewModel.formatLocalAmount(totalLocal)})',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // SECTION 2: အသေးစိတ် ရိုးရာချက်ပြုတ်နည်း အဆင့်ဆင့်
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161914),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.neonLime600, width: 1.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.olive900,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: AppTheme.neonLime600,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'အသေးစိတ် ရိုးရာချက်ပြုတ်နည်း အဆင့်ဆင့် (${recipe.steps.length} ဆင့်)',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.neonLime500,
                                  ),
                            ),
                            Text(
                              '${recipe.name} ကို အရသာစစ်စစ် ရရှိအောင် အဆင့်ဆင့် ချက်ပြုတ်နည်း',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.gray200,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...recipe.steps.asMap().entries.map((e) {
                    final stepNum = e.key + 1;
                    final stepText = e.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10130E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2B381B)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.neonLime600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'အဆင့် $stepNum',
                              style: const TextStyle(
                                color: AppTheme.obsidian1000,
                                fontWeight: FontWeight.w900,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              stepText,
                              style: const TextStyle(
                                fontSize: 13.8,
                                height: 1.5,
                                color: AppTheme.white100,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (recipe.chefTipMm.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D2811),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.neonLime600),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.tips_and_updates_rounded,
                            color: AppTheme.neonLime600,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'စားဖိုမှူး အကြံပြုချက် - ${recipe.chefTipMm}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.neonLime500,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final generalRecipes = viewModel.filteredGeneralRecipes;
    final ethnicRecipes = viewModel.filteredEthnicRecipes;
    final snap = viewModel.marketSnapshot;
    final country = viewModel.activeCountry;
    final ipInfo = viewModel.ipLocation;
    final regionalPrices = viewModel.regionalUnitPrices;
    final keyStaples = [
      'chicken',
      'onion',
      'potato',
      'cooking_oil',
      'pork',
      'fish_general',
      'seafood_squid',
      'bamboo_shoot',
      'egg_chicken',
      'tomato',
    ]
        .map((id) => viewModel.commodities[id])
        .whereType<CommodityPrice>()
        .toList();

    final locationBannerText = viewModel.isAutoIpMode
        ? (ipInfo?.statusSummaryMm ??
            '${country.flag} ${country.nameMm} (${country.currencyCode})')
        : '${country.flag} ${country.nameMm} ဈေးနှုန်း (${country.currencyCode}) • ${snap.sourceNote}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Live IP Location, 6-Country Market Currency & Commodity Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF171E10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.neonLime600, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: snap.isOnlineLive
                          ? AppTheme.neonLime600
                          : const Color(0xFFFACC15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          viewModel.isAutoIpMode
                              ? Icons.my_location_rounded
                              : (snap.isOnlineLive
                                  ? Icons.cloud_done_rounded
                                  : Icons.public_rounded),
                          size: 13,
                          color: AppTheme.obsidian1000,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${country.flag} ${country.currencyCode}',
                          style: const TextStyle(
                            color: AppTheme.obsidian1000,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locationBannerText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.neonLime500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'IP တည်နေရာဖြင့် အလိုအလျောက်ရှာမည်',
                    onPressed: viewModel.isDetectingLocation
                        ? null
                        : viewModel.refreshIpLocation,
                    icon: viewModel.isDetectingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: AppTheme.neonLime600,
                            size: 19,
                          ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Online ပေါက်ဈေး Sync လုပ်ရန်',
                    onPressed: viewModel.isSyncingOnline
                        ? null
                        : viewModel.syncOnlinePrices,
                    icon: viewModel.isSyncingOnline
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            color: AppTheme.neonLime600,
                          ),
                  ),
                  TextButton(
                    onPressed: onOpenPriceSheet,
                    child: const Text('ပေါက်ဈေးပြင်ရန်'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Strictly 6 supported regional markets + Auto IP mode
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: const Text('📍 Auto (IP)'),
                        selected: viewModel.isAutoIpMode,
                        onSelected: (_) =>
                            viewModel.setCountrySelection('auto'),
                      ),
                    ),
                    ...SupportedMarketCountry.values.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('${c.flag} ${c.nameMm} (${c.currencyCode})'),
                          selected:
                              !viewModel.isAutoIpMode && viewModel.activeCountry == c,
                          onSelected: (_) =>
                              viewModel.setCountrySelection(c.isoCode),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: keyStaples
                      .map(
                        (c) {
                          final localPrice =
                              regionalPrices[c.id] ?? c.currentPriceMmk.toDouble();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              backgroundColor: const Color(0xFF1F2812),
                              side: const BorderSide(color: AppTheme.olive800),
                              label: Text(
                                '${c.nameMm} (${c.unitLabelMm}): ${viewModel.formatLocalAmount(localPrice)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.neonLime500,
                                ),
                              ),
                              onPressed: () => onEditCommodity(c),
                            ),
                          );
                        },
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: viewModel.setSearchQuery,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText:
                'ဟင်းအမည် ရှာရန် (ဥပမာ - ထားဝယ် မုန့်လက်ဆွဲ၊ ရှမ်း၊ ချင်း၊ ကြက်သား)',
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: viewModel.recipeCategories
                .map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        cat == 'တိုင်းရင်းသားဟင်းလျာများ'
                            ? 'တိုင်းရင်းသားဟင်းလျာများ (${viewModel.totalEthnicRecipeCount})'
                            : cat,
                      ),
                      selected: viewModel.selectedCategory == cat,
                      onSelected: (_) => viewModel.setCategory(cat),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),

        // 1. Dedicated "တိုင်းရင်းသားဟင်းလျာများ" Section FIRST (Featuring Dawei Mont Lat Swel/Thoke, Shan, Chin, Kachin, Rakhine, Mon, Karen, Kayah)
        if (viewModel.selectedCategory == 'အားလုံး' ||
            viewModel.selectedCategory == 'တိုင်းရင်းသားဟင်းလျာများ' ||
            (viewModel.selectedCategory == 'ချွေတာရေး' &&
                ethnicRecipes.isNotEmpty)) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A2310), Color(0xFF11150E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.neonLime600, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.olive900,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.diversity_3_rounded,
                        color: AppTheme.neonLime600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'တိုင်းရင်းသား ရိုးရာဟင်းလျာကတ်များ (${ethnicRecipes.length} မျိုး)',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.white100,
                                ),
                          ),
                          const Text(
                            'ဟင်းပုံကတ်ကို နှိပ်၍ ဝယ်ရမည့်ပစ္စည်းများနှင့် အသေးစိတ်ရိုးရာချက်နည်းကို ကြည့်ပါ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.neonLime500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: viewModel.ethnicGroups
                        .map(
                          (grp) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(grp),
                              selected: viewModel.selectedEthnicGroup == grp,
                              onSelected: (_) => viewModel.setEthnicGroup(grp),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          _NbkRecipeGrid(
            recipes: ethnicRecipes,
            onTapRecipe: (dish) => _showRecipeDetailSheet(context, dish),
          ),
          const SizedBox(height: 18),
        ],

        // 2. General Myanmar Dishes in clean Photo + Name Grid
        if (generalRecipes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 18,
                  color: AppTheme.neonLime600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'မြန်မာရိုးရာ နေ့စဉ်ဟင်းလျာကတ်များ (${generalRecipes.length} မျိုး)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.neonLime500,
                        ),
                  ),
                ),
              ],
            ),
          ),
          _NbkRecipeGrid(
            recipes: generalRecipes,
            onTapRecipe: (dish) => _showRecipeDetailSheet(context, dish),
          ),
          const SizedBox(height: 12),
        ],
        const _QuietOtherToolsFooter(),
      ],
    );
  }
}

class _QuietOtherToolsFooter extends StatelessWidget {
  const _QuietOtherToolsFooter();

  void _openQuietTool(
    BuildContext context,
    String route, {
    ToolsSection? section,
  }) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    if (section != null) {
      try {
        context.read<RemindersQrViewModel>().setActiveSection(section);
      } catch (_) {}
    }
    router.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121511),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF232821)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'အခြား အသုံးအဆောင်များ (လိုအပ်မှ နှိပ်ကြည့်ရန်)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.gray200,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _QuietFooterChip(
                icon: Icons.calculate_outlined,
                label: 'စာရင်း/တွက်စက်',
                onTap: () => _openQuietTool(context, '/finance'),
              ),
              _QuietFooterChip(
                icon: Icons.directions_car_outlined,
                label: 'ယာဉ်/စာရွက် Reminder',
                onTap: () => _openQuietTool(
                  context,
                  '/tools',
                  section: ToolsSection.reminders,
                ),
              ),
              _QuietFooterChip(
                icon: Icons.qr_code_2_outlined,
                label: 'Offline QR & Backup',
                onTap: () => _openQuietTool(
                  context,
                  '/tools',
                  section: ToolsSection.qrCard,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuietFooterChip extends StatelessWidget {
  const _QuietFooterChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      backgroundColor: const Color(0xFF181C16),
      side: const BorderSide(color: Color(0xFF2B3128)),
      avatar: Icon(icon, size: 14, color: AppTheme.gray200),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.gray200,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onTap,
    );
  }
}

/// Responsive grid of compact Photo + Name dish cards (expands on tap).
class _NbkRecipeGrid extends StatelessWidget {
  const _NbkRecipeGrid({
    required this.recipes,
    required this.onTapRecipe,
  });

  final List<Recipe> recipes;
  final void Function(Recipe) onTapRecipe;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : (constraints.maxWidth >= 580 ? 3 : 2);
        final rows = <Widget>[];
        for (var i = 0; i < recipes.length; i += crossAxisCount) {
          final rowChildren = <Widget>[];
          for (var col = 0; col < crossAxisCount; col++) {
            if (col > 0) rowChildren.add(const SizedBox(width: 10));
            final index = i + col;
            rowChildren.add(
              Expanded(
                child: index < recipes.length
                    ? _NbkRecipeCard(
                        recipe: recipes[index],
                        onTap: () => onTapRecipe(recipes[index]),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rowChildren,
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}

/// Compact Dish Card showing only Photo + Dish Name on the main screen;
/// tapping expands into the full NBK detail UI.
class _NbkRecipeCard extends StatelessWidget {
  const _NbkRecipeCard({
    required this.recipe,
    required this.onTap,
  });

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForRecipe(recipe);

    return Material(
      color: const Color(0xFF151813),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Clean Dish Photo Frame (zero badges/buttons on outside card)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.15),
                        radius: 0.9,
                        colors: [
                          palette.spotlightGlow,
                          const Color(0xFF17240D),
                          const Color(0xFF0E120B),
                        ],
                      ),
                    ),
                    child: _DishPhotoWidget(
                      recipe: recipe,
                      palette: palette,
                      iconSize: 36,
                    ),
                  ),
                ),
              ),

              // 2. Dish Name Only
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 36),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        height: 1.3,
                        color: AppTheme.white100,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NbkStatBar extends StatelessWidget {
  const _NbkStatBar({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.gray200,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (value / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFF262D1F),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.neonLime600),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 24,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.white100,
            ),
          ),
        ),
      ],
    );
  }
}

class _NbkMetaRow extends StatelessWidget {
  const _NbkMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.gray200,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.white100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DishPhotoWidget extends StatelessWidget {
  const _DishPhotoWidget({
    required this.recipe,
    required this.palette,
    required this.iconSize,
  });

  final Recipe recipe;
  final _RecipeCardPalette palette;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      recipe.resolvedImageAsset,
      fit: BoxFit.cover,
      cacheWidth: iconSize <= 48 ? 640 : 800,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            palette.icon,
            size: iconSize,
            color: AppTheme.neonLime600,
          ),
        );
      },
    );
  }
}
