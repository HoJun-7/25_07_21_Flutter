class Patient {
  final int id;
  final int doctorId; // 이 환자를 등록한 의사의 ID
  final String name;
  final String dateOfBirth;
  final String gender;
  final String? phoneNumber;
  final String? address;

  Patient({
    required this.id,
    required this.doctorId,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.phoneNumber,
    this.address,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as int,
      doctorId: json['doctorId'] as int,
      name: json['name'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
      gender: json['gender'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'name': name,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }
}
