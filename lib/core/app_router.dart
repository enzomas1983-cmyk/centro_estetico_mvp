/*import 'package:flutter/material.dart';
import '../widgets/auth_gate.dart';
import '../pages/not_found_page.dart';
import '../pages/cancel_booking_page.dart';
import '../pages/guest_booking_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    debugPrint("ROUTE NAME => ${settings.name}"); // ✅ aggiungi qui
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
}*/


import 'package:flutter/material.dart';
import '../widgets/auth_gate.dart';
import '../pages/not_found_page.dart';
import '../pages/cancel_booking_page.dart';
import '../pages/guest_booking_page.dart';
import '../core/app_config.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    debugPrint("ROUTE NAME => ${settings.name}");
    final uri = Uri.parse(settings.name ?? '/');

    // 🔵 BOOKING PUBBLICO
    // Accetta sia lo slug "centro-estetico-mv" che l'UUID diretto
    if (uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'book') {

      final segment = uri.pathSegments.length > 1
          ? uri.pathSegments[1]
          : '';

      // Se il segmento è lo slug → usa businessId da AppConfig
      // Se è l'UUID diretto → usalo così (retrocompatibilità)
      final businessId = (segment == AppConfig.businessSlug || segment.isEmpty)
          ? AppConfig.businessId
          : segment;

      return MaterialPageRoute(
        builder: (_) => GuestBookingPage(businessId: businessId),
      );
    }

    // 🔴 CANCELLAZIONE
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
