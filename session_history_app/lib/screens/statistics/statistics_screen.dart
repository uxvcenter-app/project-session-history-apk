import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/session_provider.dart';

/// Écran Statistics : vue d'ensemble façon "dashboard" — carte principale
/// (total), deux indicateurs secondaires, répartition par catégorie
/// (donut) et activité des 7 derniers jours (barres), avec pull-to-refresh.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadSessions();
    });
  }

  /// Labels réels des 7 derniers jours (se terminant aujourd'hui). Avant,
  /// le graphique affichait toujours "Mon...Sun" en dur, ce qui ne
  /// correspondait pas vraiment aux 7 derniers jours sauf un dimanche.
  List<String> _lastSevenDayLabels() {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - i));
      return _dayLabels[day.weekday - 1];
    });
  }

  String _topCategorySubtitle(Map<String, int> counts, int total) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final pct = (top.value / total * 100).round();
    return '${CategoryModel.byId(top.key).name} leads with $pct%';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final sessions = context.watch<SessionProvider>();
    final total = sessions.totalCount;
    final counts = sessions.categoryCounts();
    final weekCounts = sessions.lastSevenDaysCounts();
    final dayLabels = _lastSevenDayLabels();
    final showFullPageLoader = sessions.isLoading && total == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Statistics')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<SessionProvider>().loadSessions(),
        child: showFullPageLoader
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 220),
                  Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _heroCard(total),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _miniStat(
                          icon: Icons.calendar_month_outlined,
                          label: 'This Month',
                          value: '${sessions.thisMonthCount()}',
                          accent: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _miniStat(
                          icon: Icons.star,
                          label: 'Favorites',
                          value: '${sessions.favoritesCount}',
                          accent: AppColors.star,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  _sectionHeader(
                    Icons.pie_chart_outline,
                    'Sessions by Category',
                    subtitle: total == 0 ? null : _topCategorySubtitle(counts, total),
                  ),
                  const SizedBox(height: 14),
                  total == 0
                      ? _emptyState(Icons.pie_chart_outline, 'Pas encore de données')
                      : _categoryCard(counts, total),

                  const SizedBox(height: 28),
                  _sectionHeader(
                    Icons.bar_chart_outlined,
                    'Sessions Over Time',
                    subtitle: 'Last 7 days',
                  ),
                  const SizedBox(height: 14),
                  _weeklyCard(weekCounts, dayLabels),
                  const SizedBox(height: 12),
                ],
              ),
      ),
    );
  }

  Widget _heroCard(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.32),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.history_edu, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Sessions',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accent, size: 17),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 23),
            child: Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Column(
          children: [
            Icon(icon, size: 30, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(message, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard(Map<String, int> counts, int total) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sorted.map((e) {
                      final cat = CategoryModel.byId(e.key);
                      return PieChartSectionData(
                        value: e.value.toDouble(),
                        color: cat.color,
                        radius: 22,
                        title: '',
                      );
                    }).toList(),
                    sectionsSpace: 3,
                    centerSpaceRadius: 42,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    Text('sessions', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sorted.map((e) {
                final cat = CategoryModel.byId(e.key);
                final pct = e.value / total * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${e.value}',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${pct.toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weeklyCard(List<int> weekCounts, List<String> dayLabels) {
    final peak = weekCounts.isEmpty ? 0 : weekCounts.reduce((a, b) => a > b ? a : b);
    final maxY = (peak < 3 ? 5 : peak + 2).toDouble();
    final todayIndex = weekCounts.length - 1;

    return _card(
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, meta) {
                    if (v == 0 || v != v.roundToDouble()) return const SizedBox.shrink();
                    return Text('${v.toInt()}', style: TextStyle(fontSize: 11, color: AppColors.textSecondary));
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 || i >= dayLabels.length) return const SizedBox.shrink();
                    final isToday = i == todayIndex;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        dayLabels[i],
                        style: TextStyle(
                          fontSize: 11,
                          color: isToday ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => AppColors.primaryDark,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final n = rod.toY.toInt();
                  return BarTooltipItem(
                    '$n session${n > 1 ? 's' : ''}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  );
                },
              ),
            ),
            barGroups: List.generate(weekCounts.length, (i) {
              final isToday = i == todayIndex;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: weekCounts[i].toDouble(),
                  gradient: isToday
                      ? const LinearGradient(
                          colors: AppColors.primaryGradient,
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        )
                      : null,
                  color: isToday ? null : AppColors.primary.withOpacity(0.28),
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}