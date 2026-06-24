class DailyEarning {
  final String dayLabel;
  final double amount;
  const DailyEarning({required this.dayLabel, required this.amount});
}

class MonthlyEarning {
  final String monthLabel;
  final double amount;
  const MonthlyEarning({required this.monthLabel, required this.amount});
}

class EarningsSummary {
  final double today;
  final double weekly;
  final double monthly;
  final double total;
  final List<DailyEarning> dailyChart;
  final List<MonthlyEarning> monthlyChart;

  const EarningsSummary({
    required this.today,
    required this.weekly,
    required this.monthly,
    required this.total,
    required this.dailyChart,
    required this.monthlyChart,
  });
}
