// Address model — where to pick up / deliver the order.

import 'enums.dart';

class Address {
  final String name;
  final String phone;
  final String addressLine;
  final AddressType type;
  final String? instructions; // optional special notes

  const Address({
    required this.name,
    required this.phone,
    required this.addressLine,
    required this.type,
    this.instructions,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'addressLine': addressLine,
        'type': type.name,
        'instructions': instructions,
      };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        name: json['name'] as String,
        phone: json['phone'] as String,
        addressLine: json['addressLine'] as String,
        type: AddressType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => AddressType.home,
        ),
        instructions: json['instructions'] as String?,
      );
}
