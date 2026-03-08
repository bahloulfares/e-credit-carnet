class Client {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? address;
  final double totalDebt;
  final double totalCredit;
  final double totalPayment;
  final bool isActive;
  final String status;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Client({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.address,
    this.totalDebt = 0,
    this.totalCredit = 0,
    this.totalPayment = 0,
    this.isActive = true,
    this.status = 'active',
    this.syncStatus = 'SYNCED',
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      totalDebt: _toDouble(json['totalDebt']),
      totalCredit: _toDouble(json['totalCredit']),
      totalPayment: _toDouble(json['totalPayment']),
      isActive: json['isActive'] ?? true,
      status: json['status'] ?? 'active',
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
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'email': email,
    'address': address,
    'totalDebt': totalDebt,
    'totalCredit': totalCredit,
    'totalPayment': totalPayment,
    'isActive': isActive,
    'status': status,
    'syncStatus': syncStatus,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Client copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? address,
    double? totalDebt,
    double? totalCredit,
    double? totalPayment,
    bool? isActive,
    String? status,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalDebt: totalDebt ?? this.totalDebt,
      totalCredit: totalCredit ?? this.totalCredit,
      totalPayment: totalPayment ?? this.totalPayment,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
