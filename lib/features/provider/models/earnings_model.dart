class EarningsModel {
  final double totalEarnings;
  final double todayEarnings;
  final double thisWeekEarnings;
  final double thisMonthEarnings;
  final int totalJobsCompleted;
  final int todayJobs;
  final int thisWeekJobs;
  final int thisMonthJobs;
  final List<EarningTransaction> recentTransactions;
  final List<DailyEarning> weeklyEarnings;
  final List<MonthlyEarning> monthlyEarnings;

  EarningsModel({
    required this.totalEarnings,
    required this.todayEarnings,
    required this.thisWeekEarnings,
    required this.thisMonthEarnings,
    required this.totalJobsCompleted,
    required this.todayJobs,
    required this.thisWeekJobs,
    required this.thisMonthJobs,
    required this.recentTransactions,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
  });

  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      todayEarnings: (json['todayEarnings'] ?? 0).toDouble(),
      thisWeekEarnings: (json['thisWeekEarnings'] ?? 0).toDouble(),
      thisMonthEarnings: (json['thisMonthEarnings'] ?? 0).toDouble(),
      totalJobsCompleted: json['totalJobsCompleted'] ?? json['jobsCompleted'] ?? 0,
      todayJobs: json['todayJobs'] ?? 0,
      thisWeekJobs: json['thisWeekJobs'] ?? 0,
      thisMonthJobs: json['thisMonthJobs'] ?? 0,
      recentTransactions: (json['recentTransactions'] as List? ?? [])
          .map((e) => EarningTransaction.fromJson(e))
          .toList(),
      weeklyEarnings: (json['weeklyEarnings'] as List? ?? [])
          .map((e) => DailyEarning.fromJson(e))
          .toList(),
      monthlyEarnings: (json['monthlyEarnings'] as List? ?? [])
          .map((e) => MonthlyEarning.fromJson(e))
          .toList(),
    );
  }
}

class EarningTransaction {
  final String id;
  final String jobId;
  final String customerName;
  final double amount;
  final String status;
  final DateTime date;
  final String? paymentMethod;

  EarningTransaction({
    required this.id,
    required this.jobId,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.date,
    this.paymentMethod,
  });

  factory EarningTransaction.fromJson(Map<String, dynamic> json) {
    return EarningTransaction(
      id: json['id'],
      jobId: json['jobId'],
      customerName: json['customerName'],
      amount: json['amount'].toDouble(),
      status: json['status'],
      date: DateTime.parse(json['date']),
      paymentMethod: json['paymentMethod'],
    );
  }
}

class DailyEarning {
  final String day;
  final double amount;
  final int jobCount;

  DailyEarning({
    required this.day,
    required this.amount,
    required this.jobCount,
  });

  factory DailyEarning.fromJson(Map<String, dynamic> json) {
    return DailyEarning(
      day: json['day'],
      amount: json['amount'].toDouble(),
      jobCount: json['jobCount'],
    );
  }
}

class MonthlyEarning {
  final String month;
  final double amount;
  final int jobCount;

  MonthlyEarning({
    required this.month,
    required this.amount,
    required this.jobCount,
  });

  factory MonthlyEarning.fromJson(Map<String, dynamic> json) {
    return MonthlyEarning(
      month: json['month'],
      amount: json['amount'].toDouble(),
      jobCount: json['jobCount'],
    );
  }
}
