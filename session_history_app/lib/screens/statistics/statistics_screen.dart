import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/session_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final sessions = context.watch<SessionProvider>();
    final counts = sessions.categoryCounts();
    final total = sessions.totalCount;
    final weekCounts = sessions.lastSevenDaysCounts();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: _statBox('Total Sessions', '$total')),
              const SizedBox(width: 12),
              Expanded(child: _statBox('This Month', '${sessions.thisMonthCount()}')),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Sessions by Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('Pas encore de données', style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: counts.entries.map((e) {
                          final cat = CategoryModel.byId(e.key);
                          final pct = (e.value / total * 100);
                          return PieChartSectionData(
                            value: e.value.toDouble(),
                            color: cat.color,
                            title: '${pct.toStringAsFixed(0)}%',
                            radius: 55,
                            titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: counts.entries.map((e) {
                        final cat = CategoryModel.byId(e.key);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text('${cat.name} (${e.value})', style: const TextStyle(fontSize: 12.5))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 30),
          const Text('Sessions Over Time (Last 7 Days)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (weekCounts.isEmpty ? 5 : (weekCounts.reduce((a, b) => a > b ? a : b) + 2)).toDouble(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(days[i], style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                barGroups: List.generate(weekCounts.length, (i) {
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: weekCounts[i].toDouble(),
                      color: AppColors.primary,
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ]);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }
}
