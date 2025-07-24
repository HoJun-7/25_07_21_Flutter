class User {
  final int? id; // user_id 또는 doctor_id
  final String registerId;
  final String? name;
  final String? gender;
  final String? birth;
  final String? phone;
  final String? role;

  User({
    required this.id,
    required this.registerId,
    this.name,
    this.gender,
    this.birth,
    this.phone,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] as int? ?? json['doctor_id'] as int?,
      registerId: json['register_id'] as String,
      name: json['name'] as String?,
      gender: json['gender'] as String?,
      birth: json['birth'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'register_id': registerId,
      'name': name,
      'gender': gender,
      'birth': birth,
      'phone': phone,
      'role': role,
    };
  }

  // ✅ Doctor 여부를 확인하는 getter
  bool get isDoctor => role == 'D';

  // ✅ 사용자 정보 복사를 위한 copyWith 메서드 추가
  User copyWith({
    String? name,
    String? gender,
    String? birth,
    String? phone,
  }) {
    return User(
      id: id,
      registerId: registerId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birth: birth ?? this.birth,
      phone: phone ?? this.phone,
      role: role,
    );
  }
}
