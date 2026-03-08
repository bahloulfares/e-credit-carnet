class DashboardStats {
  final int totalClients;
  final double totalDebt;
  final double totalCredit;
  final double totalPayment;
  final int monthlyTransactions;
  final double monthlyCredit;
  final double monthlyPayment;
  final List<RecentTransaction> recentTransactions;

  DashboardStats({
    required this.totalClients,
    required this.totalDebt,
    required this.totalCredit,
    required this.totalPayment,
    required this.monthlyTransactions,
    required this.monthlyCredit,
    required this.monthlyPayment,
    required this.recentTransactions,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalClients: _toInt(json['totalClients']),
      totalDebt: _toDouble(json['totalDebt']),
      totalCredit: _toDouble(json['totalCredit']),
      totalPayment: _toDouble(json['totalPayment']),
      monthlyTransactions: _toInt(json['monthlyTransactions']),
      monthlyCredit: _toDouble(json['monthlyCredit']),
      monthlyPayment: _toDouble(json['monthlyPayment']),
      recentTransactions: (json['recentTransactions'] as List<dynamic>? ?? [])
          .map((e) => RecentTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalClients': totalClients,
    'totalDebt': totalDebt,
    'totalCredit': totalCredit,
    'totalPayment': totalPayment,
    'monthlyTransactions': monthlyTransactions,
    'monthlyCredit': monthlyCredit,
    'monthlyPayment': monthlyPayment,
    'recentTransactions': recentTransactions.map((e) => e.toJson()).toList(),
  };

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class RecentTransaction {
  final String id;
  final String type; // CREDIT, PAYMENT
  final double amount;
  final ClientInfo client;
  final DateTime createdAt;

  RecentTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.client,
    required this.createdAt,
  });

  factory RecentTransaction.fromJson(Map<String, dynamic> json) {
    return RecentTransaction(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'CREDIT',
      amount: _toDouble(json['amount']),
      client: ClientInfo.fromJson(
        (json['client'] as Map<String, dynamic>?) ?? {},
      ),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'amount': amount,
    'client': client.toJson(),
    'createdAt': createdAt.toIso8601String(),
  };

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool get isCredit => type == 'CREDIT';
}

class ClientInfo {
  final String firstName;
  final String lastName;

  ClientInfo({required this.firstName, required this.lastName});

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
  };

  String get fullName => '$firstName $lastName';
}

class SyncStatus {
  final int pendingSyncs;
  final LastSync? lastSync;

  SyncStatus({required this.pendingSyncs, this.lastSync});

  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      pendingSyncs: _toInt(json['pendingSyncs']),
      lastSync: json['lastSync'] == null
          ? null
          : LastSync.fromJson(json['lastSync'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'pendingSyncs': pendingSyncs,
    'lastSync': lastSync?.toJson(),
  };

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class LastSync {
  final DateTime syncStartTime;
  final DateTime? syncEndTime;
  final String status;
  final int itemsSynced;
  final int itemsFailed;

  LastSync({
    required this.syncStartTime,
    this.syncEndTime,
    required this.status,
    required this.itemsSynced,
    required this.itemsFailed,
  });

  factory LastSync.fromJson(Map<String, dynamic> json) {
    return LastSync(
      syncStartTime: _parseDate(json['syncStartTime']),
      syncEndTime: json['syncEndTime'] == null
          ? null
          : _parseDate(json['syncEndTime']),
      status: json['status']?.toString() ?? 'unknown',
      itemsSynced: _toInt(json['itemsSynced']),
      itemsFailed: _toInt(json['itemsFailed']),
    );
  }

  Map<String, dynamic> toJson() => {
    'syncStartTime': syncStartTime.toIso8601String(),
    'syncEndTime': syncEndTime?.toIso8601String(),
    'status': status,
    'itemsSynced': itemsSynced,
    'itemsFailed': itemsFailed,
  };

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool get isSuccessful => status == 'success' && itemsFailed == 0;
  Duration? get syncDuration {
    if (syncEndTime == null) return null;
    return syncEndTime!.difference(syncStartTime);
  }
}
