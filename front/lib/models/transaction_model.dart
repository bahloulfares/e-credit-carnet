class TransactionClient {
  final String id;
  final String firstName;
  final String lastName;
  final String? phone;

  TransactionClient({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
  });

  String get fullName => '$firstName $lastName';

  factory TransactionClient.fromJson(Map<String, dynamic> json) {
    return TransactionClient(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
  };
}

class Transaction {
  final String id;
  final String userId;
  final String clientId;
  final String type; // CREDIT or PAYMENT
  final double amount;
  final String? description;
  final DateTime transactionDate;
  final DateTime? dueDate;
  final bool isPaid;
  final DateTime? paidAt;
  final String? paymentMethod;
  final TransactionClient? client;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.type,
    required this.amount,
    this.description,
    required this.transactionDate,
    this.dueDate,
    this.isPaid = false,
    this.paidAt,
    this.paymentMethod,
    this.client,
    this.syncStatus = 'SYNCED',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      clientId: json['clientId'] ?? '',
      type: json['type'] ?? 'CREDIT',
      amount: _toDouble(json['amount']),
      description: json['description'],
      transactionDate: json['transactionDate'] != null
          ? DateTime.parse(json['transactionDate'])
          : DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isPaid: json['isPaid'] ?? false,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      paymentMethod: json['paymentMethod'],
      client: json['client'] != null
          ? TransactionClient.fromJson(json['client'])
          : null,
      syncStatus: json['syncStatus'] ?? 'SYNCED',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'clientId': clientId,
    'type': type,
    'amount': amount,
    'description': description,
    'transactionDate': transactionDate.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'isPaid': isPaid,
    'paidAt': paidAt?.toIso8601String(),
    'paymentMethod': paymentMethod,
    'client': client?.toJson(),
    'syncStatus': syncStatus,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Transaction copyWith({
    String? id,
    String? userId,
    String? clientId,
    String? type,
    double? amount,
    String? description,
    DateTime? transactionDate,
    DateTime? dueDate,
    bool? isPaid,
    DateTime? paidAt,
    String? paymentMethod,
    TransactionClient? client,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      client: client ?? this.client,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
