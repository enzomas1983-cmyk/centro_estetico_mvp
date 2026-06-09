/*class AppConfig {
  static const String baseUrl = "https://www.mvenzo.it";

  static String bookingUrl(String appointmentId) => "$baseUrl/book/$appointmentId";
  static String cancelUrl(String appointmentId) => "$baseUrl/cancel/$appointmentId";
}*/


class AppConfig {
  static const String baseUrl = "https://www.mvenzo.it";

  // ── Business unico ───────────────────────────────────────────
  static const String businessSlug = "centro-estetico-mv";
  static const String businessId   = "48244569-89fb-4b8c-97af-0a7e9ee329ea";

  // ── URL pubblici ─────────────────────────────────────────────
  static String bookingUrl(String id) => "$baseUrl/book/$businessSlug";
  static String cancelUrl(String appointmentId) => "$baseUrl/cancel/$appointmentId";
}

