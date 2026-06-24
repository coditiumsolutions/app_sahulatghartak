import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/provider/dashboard_stat_card.dart';

class EarningsTab extends StatelessWidget {
  const EarningsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<ProviderDashboardProvider>().earningsSummary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              DashboardStatCard(label: "Today's Earnings", value: 'Rs ${summary.today.toStringAsFixed(0)}', icon: Icons.today, color: kPrimaryColor),
              DashboardStatCard(label: 'Weekly Earnings', value: 'Rs ${summary.weekly.toStringAsFixed(0)}', icon: Icons.calendar_view_week, color: kAccentColor),
              DashboardStatCard(label: 'Monthly Earnings', value: 'Rs ${summary.monthly.toStringAsFixed(0)}', icon: Icons.calendar_month, color: Colors.orange),
              DashboardStatCard(label: 'Total Earnings', value: 'Rs ${summary.total.toStringAsFixed(0)}', icon: Icons.savings, color: kSecondaryColor),
            ],
          ),
          const SizedBox(height: 24),
          Text('Daily Earnings (This Week)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= summary.dailyChart.length) return const SizedBox.shrink();
                        return Padding(padding: const EdgeInsets.only(top: 6), child: Text(summary.dailyChart[index].dayLabel, style: const TextStyle(fontSize: 11)));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                barGroups: summary.dailyChart.asMap().entries.map((entry) {
                  return BarChartGroupData(x: entry.key, barRods: [
                    BarChartRodData(toY: entry.value.amount, color: kPrimaryColor, width: 16, borderRadius: BorderRadius.circular(4)),
                  ]);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Monthly Earnings Trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= summary.monthlyChart.length) return const SizedBox.shrink();
                        return Padding(padding: const EdgeInsets.only(top: 6), child: Text(summary.monthlyChart[index].monthLabel, style: const TextStyle(fontSize: 11)));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: kAccentColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: kAccentColor.withOpacity(0.15)),
                    spots: summary.monthlyChart.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.amount)).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
