class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.isPrimary,
  });

  final int id;
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;

  EmergencyContact copyWith({
    int? id,
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
