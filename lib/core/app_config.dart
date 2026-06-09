class AppConfig {
  static const String baseUrl = "https://www.mvenzo.it";

  static String bookingUrl(String appointmentId) => "$baseUrl/book/$appointmentId";
  static String cancelUrl(String appointmentId) => "$baseUrl/cancel/$appointmentId";
}
