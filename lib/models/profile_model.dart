/*class ProfileModel {
  final String id;
  final String email;
  final String role;
  final String businessId;

  ProfileModel({
    required this.id,
    required this.email,
    required this.role,
    required this.businessId,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      businessId: json['business_id'] ?? '',
    );
  }

  bool get isAdmin => role == 'admin';
}*/


class ProfileModel {
  final String id;
  final String email;
  final String role;
  final String? businessId; // ✅ nullable — un profilo può non avere business

  ProfileModel({
    required this.id,
    required this.email,
    required this.role,
    this.businessId,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      businessId: json['business_id']?.toString(),
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isOperator => role == 'operator';

  ProfileModel copyWith({
    String? id,
    String? email,
    String? role,
    String? businessId,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      businessId: businessId ?? this.businessId,
    );
  }
}