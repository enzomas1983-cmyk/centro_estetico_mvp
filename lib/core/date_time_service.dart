class DateTimeService {
  /// =========================
  /// UI → DB (salvataggio)
  /// =========================
  static String toDb(DateTime localTime) {
    return localTime.toUtc().toIso8601String();
  }

  /// =========================
  /// DB → UI (visualizzazione)
  /// =========================
  static DateTime fromDb(String utcTime) {
    return DateTime.parse(utcTime).toLocal();
  }

  /// =========================
  /// SLOT KEY (anti bug parsing)
  /// =========================
  static String slotKey(DateTime localTime) {
    return localTime.toIso8601String();
  }

  static DateTime slotFromKey(String key) {
    return DateTime.parse(key).toLocal();
  }
}