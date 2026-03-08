class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String role;
  final String? shopName;
  final String? shopAddress;
  final String? shopPhone;
  final String subscriptionStatus;
  final DateTime? subscriptionEndDate;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
    this.shopName,
    this.shopAddress,
    this.shopPhone,
    required this.subscriptionStatus,
    this.subscriptionEndDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'EPICIER',
      shopName: json['shopName'],
      shopAddress: json['shopAddress'],
      shopPhone: json['shopPhone'],
      subscriptionStatus: json['subscriptionStatus'] ?? 'TRIAL',
      subscriptionEndDate: json['subscriptionEndDate'] != null
          ? DateTime.parse(json['subscriptionEndDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'role': role,
    'shopName': shopName,
    'shopAddress': shopAddress,
    'shopPhone': shopPhone,
    'subscriptionStatus': subscriptionStatus,
    'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
  };

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? role,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? subscriptionStatus,
    DateTime? subscriptionEndDate,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      shopPhone: shopPhone ?? this.shopPhone,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
    );
  }
}
