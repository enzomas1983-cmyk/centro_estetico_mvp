// VERSIONE CON QR CODE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/auth_gate.dart';
import 'providers/auth_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart';
import 'core/app_router.dart';
import 'pages/public_booking_page.dart' show PublicBookingPage;
/// commentato per eseguire su APP ///
//import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'url_strategy.dart'
if (dart.library.html) 'url_strategy_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //// commentato per eseguire su APP ////
  //setUrlStrategy(PathUrlStrategy());

  if (kIsWeb) {
    //setUrlStrategy(PathUrlStrategy());
    configureUrlStrategy();
  }

  await initializeDateFormatting('it_IT', null);

  await Supabase.initialize(
    url: 'https://zhhubszcifokqrmfwurf.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpoaHVic3pjaWZva3FybWZ3dXJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwNTQwMDEsImV4cCI6MjA5MzYzMDAwMX0.3X5iKvq6xNSqLorIVM1vKzqFwpnBlMBCTfa6JkDYvb8',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      )
  );

  // 🔥 QUI VA IL DEBUG SESSIONE
  final session = Supabase.instance.client.auth.currentSession;
  debugPrint("SESSION INIT => $session");

  final user = Supabase.instance.client.auth.currentUser;
  debugPrint("USER INIT => $user");

  // Forza inclusione nel build
  // assert(PublicBookingPage != null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthProvider();
            auth.init(); // 🔥 IMPORTANTISSIMO
            return auth;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // #### TITLE ####
        title: 'Centro Estetico',

        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFE2E8F0),

          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Color(0xFF0F172A),
          ),

          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Color(0xFF0F172A)),
            bodyMedium: TextStyle(color: Color(0xFF475569)),
          ),

          useMaterial3: true,
        ),


        initialRoute: '/',
        onGenerateRoute: AppRouter.generateRoute,

      ),
    );
  }
}