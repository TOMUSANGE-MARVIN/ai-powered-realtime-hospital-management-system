class RecentTransaction {
  RecentTransaction({
    required this.id,
    required this.patientName,
    required this.amount,
    required this.date,
    required this.isVirtual,
  });

  final String id;
  final String patientName;
  final int amount;
  final DateTime date;
  final bool isVirtual;

  factory RecentTransaction.fromJson(Map<String, dynamic> json) {
    return RecentTransaction(
      id: json['id'] as String,
      patientName: json['patientName'] as String? ?? 'Patient',
      amount: json['amount'] as int? ?? 0,
      date: DateTime.parse(json['date'] as String),
      isVirtual: json['isVirtual'] as bool? ?? false,
    );
  }
}

class Earnings {
  Earnings({
    required this.totalEarnings,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.thisYear,
    required this.availableBalance,
    required this.pendingPayments,
    required this.consultationTotal,
    required this.consultationVirtual,
    required this.consultationInPerson,
    required this.revenueVirtual,
    required this.revenueInPerson,
    required this.recentTransactions,
  });

  final int totalEarnings;
  final int today;
  final int thisWeek;
  final int thisMonth;
  final int thisYear;
  final int availableBalance;
  final int pendingPayments;
  final int consultationTotal;
  final int consultationVirtual;
  final int consultationInPerson;
  final int revenueVirtual;
  final int revenueInPerson;
  final List<RecentTransaction> recentTransactions;

  factory Earnings.fromJson(Map<String, dynamic> json) {
    final stats = json['consultationStats'] as Map<String, dynamic>? ?? {};
    final breakdown = json['revenueBreakdown'] as Map<String, dynamic>? ?? {};
    final transactions = (json['recentTransactions'] as List? ?? [])
        .map((t) => RecentTransaction.fromJson(t as Map<String, dynamic>))
        .toList();

    return Earnings(
      totalEarnings: json['totalEarnings'] as int? ?? 0,
      today: json['today'] as int? ?? 0,
      thisWeek: json['thisWeek'] as int? ?? 0,
      thisMonth: json['thisMonth'] as int? ?? 0,
      thisYear: json['thisYear'] as int? ?? 0,
      availableBalance: json['availableBalance'] as int? ?? 0,
      pendingPayments: json['pendingPayments'] as int? ?? 0,
      consultationTotal: stats['total'] as int? ?? 0,
      consultationVirtual: stats['virtual'] as int? ?? 0,
      consultationInPerson: stats['inPerson'] as int? ?? 0,
      revenueVirtual: breakdown['virtual'] as int? ?? 0,
      revenueInPerson: breakdown['inPerson'] as int? ?? 0,
      recentTransactions: transactions,
    );
  }
}
