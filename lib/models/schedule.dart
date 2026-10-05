// Schedule — pickup and delivery date/time chosen by the customer.

class Schedule {
  final DateTime pickupDateTime;
  final DateTime deliveryDateTime;

  const Schedule({
    required this.pickupDateTime,
    required this.deliveryDateTime,
  });

  Map<String, dynamic> toJson() => {
        'pickupDateTime': pickupDateTime.toIso8601String(),
        'deliveryDateTime': deliveryDateTime.toIso8601String(),
      };

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
        pickupDateTime: DateTime.parse(json['pickupDateTime'] as String),
        deliveryDateTime: DateTime.parse(json['deliveryDateTime'] as String),
      );
}
