class AppConfig {
  static const String baseUrl = "https://centro-estetico-mvp.vercel.app";

  static String bookingUrl(String businessId) => "$baseUrl/book/$businessId";
  static String cancelUrl(String appointmentId) => "$baseUrl/cancel/$appointmentId";
}