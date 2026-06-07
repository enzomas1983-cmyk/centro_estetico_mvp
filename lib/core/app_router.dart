import 'package:flutter/material.dart';
import '../widgets/auth_gate.dart';
import '../pages/not_found_page.dart';
import '../pages/cancel_booking_page.dart';
import '../pages/guest_booking_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');

    // 🔵 BOOKING PUBBLICO
    if (uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'book') {

      final id = uri.pathSegments.length > 1
          ? uri.pathSegments[1]
          : '';

      return MaterialPageRoute(
        builder: (_) => GuestBookingPage(businessId: id),
      );
    }

    if (uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'cancel') {
      final id = uri.pathSegments.length > 1
          ? uri.pathSegments[1]
          : '';
      return MaterialPageRoute(
        builder: (_) => CancelBookingPage(appointmentId: id),
      );
    }

    // 🔐 ADMIN ROOT
    if (uri.path == '/' || uri.path.isEmpty) {
      return MaterialPageRoute(
        builder: (_) => const AuthGate(),
      );
    }

    // ❌ 404
    return MaterialPageRoute(
      builder: (_) => const NotFoundPage(),
    );
  }
}