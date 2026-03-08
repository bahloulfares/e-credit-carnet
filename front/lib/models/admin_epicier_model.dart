class AdminEpicier {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? shopName;
  final bool isActive;
  final String subscriptionStatus;
  final DateTime createdAt;
  final int clientsCount;
  final int transactionsCount;

  AdminEpicier({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.shopName,
    required this.isActive,
    required this.subscriptionStatus,
    required this.createdAt,
    required this.clientsCount,
    required this.transactionsCount,
  });

  String get fullName => '$firstName $lastName';

  factory AdminEpicier.fromJson(Map<String, dynamic> json) {
    return AdminEpicier(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      shopName: json['shopName']?.toString(),
      isActive: json['isActive'] == true,
      subscriptionStatus: json['subscriptionStatus']?.toString() ?? 'TRIAL',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      clientsCount: _toInt(json['clientsCount']),
      transactionsCount: _toInt(json['transactionsCount']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class AdminGlobalStats {
  final int totalEpiciers;
  final int activeEpiciers;
  final int totalClients;
  final int totalTransactions;
  final double totalCredit;
  final double totalPayment;
  final double totalDebt;
  final int monthlyTransactions;
  final double monthlyCredit;
  final double monthlyPayment;

  AdminGlobalStats({
    required this.totalEpiciers,
    required this.activeEpiciers,
    required this.totalClients,
    required this.totalTransactions,
    required this.totalCredit,
    required this.totalPayment,
    required this.totalDebt,
    required this.monthlyTransactions,
    required this.monthlyCredit,
    required this.monthlyPayment,
  });

  factory AdminGlobalStats.fromJson(Map<String, dynamic> json) {
    return AdminGlobalStats(
      totalEpiciers: _toInt(json['totalEpiciers']),
      activeEpiciers: _toInt(json['activeEpiciers']),
      totalClients: _toInt(json['totalClients']),
      totalTransactions: _toInt(json['totalTransactions']),
      totalCredit: _toDouble(json['totalCredit']),
      totalPayment: _toDouble(json['totalPayment']),
      totalDebt: _toDouble(json['totalDebt']),
      monthlyTransactions: _toInt(json['monthlyTransactions']),
      monthlyCredit: _toDouble(json['monthlyCredit']),
      monthlyPayment: _toDouble(json['monthlyPayment']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
