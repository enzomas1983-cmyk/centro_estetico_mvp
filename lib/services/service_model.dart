class ServiceModel {
  final String id;
  final String name;
  final int durationMinutes;
  final String? color; // ✅ nullable

  ServiceModel({
    required this.id,
    required this.name,
    required this.durationMinutes,
    this.color,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',       // ✅ validato
      name: json['name']?.toString() ?? '',   // ✅ validato
      durationMinutes: json['duration_minutes'] is int
          ? json['duration_minutes']
          : int.tryParse('${json['duration_minutes']}') ?? 30,
      color: json['color']?.toString(),       // ✅ nullable
    );
  }

  // ✅ copyWith aggiunto
  ServiceModel copyWith({
    String? id,
    String? name,
    int? durationMinutes,
    String? color,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      color: color ?? this.color,
    );
  }
}


/*class ServiceModel {
  final String id;
  final String name;
  final int durationMinutes;
  final String color;

  ServiceModel({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.color,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: json['name'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 30,
      color: json['color'] ?? '#9E9E9E',
    );
  }
}*/