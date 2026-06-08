class AppointmentModel {
  final String id;
  final String customerId;
  final String customerName;
  final String serviceName;
  final String? serviceColor;
  final int? serviceDuration;
  final DateTime startTime;
  final DateTime endTime;
  final String? status; // ✅ aggiunto

  AppointmentModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.serviceName,
    required this.startTime,
    required this.endTime,
    this.serviceColor,
    this.serviceDuration,
    this.status, // ✅ aggiunto
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customers'] as Map<String, dynamic>?;
    final service = json['services'] as Map<String, dynamic>?;

    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: (customer?['name'] ?? '').toString(),
      serviceName: (service?['name'] ?? '').toString(),
      serviceColor: service?['color']?.toString(),
      serviceDuration: service?['duration_minutes'] as int?,
      startTime: DateTime.parse(json['start_time']).toUtc(),
      endTime: DateTime.parse(json['end_time']).toUtc(),
      status: json['status']?.toString(), // ✅ aggiunto
    );
  }

  AppointmentModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? serviceName,
    String? serviceColor,
    int? serviceDuration,
    DateTime? startTime,
    DateTime? endTime,
    String? status, // ✅ aggiunto
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      serviceName: serviceName ?? this.serviceName,
      serviceColor: serviceColor ?? this.serviceColor,
      serviceDuration: serviceDuration ?? this.serviceDuration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status, // ✅ aggiunto
    );
  }
}